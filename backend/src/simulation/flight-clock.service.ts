import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Not, Repository } from 'typeorm';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { DeliveryCode } from '../delivery/delivery-code.entity';
import { isDeliveryWaitOver, pickupWaitMs } from '../delivery/delivery.rules';
import { Drone } from '../fleet/drone.entity';
import {
  DRONE_LIVE_STATUSES,
  activeOrderByDrone,
} from '../fleet/fleet-flights.rules';
import { Hub } from '../hubs/hub.entity';
import { InboxService } from '../notifications/inbox.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { departureCopy } from '../orders/plan-dispatch.rules';
import {
  LngLat,
  PlannedCorridor,
  rerouteFromPosition,
  splitCorridorAt,
} from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { batteryNow, batteryToFinishPercent } from './flight-energy.rules';
import { TELEMETRY_UNAVAILABLE } from '../telemetry/telemetry.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import {
  chooseProtocol,
  emergencyCorridor,
  homeCorridor,
  percentToFinish,
  percentToLand,
  safeLandingPoint,
} from './contingency.rules';
import { FlightIncidentsService } from './flight-incidents.service';
import { Mission } from './mission.entity';
import { WeatherService } from '../weather/weather.service';
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
import { simClock } from '../common/clock/sim-clock';

/** RF-33: fases en que el dron todavía puede tomar otro camino. */
const REROUTABLE_PHASES = new Set<FlightPhase>([
  FlightPhase.TAKEOFF,
  FlightPhase.TRANSITION,
  FlightPhase.CRUISE,
]);

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
  /** Central del dron: a ella vuelve si un incidente lo obliga (RF-34). */
  hubId: string;
  hub: LngLat;
  identifier: string;
  quantity: number;
  requiresColdChain: boolean;
  corridor: PlannedCorridor;
  model: FlightModel;
  progress: FlightProgress;
  loadConfirmedAt: Date;
  /** Aviso de despegue, solo en la ida de un programado que todavía no volaba. */
  departure: {
    toHub: boolean;
    requesterId: string | null;
    destinationHubId: string | null;
  } | null;
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
  /** RF-35: quién vuelve a despachar un pedido cuya misión no llegó. */
  private readonly abortListeners: Array<(orderId: string) => Promise<void>> =
    [];
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
    private readonly inbox: InboxService,
    private readonly weather: WeatherService,
    private readonly incidents: FlightIncidentsService,
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

  /**
   * RF-35: lo llama el motor de decisión para volver a despachar un pedido
   * cuya misión no llegó a su destino por un incidente. Corre cuando el dron
   * ya está en tierra (en la central o en el punto de emergencia): un pedido
   * no tiene dos vuelos a la vez.
   */
  onMissionAborted(listener: (orderId: string) => Promise<void>): void {
    this.abortListeners.push(listener);
  }

  /**
   * RF-33: una zona nueva (geovalla, temporal o tormenta) puede cruzar el
   * tramo que le falta a un dron en el aire. Si lo cruza, el dron sigue por
   * un corredor nuevo desde donde va; la decisión es de `rerouteFromPosition`
   * y aquí solo se aplica. Lo llama quien cambia las zonas.
   */
  async recheckRoutes(): Promise<void> {
    if (!this.active.size) {
      return;
    }
    const polygons = await this.routes.loadPolygons(this.orders.manager);
    for (const session of [...this.active.values()]) {
      if (
        !REROUTABLE_PHASES.has(session.progress.phase) ||
        session.progress.contingency?.protocol ===
          ContingencyProtocol.EMERGENCY_LANDING
      ) {
        continue;
      }
      const outcome = rerouteFromPosition(
        session.corridor,
        session.progress.cruiseKm,
        polygons,
      );
      if (outcome.kind === 'clear') {
        continue;
      }
      if (outcome.kind === 'blocked') {
        await this.notifications.rerouted({
          orderId: session.orderId,
          droneId: session.droneId,
          outcome: 'blocked',
          addedKm: null,
          crossesGeofence: true,
          batteryShort: false,
        });
        // Sin camino seguro: el protocolo lo decide RF-34.
        await this.handleIncident(session, IncidentKind.ROUTE_BLOCKED);
        continue;
      }
      session.corridor = outcome.corridor;
      await this.routes.replaceLeg(
        session.orderId,
        session.leg,
        outcome.corridor,
      );
      const needed = batteryToFinishPercent({
        remainingKm: outcome.remainingKm,
        returnKm:
          session.leg === RouteLeg.OUTBOUND
            ? outcome.corridor.distanceKm
            : null,
        maxRangeKm: session.model.maxRangeKm,
      });
      const batteryShort = session.progress.batteryPercent < needed;
      await this.notifications.rerouted({
        orderId: session.orderId,
        droneId: session.droneId,
        outcome: 'rerouted',
        addedKm: outcome.addedKm,
        crossesGeofence: outcome.crossesGeofence,
        batteryShort,
      });
      if (batteryShort) {
        // El camino nuevo es más largo de lo que alcanza: RF-34 según alcance.
        await this.handleIncident(session, IncidentKind.BATTERY_SHORT);
      }
    }
  }

  /**
   * RF-34 y CU-32: el reloj detectó un incidente. Las reglas eligen el
   * protocolo (`chooseProtocol`) y aquí se aplica: seguir, volver a la
   * central con el paquete o bajar en el punto seguro más cercano.
   */
  private async handleIncident(
    session: FlightSession,
    kind: IncidentKind,
  ): Promise<void> {
    if (
      session.progress.contingency?.protocol ===
      ContingencyProtocol.EMERGENCY_LANDING
    ) {
      return;
    }
    const polygons = await this.routes.loadPolygons(this.orders.manager);
    const cruiseKm = session.progress.cruiseKm;
    const at = splitCorridorAt(session.corridor, cruiseKm).at;
    const remainingKm = Math.max(0, session.corridor.distanceKm - cruiseKm);
    const maxRangeKm = session.model.maxRangeKm;
    const blocked = kind === IncidentKind.ROUTE_BLOCKED;
    const outbound = session.leg === RouteLeg.OUTBOUND;
    // De ida, la central se alcanza por un corredor nuevo desde aquí; de
    // regreso, el que lleva ya va a la central.
    const home = outbound ? homeCorridor(at, session.hub, polygons) : null;
    const homePercent = outbound
      ? home
        ? percentToLand(home.distanceKm, maxRangeKm)
        : null
      : blocked
        ? null
        : percentToLand(remainingKm, maxRangeKm);
    const protocol = chooseProtocol({
      kind,
      leg: session.leg,
      phase: session.progress.phase,
      batteryPercent: session.progress.batteryPercent,
      finishPercent:
        outbound && !blocked
          ? percentToFinish({
              remainingKm,
              returnKm: session.corridor.distanceKm,
              maxRangeKm,
            })
          : null,
      homePercent,
    });
    const order = session.keepStatus
      ? null
      : await this.orders.findOne({ where: { id: session.orderId } });
    const incident = await this.incidents.record({
      orderId: session.orderId,
      droneId: session.droneId,
      hubId: session.hubId,
      kind,
      leg: session.leg,
      protocol,
      position: at,
      batteryPercent: session.progress.batteryPercent,
      packageOf: order,
    });
    if (protocol === ContingencyProtocol.RETURN_TO_HUB && home) {
      await this.turnHome(session, home, incident.id);
      return;
    }
    if (protocol === ContingencyProtocol.EMERGENCY_LANDING) {
      const landing = safeLandingPoint(at, polygons);
      const corridor = emergencyCorridor(session.corridor, cruiseKm, landing);
      await this.routes.replaceLeg(session.orderId, session.leg, corridor);
      await this.incidents.setLanding(incident.id, landing);
      session.corridor = corridor;
      session.progress = {
        ...session.progress,
        // Si aún despegaba, sigue directo al punto de aterrizaje.
        phase: FlightPhase.CRUISE,
        phaseElapsedMs: 0,
        contingency: { protocol, incidentId: incident.id },
      };
    }
  }

  /** RF-34: de ida, el dron da la vuelta con el paquete hacia su central. */
  private async turnHome(
    session: FlightSession,
    home: PlannedCorridor,
    incidentId: string,
  ): Promise<void> {
    if (await this.routes.findReturn(session.orderId)) {
      await this.routes.replaceLeg(session.orderId, RouteLeg.RETURN, home);
    } else {
      await this.routes.saveReturn(session.orderId, home, this.orders.manager);
    }
    session.leg = RouteLeg.RETURN;
    session.corridor = home;
    session.departure = null;
    session.progress = {
      ...session.progress,
      phase: FlightPhase.CRUISE,
      phaseElapsedMs: 0,
      cruiseKm: 0,
      // El viento ya se avisó: la misma celda no cuenta otro incidente.
      orderStatus: OrderStatus.RETURNING,
      contingency: {
        protocol: ContingencyProtocol.RETURN_TO_HUB,
        incidentId,
      },
    };
    await this.orders.update(
      { id: session.orderId },
      { status: OrderStatus.RETURNING },
    );
    await this.notifications.statusChanged(
      session.orderId,
      OrderStatus.RETURNING,
    );
  }

  /** RF-35: el pedido vuelve al motor de decisión. */
  private async notifyAborted(orderId: string): Promise<void> {
    await this.telemetry.forgetFlight(orderId);
    for (const listener of this.abortListeners) {
      try {
        await listener(orderId);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'despacho';
        this.logger.error(
          `No se pudo volver a despachar ${orderId}: ${message}`,
        );
      }
    }
  }

  /**
   * RF-34: tocó tierra fuera de base. El dron queda `grounded` hasta que lo
   * rescaten. Si iba de ida, el pedido vuelve al motor de decisión ya.
   */
  private async landEmergency(
    session: FlightSession,
    step: FlightStep,
    incidentId: string,
  ): Promise<void> {
    const landed = simClock.now();
    await this.drones.update(
      { id: session.droneId },
      {
        status: DroneStatus.GROUNDED,
        batteryPercent: step.progress.batteryPercent,
        batteryUpdatedAt: landed,
        lastFlightEndedAt: landed,
      },
    );
    await this.incidents.grounded(incidentId, {
      latitude: step.latitude,
      longitude: step.longitude,
    });
    if (session.leg === RouteLeg.OUTBOUND) {
      await this.notifyAborted(session.orderId);
    }
  }

  /**
   * RF-40: el reinicio del escenario borró estos pedidos. El reloj deja de
   * moverlos; si un tick está en curso, espera a que termine para que no
   * vuelva a escribir una misión que ya no existe.
   */
  async forget(orderIds: string[]): Promise<void> {
    for (let waited = 0; this.ticking && waited < 5_000; waited += 50) {
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    for (const orderId of orderIds) {
      this.active.delete(orderId);
      this.waiting.delete(orderId);
      this.coldWaits.delete(orderId);
      this.pickups.delete(orderId);
    }
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
      .innerJoin(Mission, 'mission', 'mission.orderId = order.id')
      .where('order.status = :status', { status: OrderStatus.DELIVERED })
      .andWhere('drone.status = :droneStatus', {
        droneStatus: DroneStatus.IN_MISSION,
      })
      .andWhere('mission.returnedAt IS NULL')
      .getMany();
    for (const order of orders) {
      await this.activate(order.id);
    }
    for (const order of await this.currentDelivered(deliveredFlying)) {
      await this.resumeDelivered(order.id);
    }
  }

  /**
   * De los regresos sin cerrar, solo el que de verdad ocupa al dron. Si el dron
   * ya tomó otro pedido (vivo, o entregado después), ese regreso quedó viejo:
   * reanudarlo lo "aterrizaría" en la central y lo liberaría en plena misión.
   */
  private async currentDelivered(delivered: Order[]): Promise<Order[]> {
    const droneIds = [
      ...new Set(delivered.flatMap((order) => order.droneId ?? [])),
    ];
    if (!droneIds.length) {
      return [];
    }
    const live = await this.orders.find({
      where: { droneId: In(droneIds), status: In(DRONE_LIVE_STATUSES) },
    });
    const current = activeOrderByDrone([...live, ...delivered], droneIds);
    return delivered.filter(
      (order) => order.droneId && current.get(order.droneId)?.id === order.id,
    );
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
  async expireDeliveryWaits(now = simClock.now()): Promise<void> {
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
    deliveredAt = simClock.now(),
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
  private async releasePickups(now = simClock.now()): Promise<void> {
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
    await this.schedulePickup(orderId, code?.usedAt ?? simClock.now());
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
    if (drone?.status === DroneStatus.GROUNDED) {
      // RF-34: en tierra fuera de base, espera el rescate.
      return;
    }
    const hub = drone
      ? await this.orders.manager.findOne(Hub, { where: { id: drone.hubId } })
      : null;
    if (!drone?.droneModel || !corridor || !hub) {
      this.logger.error(
        `El pedido ${orderId} no tiene dron o corredor para volar.`,
      );
      return;
    }
    // RF-35: tras un incidente, Redis todavía guarda el vuelo del dron
    // anterior de este pedido. Solo se retoma el progreso del mismo dron.
    const saved = await this.telemetry.readFlight(orderId);
    const stored = saved?.droneId === drone.id ? saved : null;
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
          // Sale con la batería que tiene, no siempre llena (RF-11).
          batteryPercent: batteryNow(
            drone.batteryPercent ?? 100,
            drone.batteryUpdatedAt ?? null,
            simClock.now(),
          ),
          coldChainExcursionAtMs: order.requiresColdChain
            ? planColdChainExcursion(
                this.random(),
                coldChainFailureRate(),
                outboundDurationMs(corridor, {
                  maxSpeedKmh: drone.droneModel.maxSpeedKmh,
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
      hubId: hub.id,
      hub: { latitude: hub.latitude, longitude: hub.longitude },
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
      departure:
        !returning &&
        order.missionType === MissionType.SCHEDULED &&
        order.status === OrderStatus.PENDING_LOAD
          ? {
              toHub: order.destinationKind === DestinationKind.HUB,
              requesterId: order.requesterId,
              destinationHubId: order.destinationHubId,
            }
          : null,
    });
  }

  /**
   * Ruta de regreso con las mismas reglas de geovalla que la ida, contra las
   * geovallas vigentes al salir. Si ninguna ruta las evita, queda en el log.
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
    const planned = this.routes.planReturn(
      { longitude: order.longitude, latitude: order.latitude },
      { longitude: origin.longitude, latitude: origin.latitude },
      polygons,
      outbound ?? null,
    );
    if (!planned) {
      return undefined;
    }
    if (planned.crossesGeofence) {
      this.logger.warn(
        `El regreso de ${order.id} cruza una geovalla: no hay otra ruta a la central.`,
      );
    }
    await this.routes.saveReturn(order.id, planned.corridor, manager);
    return planned.corridor;
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
      // RF-31: cada tick son 2 s reales; a x8, 16 s simulados; en pausa, 0.
      elapsedMs: simClock.scale(TICK_MS),
      corridor: session.corridor,
      model: session.model,
      loadConfirmedAt: session.loadConfirmedAt,
      weather: this.weather.active(),
    });
    if (!step) {
      return;
    }
    if (session.keepStatus) {
      // Entregado es definitivo: el regreso solo mueve al dron.
      step.progress.orderStatus = OrderStatus.DELIVERED;
      step.statusChanges = [];
    }
    const contingency = session.progress.contingency ?? null;
    if (contingency?.protocol === ContingencyProtocol.EMERGENCY_LANDING) {
      // Bajar de emergencia no es llegar: el pedido no cambia por aterrizar.
      step.progress.orderStatus = session.progress.orderStatus;
      step.statusChanges = [];
    }
    // Tras entregar, el dron vuelve vacío: ya no hay carga que medir.
    const carriesColdLoad = session.requiresColdChain && !session.keepStatus;
    let temperatureC: number | null = null;
    if (carriesColdLoad) {
      const reading = coldChainReading(
        step.progress,
        simClock.nowMs() - session.loadConfirmedAt.getTime(),
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
        if (status === OrderStatus.IN_FLIGHT) {
          await this.noteDeparture(session);
        }
      }
      const landedAt = await this.syncMission(session, step);
      for (const kind of step.alerts) {
        await this.notifications.alert(orderId, session.droneId, kind);
      }
      if (step.alerts.includes('cold_chain')) {
        await this.markColdChainAlert(orderId);
      }
      if (step.progress.phase !== FlightPhase.LANDED) {
        // RF-34: lo que el reloj detecta solo también es un incidente.
        if (step.alerts.includes('wind_limit')) {
          await this.handleIncident(session, IncidentKind.WIND_LIMIT);
        }
        if (step.alerts.includes('battery_critical')) {
          await this.handleIncident(session, IncidentKind.BATTERY_CRITICAL);
        }
      }
      if (
        step.progress.phase === FlightPhase.LANDED &&
        contingency?.protocol === ContingencyProtocol.EMERGENCY_LANDING
      ) {
        this.active.delete(orderId);
        await this.landEmergency(session, step, contingency.incidentId);
      } else if (step.progress.phase === FlightPhase.LANDED) {
        this.active.delete(orderId);
        if (session.leg === RouteLeg.RETURN) {
          // Si el dron ya tiene otro pedido vivo, sigue en misión con ese.
          const busy = await this.orders.count({
            where: {
              droneId: session.droneId,
              status: In(DRONE_LIVE_STATUSES),
              id: Not(orderId),
            },
          });
          // Guarda con cuánta batería volvió; desde ahora recarga en tierra.
          const landed = simClock.now();
          await this.drones.update(
            { id: session.droneId },
            {
              ...(busy ? {} : { status: DroneStatus.AVAILABLE }),
              batteryPercent: step.progress.batteryPercent,
              batteryUpdatedAt: landed,
              lastFlightEndedAt: landed,
              // Un ciclo más para el preventivo; el aviso lo decide la flota.
              flightsSinceMaintenance: () => '"flightsSinceMaintenance" + 1',
            },
          );
          await this.missions.update(
            { orderId, droneId: session.droneId, returnedAt: IsNull() },
            {
              returnedAt: simClock.now(),
              landingBatteryPercent: step.progress.batteryPercent,
            },
          );
          if (contingency?.protocol === ContingencyProtocol.RETURN_TO_HUB) {
            // RF-34: el paquete queda en cuarentena; RF-35: dron nuevo.
            await this.incidents.returnedHome(contingency.incidentId);
            await this.notifyAborted(orderId);
          }
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
  private async watchColdWaits(now = simClock.now()): Promise<void> {
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

  /** RU-30: al despegar, quien recibe sabe a qué hora llega. Una sola vez. */
  private async noteDeparture(session: FlightSession): Promise<void> {
    const departure = session.departure;
    if (!departure) {
      return;
    }
    session.departure = null;
    const arrival = new Date(
      simClock.nowMs() + outboundDurationMs(session.corridor, session.model),
    );
    const notice = {
      kind: NotificationKind.DEPARTED,
      orderId: session.orderId,
      ...departureCopy(arrival, departure.toHub),
    };
    try {
      if (departure.toHub && departure.destinationHubId) {
        await this.inbox.notifyHubDispatchers(departure.destinationHubId, notice);
        return;
      }
      if (departure.requesterId) {
        await this.inbox.notifyUser(departure.requesterId, notice);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'aviso';
      this.logger.warn(
        `No se pudo avisar el despegue de ${session.orderId}: ${message}`,
      );
    }
  }

  /** La marca impide reingresar el insumo (cuarentena de productos.md). */
  private async markColdChainAlert(
    orderId: string,
    now = simClock.now(),
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
    // RF-35: un pedido despachado otra vez tiene una misión por dron.
    let mission = await this.missions.findOne({
      where: {
        orderId: session.orderId,
        droneId: session.droneId,
        returnedAt: IsNull(),
      },
    });
    if (!mission) {
      mission = this.missions.create({
        orderId: session.orderId,
        droneId: session.droneId,
        startedAt: simClock.now(),
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
    if (step.alerts.includes('wind_limit')) {
      mission.windAlert = true;
    }
    if (
      step.progress.orderStatus === OrderStatus.AWAITING_DELIVERY &&
      !mission.landedAt
    ) {
      mission.landedAt = simClock.now();
    }
    await this.missions.save(mission);
    return mission.landedAt;
  }
}
