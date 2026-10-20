import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { isDeliveryWaitOver } from '../delivery/delivery.rules';
import { Drone } from '../fleet/drone.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { PlannedCorridor } from '../routing/routing.rules';
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
  initialProgress,
  FlightPhase,
} from './simulation.rules';

type FlightSession = {
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

  private async resume(): Promise<void> {
    const orders = await this.orders
      .createQueryBuilder('order')
      .where('order.loadConfirmedAt IS NOT NULL')
      .andWhere('order.status IN (:...statuses)', {
        statuses: [OrderStatus.PENDING_LOAD, OrderStatus.IN_FLIGHT],
      })
      .getMany();
    for (const order of orders) {
      await this.activate(order.id);
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
  }

  /**
   * CU-29: sin código válido a tiempo, el pedido pasa a `returning`.
   * El UPDATE condicionado al estado evita pisar una entrega que se esté
   * validando en ese instante.
   */
  async expireDeliveryWaits(now = new Date()): Promise<void> {
    for (const [orderId, landedAt] of [...this.waiting]) {
      if (!isDeliveryWaitOver(landedAt, now)) {
        continue;
      }
      this.waiting.delete(orderId);
      const result = await this.orders.update(
        { id: orderId, status: OrderStatus.AWAITING_DELIVERY },
        { status: OrderStatus.RETURNING },
      );
      if (result.affected) {
        await this.notifications.statusChanged(orderId, OrderStatus.RETURNING);
      }
    }
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
        order.status !== OrderStatus.IN_FLIGHT)
    ) {
      return;
    }
    const drone = await this.drones.findOne({
      where: { id: order.droneId },
      relations: { droneModel: true },
    });
    const corridor = (await this.routes.findOutboundMany([orderId])).get(
      orderId,
    );
    if (!drone?.droneModel || !corridor) {
      this.logger.error(
        `El pedido ${orderId} no tiene dron o corredor para volar.`,
      );
      return;
    }
    const stored = await this.telemetry.readFlight(orderId);
    const progress = stored?.progress ?? {
      ...initialProgress(),
      orderStatus:
        order.status === OrderStatus.IN_FLIGHT
          ? OrderStatus.IN_FLIGHT
          : OrderStatus.PENDING_LOAD,
    };
    this.active.set(orderId, {
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
      progress: session.progress,
      elapsedMs: TICK_MS,
      corridor: session.corridor,
      model: session.model,
      loadConfirmedAt: session.loadConfirmedAt,
    });
    if (!step) {
      return;
    }
    const previous = session.progress;
    session.progress = step.progress;
    try {
      await this.telemetry.publishFlight(
        buildLiveFlight({
          orderId: session.orderId,
          droneId: session.droneId,
          identifier: session.identifier,
          quantity: session.quantity,
          requiresColdChain: session.requiresColdChain,
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
      if (step.progress.phase === FlightPhase.LANDED) {
        this.active.delete(orderId);
        if (landedAt) {
          this.waiting.set(orderId, landedAt);
        }
      }
    } catch (error) {
      session.progress = previous;
      throw error;
    }
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
