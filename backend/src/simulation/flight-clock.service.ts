import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { DeliveryCode } from '../delivery/delivery-code.entity';
import { isDeliveryWaitOver, pickupWaitMs } from '../delivery/delivery.rules';
import { Drone } from '../fleet/drone.entity';
import { Hub } from '../hubs/hub.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { PlannedCorridor, reverseCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { TELEMETRY_UNAVAILABLE } from '../telemetry/telemetry.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { Mission } from './mission.entity';
import {
  FLIGHT_NOT_READY,
  FlightModel,
  FlightProgress,
  FlightStep,
  TICK_MS,
  advanceFlight,
  buildLiveFlight,
  coldChainFailureRate,
  coldChainReading,
  initialProgress,
  outboundDurationMs,
  planColdChainExcursion,
  returnProgress,
  FlightPhase,
} from './simulation.rules';

/** Pedido con frío que espera el código: la carga se sigue midiendo. */
type ColdWait = {
  droneId: string;
  loadConfirmedAt: Date;
};

type FlightSession = {
  leg: RouteLeg;
  /** Regreso del dron tras una entrega: el pedido se queda `delivered`. */
  keepStatus: boolean;
  orderId: string;
  droneId: string;
  identifier: string;
  quantity: number;
  requiresColdChain: boolean;
  corridor: PlannedCorridor;
  model: FlightModel;
  progress: FlightProgress;
  loadConfirmedAt: Date;
};

@Injectable()
export class FlightClockService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(FlightClockService.name);
  private readonly active = new Map<string, FlightSession>();
  /** Pedidos aterrizados que esperan el código de entrega. */
  private readonly waiting = new Map<string, Date>();
  private readonly coldWaits = new Map<string, ColdWait>();
  /** Pedidos entregados cuyo dron espera en destino a que retiren el insumo. */
  private readonly pickups = new Map<string, Date>();
  /** Los tests lo reemplazan para fijar si hay falla de frío. */
  private random: () => number = Math.random;
  private timer: NodeJS.Timeout | null = null;
  private ticking = false;

  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Drone)
    private readonly drones: Repository<Drone>,
    @InjectRepository(Mission)
    private readonly missions: Repository<Mission>,
    private readonly routes: RoutePlannerService,
    private readonly telemetry: TelemetryPublisher,
    private readonly notifications: NotificationsService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!this.isReady()) {
      this.logger.error(
        'Redis no está disponible. El reloj de vuelo no arranca.',
      );
      return;
    }
    await this.resume();
    await this.resumeWaiting();
    this.timer = setInterval(() => {
      void this.tickAll();
    }, TICK_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  isReady(): boolean {
    return this.telemetry.isReady();
  }

  async start(orderId: string): Promise<void> {
    if (!this.isReady()) {
      throw new ServiceUnavailableException(TELEMETRY_UNAVAILABLE);
    }
    await this.activate(orderId);
    if (!this.active.has(orderId)) {
      throw new BadRequestException(FLIGHT_NOT_READY);
    }
  }

  /**
   * Tras una entrega, el dron vuelve solo a su central. Si la central de
   * destino no recibió el traslado (`returning`), vuelve con el paquete.
   */
  async startReturn(orderId: string): Promise<void> {
    await this.activate(orderId);
  }

  private async resume(): Promise<void> {
    const orders = await this.orders
      .createQueryBuilder('order')
      .where('order.loadConfirmedAt IS NOT NULL')
      .andWhere('order.status IN (:...statuses)', {
        statuses: [
          OrderStatus.PENDING_LOAD,
          OrderStatus.IN_FLIGHT,
          OrderStatus.RETURNING,
        ],
      })
      .getMany();
    const deliveredFlying = await this.orders
      .createQueryBuilder('order')
      .innerJoin(Drone, 'drone', 'drone.id = order.droneId')
      .where('order.status = :status', { status: OrderStatus.DELIVERED })
      .andWhere('drone.status = :droneStatus', {
        droneStatus: DroneStatus.IN_MISSION,
      })
      .getMany();
    for (const order of orders) {
      await this.activate(order.id);
    }
    for (const order of deliveredFlying) {
      await this.resumeDelivered(order.id);
    }
  }

  private async resumeWaiting(): Promise<void> {
    const missions = await this.missions
      .createQueryBuilder('mission')
      .innerJoin(Order, 'order', 'order.id = mission.orderId')
      .where('order.status = :status', {
        status: OrderStatus.AWAITING_DELIVERY,
      })
      .andWhere('mission.landedAt IS NOT NULL')
      .getMany();
    for (const mission of missions) {
      if (mission.landedAt) {
        this.waiting.set(mission.orderId, mission.landedAt);
      }
    }
    if (!missions.length) {
      return;
    }
    const cold = await this.orders.find({
      where: {
        id: In(missions.map((mission) => mission.orderId)),
        requiresColdChain: true,
      },
    });
    for (const order of cold) {
      if (order.droneId && order.loadConfirmedAt) {
        this.coldWaits.set(order.id, {
          droneId: order.droneId,
          loadConfirmedAt: order.loadConfirmedAt,
        });
      }
    }
  }

  /**
   * CU-29: sin código válido a tiempo, el pedido pasa a `returning`.
   */
  async expireDeliveryWaits(now = new Date()): Promise<void> {
    for (const [orderId, landedAt] of [...this.waiting]) {
      if (isDeliveryWaitOver(landedAt, now)) {
        await this.returnWithPackage(orderId);
      }
    }
  }

  /**
   * El dron deja de esperar y vuelve con el paquete: venció la espera o se
   * agotaron los intentos del código. El UPDATE condicionado al estado evita
   * pisar una entrega que se esté validando en ese instante.
   */
  async returnWithPackage(orderId: string): Promise<boolean> {
    const result = await this.orders.update(
      { id: orderId, status: OrderStatus.AWAITING_DELIVERY },
      { status: OrderStatus.RETURNING },
    );
    // Si el UPDATE falla, sigue en espera y la vence el siguiente tick.
    this.waiting.delete(orderId);
    if (!result.affected) {
      return false;
    }
    await this.notifications.statusChanged(orderId, OrderStatus.RETURNING);
    try {
      await this.activate(orderId);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'regreso';
      this.logger.error(
        `No se pudo iniciar el regreso ${orderId}: ${message}. Se reintenta al reiniciar.`,
      );
    }
    return true;
  }

  /**
   * Código correcto: el pedido ya está entregado, pero el dron se queda en
   * destino `PICKUP_WAIT_MS` (1 min) con la fase `unloading` para que retiren
   * el medicamento. Después despega solo de regreso.
   */
  async schedulePickup(
    orderId: string,
    deliveredAt = new Date(),
  ): Promise<void> {
    this.waiting.delete(orderId);
    this.coldWaits.delete(orderId);
    this.pickups.set(orderId, new Date(deliveredAt.getTime() + pickupWaitMs()));
    try {
      const flight = await this.telemetry.readFlight(orderId);
      if (flight) {
        await this.telemetry.publishFlight({
          ...flight,
          phase: FlightPhase.UNLOADING,
          status: OrderStatus.DELIVERED,
          speedKmh: 0,
          etaSeconds: null,
          temperatureC: null,
        });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'telemetría';
      this.logger.warn(
        `No se pudo publicar el retiro de ${orderId}: ${message}`,
      );
    }
  }

  /** Terminó el minuto de retiro: el dron despega de regreso, ya vacío. */
  private async releasePickups(now = new Date()): Promise<void> {
    for (const [orderId, readyAt] of [...this.pickups]) {
      if (now < readyAt) {
        continue;
      }
      this.pickups.delete(orderId);
      try {
        await this.activate(orderId);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'regreso';
        this.logger.error(
          `No se pudo iniciar el regreso del dron ${orderId}: ${message}. Se reintenta al reiniciar.`,
        );
      }
    }
  }

  /**
   * Tras un reinicio: si el regreso ya empezó, sigue; si no, el dron todavía
   * estaba en el minuto de retiro y lo termina desde la hora de la entrega.
   */
  private async resumeDelivered(orderId: string): Promise<void> {
    if (await this.routes.findReturn(orderId)) {
      await this.activate(orderId);
      return;
    }
    const code = await this.orders.manager.findOne(DeliveryCode, {
      where: { orderId },
    });
    await this.schedulePickup(orderId, code?.usedAt ?? new Date());
  }

  private async activate(orderId: string): Promise<void> {
    if (this.active.has(orderId)) {
      return;
    }
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (
      !order?.loadConfirmedAt ||
      !order.droneId ||
      (order.status !== OrderStatus.PENDING_LOAD &&
        order.status !== OrderStatus.IN_FLIGHT &&
        order.status !== OrderStatus.RETURNING &&
        order.status !== OrderStatus.DELIVERED)
    ) {
      return;
    }
    const delivered = order.status === OrderStatus.DELIVERED;
    const returning = delivered || order.status === OrderStatus.RETURNING;
    const leg = returning ? RouteLeg.RETURN : RouteLeg.OUTBOUND;
    const drone = await this.drones.findOne({
      where: { id: order.droneId },
      relations: { droneModel: true },
    });
    const corridor = returning
      ? await this.returnCorridor(order)
      : (await this.routes.findOutboundMany([orderId])).get(orderId);
    if (!drone?.droneModel || !corridor) {
      this.logger.error(
        `El pedido ${orderId} no tiene dron o corredor para volar.`,
      );
      return;
    }
    const stored = await this.telemetry.readFlight(orderId);
    const progress = returning
      ? stored?.leg === RouteLeg.RETURN
        ? stored.progress
        : {
            ...returnProgress(stored?.progress ?? null),
            orderStatus: delivered
              ? OrderStatus.DELIVERED
              : OrderStatus.RETURNING,
          }
      : (stored?.progress ?? {
          ...initialProgress(),
          coldChainExcursionAtMs: order.requiresColdChain
            ? planColdChainExcursion(
                this.random(),
                coldChainFailureRate(),
                outboundDurationMs(corridor, {
                  maxSpeedKmh: drone.droneModel.maxSpeedKmh,
                  maxRangeKm: drone.droneModel.maxRangeKm,
                }),
              )
            : null,
          orderStatus:
            order.status === OrderStatus.IN_FLIGHT
              ? OrderStatus.IN_FLIGHT
              : OrderStatus.PENDING_LOAD,
        });
    this.active.set(orderId, {
      leg,
      keepStatus: delivered,
      orderId,
      droneId: drone.id,
      identifier: drone.identifier,
      quantity: order.quantity,
      requiresColdChain: order.requiresColdChain,
      corridor,
      model: {
        maxSpeedKmh: drone.droneModel.maxSpeedKmh,
        maxRangeKm: drone.droneModel.maxRangeKm,
      },
      progress,
      loadConfirmedAt: order.loadConfirmedAt,
    });
  }

  /**
   * Ruta de regreso con las mismas reglas de geovalla que la ida. Si una
   * geovalla nueva la bloquea, el dron vuelve por donde vino.
   */
  private async returnCorridor(
    order: Order,
  ): Promise<PlannedCorridor | undefined> {
    const saved = await this.routes.findReturn(order.id);
    if (saved) {
      return saved;
    }
    const manager = this.orders.manager;
    const origin = order.originHubId
      ? await manager.findOne(Hub, { where: { id: order.originHubId } })
      : null;
    const outbound = (await this.routes.findOutboundMany([order.id])).get(
      order.id,
    );
    if (!origin || order.latitude == null || order.longitude == null) {
      return undefined;
    }
    const polygons = await this.routes.loadPolygons(manager);
    const planned =
      this.routes.plan(
        { longitude: order.longitude, latitude: order.latitude },
        { longitude: origin.longitude, latitude: origin.latitude },
        polygons,
      ) ?? (outbound ? reverseCorridor(outbound) : null);
    if (!planned) {
      return undefined;
    }
    await this.routes.saveReturn(order.id, planned, manager);
    return planned;
  }

  private async tickAll(): Promise<void> {
    if (this.ticking) {
      return;
    }
    this.ticking = true;
    try {
      for (const orderId of [...this.active.keys()]) {
        try {
          await this.tick(orderId);
        } catch (error) {
          const message = error instanceof Error ? error.message : 'tick';
          this.logger.error(
            `No se pudo avanzar el vuelo ${orderId}: ${message}`,
          );
        }
      }
      try {
        await this.releasePickups();
      } catch (error) {
        const message = error instanceof Error ? error.message : 'retiro';
        this.logger.error(`No se pudo terminar el retiro: ${message}`);
      }
      try {
        await this.watchColdWaits();
      } catch (error) {
        const message = error instanceof Error ? error.message : 'frío';
        this.logger.error(`No se pudo medir la carga en espera: ${message}`);
      }
      try {
        await this.expireDeliveryWaits();
      } catch (error) {
        const message = error instanceof Error ? error.message : 'espera';
        this.logger.error(`No se pudo vencer la espera: ${message}`);
      }
    } finally {
      this.ticking = false;
    }
  }

  private async tick(orderId: string): Promise<void> {
    const session = this.active.get(orderId);
    if (!session) {
      return;
    }
    const step = advanceFlight({
      leg: session.leg,
      progress: session.progress,
      elapsedMs: TICK_MS,
      corridor: session.corridor,
      model: session.model,
      loadConfirmedAt: session.loadConfirmedAt,
    });
    if (!step) {
      return;
    }
    if (session.keepStatus) {
      // Entregado es definitivo: el regreso solo mueve al dron.
      step.progress.orderStatus = OrderStatus.DELIVERED;
      step.statusChanges = [];
    }
    // Tras entregar, el dron vuelve vacío: ya no hay carga que medir.
    const carriesColdLoad = session.requiresColdChain && !session.keepStatus;
    let temperatureC: number | null = null;
    if (carriesColdLoad) {
      const reading = coldChainReading(
        step.progress,
        Date.now() - session.loadConfirmedAt.getTime(),
      );
      temperatureC = reading.temperatureC;
      step.progress.coldChainAlertSent = reading.alertSent;
      if (reading.alert) {
        step.alerts.push('cold_chain');
      }
    }
    const previous = session.progress;
    session.progress = step.progress;
    try {
      await this.telemetry.publishFlight(
        buildLiveFlight({
          leg: session.leg,
          orderId: session.orderId,
          droneId: session.droneId,
          identifier: session.identifier,
          quantity: session.quantity,
          requiresColdChain: carriesColdLoad,
          temperatureC,
          step,
        }),
      );
      for (const status of step.statusChanges) {
        await this.orders.update({ id: orderId }, { status });
        await this.notifications.statusChanged(orderId, status);
      }
      const landedAt = await this.syncMission(session, step);
      for (const kind of step.alerts) {
        await this.notifications.alert(orderId, session.droneId, kind);
      }
      if (step.alerts.includes('cold_chain')) {
        await this.markColdChainAlert(orderId);
      }
      if (step.progress.phase === FlightPhase.LANDED) {
        this.active.delete(orderId);
        if (session.leg === RouteLeg.RETURN) {
          await this.drones.update(
            { id: session.droneId },
            { status: DroneStatus.AVAILABLE },
          );
          await this.missions.update({ orderId }, { returnedAt: new Date() });
        } else if (landedAt) {
          this.waiting.set(orderId, landedAt);
          if (session.requiresColdChain) {
            this.coldWaits.set(orderId, {
              droneId: session.droneId,
              loadConfirmedAt: session.loadConfirmedAt,
            });
          }
        }
      }
    } catch (error) {
      session.progress = previous;
      throw error;
    }
  }

  /**
   * RF-17 en la espera: no hay tick de vuelo, pero la carga sigue en el dron.
   * Se recalcula la temperatura, se publica y, si sale de rango, se alerta.
   * Al entregar o al iniciar el regreso, deja de medirse aquí.
   */
  private async watchColdWaits(now = new Date()): Promise<void> {
    for (const [orderId, cold] of [...this.coldWaits]) {
      if (!this.waiting.has(orderId) || this.active.has(orderId)) {
        this.coldWaits.delete(orderId);
        continue;
      }
      const flight = await this.telemetry.readFlight(orderId);
      if (!flight) {
        continue;
      }
      const reading = coldChainReading(
        flight.progress,
        now.getTime() - cold.loadConfirmedAt.getTime(),
      );
      await this.telemetry.publishFlight({
        ...flight,
        temperatureC: reading.temperatureC,
        progress: { ...flight.progress, coldChainAlertSent: reading.alertSent },
      });
      if (reading.alert) {
        await this.notifications.alert(orderId, cold.droneId, 'cold_chain');
        await this.markColdChainAlert(orderId, now);
      }
    }
  }

  /** La marca impide reingresar el insumo (cuarentena de productos.md). */
  private async markColdChainAlert(
    orderId: string,
    now = new Date(),
  ): Promise<void> {
    await this.orders.update(
      { id: orderId, coldChainAlertAt: IsNull() },
      { coldChainAlertAt: now },
    );
  }

  private async syncMission(
    session: FlightSession,
    step: FlightStep,
  ): Promise<Date | null> {
    const flying =
      step.progress.orderStatus === OrderStatus.IN_FLIGHT ||
      step.progress.orderStatus === OrderStatus.AWAITING_DELIVERY;
    if (!flying) {
      return null;
    }
    let mission = await this.missions.findOne({
      where: { orderId: session.orderId },
    });
    if (!mission) {
      mission = this.missions.create({
        orderId: session.orderId,
        droneId: session.droneId,
        startedAt: new Date(),
        landedAt: null,
        returnedAt: null,
        batteryAlert: false,
        failureAlert: false,
      });
    }
    if (step.alerts.includes('battery_critical')) {
      mission.batteryAlert = true;
    }
    if (step.alerts.includes('failure')) {
      mission.failureAlert = true;
    }
    if (
      step.progress.orderStatus === OrderStatus.AWAITING_DELIVERY &&
      !mission.landedAt
    ) {
      mission.landedAt = new Date();
    }
    await this.missions.save(mission);
    return mission.landedAt;
  }
}
