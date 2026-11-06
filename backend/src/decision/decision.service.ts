import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { DataSource, EntityManager, In } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import {
  DRONE_HOLDING_STATUSES,
  activeOrderByDrone,
} from '../fleet/fleet-flights.rules';
import { DroneModel } from '../fleet/drone-model.entity';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { Hub } from '../hubs/hub.entity';
import {
  HUB_WITHOUT_POWER,
  HUB_WITHOUT_POWER_NOTE,
  OUTAGE_REDISPATCH_REASON,
  isPowered,
} from '../hubs/hub-power.rules';
import { HubsService } from '../hubs/hubs.service';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { InboxService } from '../notifications/inbox.service';
import { presentOrder } from '../orders/order.presenter';
import { HubTrace, Order } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { SCHEDULE_LEAD_MS } from '../orders/plan-schedule.rules';
import {
  WINDOW_MISSED,
  assertDispatchWindow,
  dispatchWindow,
  isMissedDeparture,
  isWindowClosed,
  missedCopy,
} from '../orders/plan-dispatch.rules';
import {
  DESTINATION_IN_GEOFENCE,
  PlannedCorridor,
  isInsideGeofence,
} from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { FlightClockService } from '../simulation/flight-clock.service';
import { FLIGHT_NOT_READY } from '../simulation/simulation.rules';
import { TELEMETRY_UNAVAILABLE } from '../telemetry/telemetry.rules';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { AuthorizeOrderDto } from './dto/authorize-order.dto';
import {
  LOT_NOT_AVAILABLE,
  NOT_THE_LOADING_HUB,
  NO_ELIGIBLE_DRONE,
  ONLY_PENDING_LOAD_IS_CONFIRMED,
  assertAuthorizingHub,
  assertCanAuthorize,
} from './decision.rules';
import {
  HUB_SUSPENDED_NOTE,
  buildDecisionTrace,
  traceEvaluatedHub,
  traceSkippedHub,
} from './decision-trace.rules';
import { assertOfferedTo } from './dispatch.rules';
import { clearFallback } from './fallback.rules';
import {
  RedispatchPath,
  canRedispatch,
  redispatchPath,
  releaseForRedispatch,
} from './redispatch.rules';
import { FallbackService } from './fallback.service';
import { HubEvaluationService } from './hub-evaluation.service';
import { simClock } from '../common/clock/sim-clock';

export type OrderAssignment = {
  droneId: string;
  identifier: string;
  modelName: string;
  route: PlannedCorridor;
  /**
   * Ruta de regreso, con las geovallas vigentes cuando empezó (la ida al
   * revés si una geovalla nueva la bloquea). `null` hasta que el dron sale.
   */
  returnRoute: PlannedCorridor | null;
};

@Injectable()
export class DecisionService {
  private readonly logger = new Logger(DecisionService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly hubsService: HubsService,
    private readonly routes: RoutePlannerService,
    private readonly hubEvaluation: HubEvaluationService,
    private readonly fallback: FallbackService,
    private readonly flights: FlightClockService,
    private readonly notifications: NotificationsService,
    private readonly inbox: InboxService,
  ) {}

  async authorize(user: User, orderId: string, dto: AuthorizeOrderDto = {}) {
    const hub = await this.requireDispatcherHub(user);
    assertPowered(hub);
    const result = await this.dataSource.transaction((manager) =>
      this.authorizeIn(
        manager,
        hub,
        orderId,
        dto.prescriptionVerified === true,
        simClock.now(),
      ),
    );
    await this.announce(result);
    return result;
  }

  /**
   * Reintento automático de un programado que esperaba dron. Autoriza como
   * la central que lo intentó, con la fórmula que ya verificó.
   */
  async retryScheduled(orderId: string, now = simClock.now()) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await manager.findOne(Order, {
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (
        !order?.originHubId ||
        order.status !== OrderStatus.RECEIVED ||
        order.fallbackKind !== FallbackKind.RETRY ||
        !order.retryAfter ||
        order.retryAfter > now
      ) {
        return null;
      }
      const hub = await manager.findOne(Hub, {
        where: { id: order.originHubId },
      });
      if (!hub) {
        return null;
      }
      if (isWindowClosed(order, now)) {
        return this.expireLocked(manager, order, now);
      }
      return this.authorizeIn(
        manager,
        hub,
        orderId,
        order.prescriptionVerifiedAt != null,
        now,
      );
    });
    if (result) {
      await this.announce(result);
      if (result.statusReason === WINDOW_MISSED) {
        await this.notifyMissed(result);
      }
    }
    return result;
  }

  /**
   * RF-35 y CU-44: la misión no llegó por un incidente. El pedido suelta el
   * dron y el lote, y vuelve al motor: la urgencia a una persona se ofrece
   * otra vez (lo hace `EmergencyDispatchService` con el camino `offers`), la
   * urgencia entre centrales vuelve a la cola de su central y el programado
   * sigue RF-18. En todos, la carga se confirma otra vez.
   */
  async redispatchAfterIncident(
    orderId: string,
    now = simClock.now(),
  ): Promise<RedispatchPath | null> {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await manager.findOne(Order, {
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order || !canRedispatch(order)) {
        return null;
      }
      const path = redispatchPath(order);
      const failingHubId = order.originHubId;
      await this.routes.deleteLegs(order.id, manager);
      releaseForRedispatch(order, path);
      if (path !== 'scheduled') {
        await manager.save(order);
        return { order, path, failingHubId };
      }
      const hub = failingHubId
        ? await manager.findOne(Hub, { where: { id: failingHubId } })
        : null;
      if (!hub || isWindowClosed(order, now)) {
        await this.expireLocked(manager, order, now);
        return { order, path, failingHubId };
      }
      const polygons = await this.routes.loadPolygons(manager);
      await this.withFallback(
        manager,
        order,
        hub,
        todayInColombia(now),
        polygons,
        now,
        [],
      );
      return { order, path, failingHubId };
    });
    if (!result) {
      return null;
    }
    const { order, path, failingHubId } = result;
    try {
      await this.notifications.statusChanged(order.id, order.status);
      for (const hubId of new Set(
        [failingHubId, order.originHubId].filter(
          (id): id is string => id != null,
        ),
      )) {
        await this.notifications.queueChanged(hubId, order.id);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'socket';
      this.logger.warn(`No se pudo avisar del pedido ${order.id}: ${message}`);
    }
    if (order.statusReason === WINDOW_MISSED) {
      await this.notifyMissed(presentOrder(order));
    }
    return path;
  }

  /**
   * RF-36 y CU-45: la central se quedó sin energía. Lo que esperaba en su
   * cola sale de ella (decisión del 2026-11-06): lo autorizado sin cargar
   * suelta el dron y el lote; la urgencia a una persona se ofrece otra vez
   * (camino `offers`, lo abre `EmergencyDispatchService`), la urgencia entre
   * centrales pasa a otra central y el programado sigue RF-18. Los
   * programados que nadie ha autorizado esperan en la cola.
   * Devuelve los pedidos que deben volver a ofrecerse.
   */
  async evacuateHub(hubId: string, now = simClock.now()): Promise<string[]> {
    const queued = await this.dataSource.getRepository(Order).find({
      where: {
        originHubId: hubId,
        status: In([OrderStatus.RECEIVED, OrderStatus.PENDING_LOAD]),
      },
    });
    const toOffer: string[] = [];
    for (const candidate of queued) {
      try {
        const result = await this.dataSource.transaction((manager) =>
          this.evacuateOrder(manager, candidate.id, hubId, now),
        );
        if (!result) {
          continue;
        }
        if (result.path === 'offers') {
          toOffer.push(result.order.id);
        }
        await this.notifications.statusChanged(
          result.order.id,
          result.order.status,
        );
        await this.notifications.queueChanged(hubId, result.order.id);
        if (result.order.originHubId && result.order.originHubId !== hubId) {
          await this.notifications.queueChanged(
            result.order.originHubId,
            result.order.id,
          );
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'pedido';
        this.logger.warn(
          `No se pudo mover el pedido ${candidate.id} de la central sin energía: ${message}`,
        );
      }
    }
    return toOffer;
  }

  private async evacuateOrder(
    manager: EntityManager,
    orderId: string,
    hubId: string,
    now: Date,
  ): Promise<{ order: Order; path: RedispatchPath } | null> {
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order || order.originHubId !== hubId || order.loadConfirmedAt) {
      return null;
    }
    const reserved = order.status === OrderStatus.PENDING_LOAD;
    const path = redispatchPath(order);
    if (!reserved && order.status !== OrderStatus.RECEIVED) {
      return null;
    }
    if (!reserved && path === 'scheduled' && order.fallbackKind == null) {
      // Nadie lo ha autorizado: espera en la cola a que vuelva la energía.
      return null;
    }
    if (reserved && order.droneId) {
      const drone = await manager.findOne(Drone, {
        where: { id: order.droneId },
        lock: { mode: 'pessimistic_write' },
      });
      if (drone?.status === DroneStatus.IN_MISSION) {
        drone.status = DroneStatus.AVAILABLE;
        await manager.save(drone);
      }
      await this.routes.deleteLegs(order.id, manager);
    }
    releaseForRedispatch(order, path, OUTAGE_REDISPATCH_REASON);
    if (path === 'offers') {
      await manager.save(order);
      return { order, path };
    }
    const hub = await manager.findOne(Hub, { where: { id: hubId } });
    if (!hub) {
      await manager.save(order);
      return { order, path };
    }
    if (path === 'scheduled' && isWindowClosed(order, now)) {
      await this.expireLocked(manager, order, now);
      return { order, path };
    }
    const polygons = await this.routes.loadPolygons(manager);
    await this.withFallback(
      manager,
      order,
      hub,
      todayInColombia(now),
      polygons,
      now,
      [traceSkippedHub(hub, false, HUB_WITHOUT_POWER_NOTE)],
    );
    return { order, path };
  }

  /** La franja cerró con el dron en tierra: suelta la reserva y aplica RF-18. */
  async expireMissed(orderId: string, now = simClock.now()) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await manager.findOne(Order, {
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order || !isMissedDeparture(order, now)) {
        return null;
      }
      return this.expireLocked(manager, order, now);
    });
    if (!result) {
      return null;
    }
    await this.announce(result);
    await this.notifyMissed(result);
    return result;
  }

  async confirmLoad(user: User, orderId: string) {
    const hub = await this.requireDispatcherHub(user);
    assertPowered(hub);
    if (!this.flights.isReady()) {
      throw new ServiceUnavailableException(TELEMETRY_UNAVAILABLE);
    }
    const order = await this.dataSource.transaction(async (manager) => {
      const current = await manager.findOne(Order, {
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!current) {
        throw new NotFoundException('El pedido no existe.');
      }
      if (
        current.status !== OrderStatus.PENDING_LOAD ||
        current.loadConfirmedAt != null
      ) {
        throw new BadRequestException(ONLY_PENDING_LOAD_IS_CONFIRMED);
      }
      if (current.originHubId !== hub.id) {
        throw new ForbiddenException(NOT_THE_LOADING_HUB);
      }
      assertDispatchWindow(current, simClock.now());
      const corridor = await this.routes.findOutboundMany([orderId]);
      if (!current.droneId || !corridor.has(orderId)) {
        throw new BadRequestException(FLIGHT_NOT_READY);
      }
      await this.dischargeLot(manager, current);
      current.loadConfirmedAt = simClock.now();
      return manager.save(current);
    });
    await this.flights.start(order.id);
    const [presented] = await this.attachAssignments([presentOrder(order)]);
    return presented;
  }

  async listPendingLoad(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const rows = await this.dataSource.getRepository(Order).find({
      where: { originHubId: hub.id, status: OrderStatus.PENDING_LOAD },
      order: { updatedAt: 'DESC' },
    });
    return this.attachAssignments(rows.map((row) => presentOrder(row)));
  }

  /**
   * Vuelos en curso de la central del despachador: al despegar, el pedido
   * sale de la cola y de pending-load, y esta es su entrada al mapa. Un
   * pedido entregado sigue aquí mientras su dron vuelve vacío a la central.
   */
  async listInFlight(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const live = await this.dataSource.getRepository(Order).find({
      where: {
        originHubId: hub.id,
        status: In([
          OrderStatus.IN_FLIGHT,
          OrderStatus.AWAITING_DELIVERY,
          OrderStatus.RETURNING,
        ]),
      },
      order: { updatedAt: 'DESC' },
    });
    const rows = [...live, ...(await this.emptyReturns(hub.id))].sort(
      (a, b) => b.updatedAt.getTime() - a.updatedAt.getTime(),
    );
    return this.attachAssignments(rows.map((row) => presentOrder(row)));
  }

  /**
   * Pedidos entregados cuyo dron todavía vuela de regreso a esta central.
   * Un entregado conserva su `droneId` para siempre: solo cuenta si el dron
   * sigue en misión y no tiene otro pedido vivo (la regla del mapa del
   * operador, `activeOrderByDrone`).
   */
  private async emptyReturns(hubId: string): Promise<Order[]> {
    const drones = await this.dataSource.getRepository(Drone).find({
      where: { hubId, status: DroneStatus.IN_MISSION },
    });
    if (!drones.length) {
      return [];
    }
    const droneIds = drones.map((drone) => drone.id);
    const holding = await this.dataSource.getRepository(Order).find({
      where: { droneId: In(droneIds), status: In(DRONE_HOLDING_STATUSES) },
    });
    return [...activeOrderByDrone(holding, droneIds).values()].filter(
      (order) =>
        order.status === OrderStatus.DELIVERED && order.originHubId === hubId,
    );
  }

  async attachAssignments<T extends { id: string; droneId: string | null }>(
    orders: T[],
  ) {
    const assigned = orders.filter((order) => order.droneId);
    if (!assigned.length) {
      return orders.map((order) => ({ ...order, assignment: null }));
    }
    const droneIds = [
      ...new Set(assigned.map((order) => order.droneId as string)),
    ];
    const drones = await this.dataSource.getRepository(Drone).find({
      where: { id: In(droneIds) },
    });
    const modelIds = [...new Set(drones.map((drone) => drone.droneModelId))];
    const models = modelIds.length
      ? await this.dataSource.getRepository(DroneModel).find({
          where: { id: In(modelIds) },
        })
      : [];
    const assignedIds = assigned.map((order) => order.id);
    const [routes, returnRoutes] = await Promise.all([
      this.routes.findOutboundMany(assignedIds),
      this.routes.findReturnMany(assignedIds),
    ]);
    const dronesById = new Map(drones.map((drone) => [drone.id, drone]));
    const modelsById = new Map(models.map((model) => [model.id, model]));
    return orders.map((order) => ({
      ...order,
      assignment: this.assignmentFor(
        order,
        dronesById,
        modelsById,
        routes,
        returnRoutes,
      ),
    }));
  }

  private async authorizeIn(
    manager: EntityManager,
    dispatcherHub: Hub,
    orderId: string,
    prescriptionVerified: boolean,
    now: Date,
  ) {
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order) {
      throw new NotFoundException('El pedido no existe.');
    }
    const today = todayInColombia(now);
    assertCanAuthorize(order, today, prescriptionVerified, now);
    assertAuthorizingHub(order.originHubId, dispatcherHub.id);
    // Urgencia civil escalonada: solo la autoriza una central a la que ya se
    // le ofreció (RU-10). Las urgencias anteriores no traen la lista.
    if (order.originHubId == null && order.dispatchOffers) {
      assertOfferedTo(order.dispatchOffers, dispatcherHub.id);
    }
    order.nextEscalationAt = null;
    const originHubId = order.originHubId ?? dispatcherHub.id;
    const origin = await manager.findOne(Hub, { where: { id: originHubId } });
    if (!origin) {
      throw new NotFoundException('La central no existe.');
    }
    // Un programado que esperaba dron no se queda reintentando en una
    // central suspendida o sin el lote: busca otra.
    const retrying = order.fallbackKind === FallbackKind.RETRY;
    const polygons = await this.routes.loadPolygons(manager);
    // Ninguna central llega a un destino dentro de una geovalla: se rechaza
    // en vez de reasignarlo.
    const destination = {
      latitude: order.latitude as number,
      longitude: order.longitude as number,
    };
    if (isInsideGeofence(destination, polygons)) {
      return this.rejectForbiddenDestination(manager, order, now);
    }
    const trace: HubTrace[] = [];
    // RF-36: sin energía cuenta como suspendida para el reintento automático.
    const powered = isPowered(origin, now);
    if (origin.status !== HubStatus.ACTIVE || !powered) {
      if (!retrying) {
        throw new ForbiddenException(
          powered ? 'La central está suspendida.' : HUB_WITHOUT_POWER,
        );
      }
      trace.push(
        traceSkippedHub(
          origin,
          false,
          powered ? HUB_SUSPENDED_NOTE : HUB_WITHOUT_POWER_NOTE,
        ),
      );
      return this.withFallback(
        manager,
        order,
        origin,
        today,
        polygons,
        now,
        trace,
      );
    }
    if (prescriptionVerified && !order.prescriptionVerifiedAt) {
      order.prescriptionVerifiedAt = now;
    }
    const evaluation = await this.hubEvaluation.evaluate(
      manager,
      origin,
      order,
      today,
      polygons,
      true,
    );
    trace.push(traceEvaluatedHub(origin, evaluation));
    const lot = evaluation.lot;
    if (!lot) {
      if (!retrying) {
        throw new BadRequestException(LOT_NOT_AVAILABLE);
      }
      return this.withFallback(
        manager,
        order,
        origin,
        today,
        polygons,
        now,
        trace,
      );
    }
    const chosen = evaluation.choice.chosen;
    const corridor = evaluation.corridor;
    const drone = chosen
      ? evaluation.drones.find((item) => item.id === chosen.droneId)
      : undefined;
    const model = drone
      ? evaluation.modelsById.get(drone.droneModelId)
      : undefined;
    if (!chosen || !corridor || !drone || !model) {
      return this.withFallback(
        manager,
        order,
        origin,
        today,
        polygons,
        now,
        trace,
      );
    }
    clearFallback(order);
    // `applyReservation` deja el pedido en pendiente de carga y lo guarda.
    order.decisionTrace = buildDecisionTrace(
      { ...order, status: OrderStatus.PENDING_LOAD },
      trace,
      now,
    );
    await this.applyReservation(
      manager,
      order,
      drone,
      lot,
      originHubId,
      corridor,
      chosen.preemptsOrderId,
    );
    return {
      ...presentOrder(order),
      assignment: {
        droneId: drone.id,
        identifier: drone.identifier,
        modelName: model.name,
        route: corridor,
        returnRoute: null,
      },
    };
  }

  private async applyReservation(
    manager: EntityManager,
    order: Order,
    drone: Drone,
    lot: InventoryItem,
    originHubId: string,
    corridor: PlannedCorridor,
    preemptsOrderId: string | null,
  ) {
    if (preemptsOrderId) {
      const held = await manager.findOne(Order, {
        where: { id: preemptsOrderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (
        !held ||
        held.droneId !== drone.id ||
        held.status !== OrderStatus.PENDING_LOAD ||
        held.missionType !== MissionType.SCHEDULED
      ) {
        throw new ConflictException(NO_ELIGIBLE_DRONE);
      }
      held.status = OrderStatus.RECEIVED;
      held.droneId = null;
      held.inventoryItemId = null;
      await manager.save(held);
      await this.routes.deleteOutbound(held.id, manager);
    }
    drone.status = DroneStatus.IN_MISSION;
    await manager.save(drone);
    order.status = OrderStatus.PENDING_LOAD;
    order.authorizedAt = simClock.now();
    order.droneId = drone.id;
    order.inventoryItemId = lot.id;
    order.originHubId = originHubId;
    await manager.save(order);
    await this.routes.saveOutbound(order.id, corridor, manager);
  }

  /**
   * persona.md paso 5 y centrales.md paso 3: al confirmar la carga sale el
   * lote reservado. Queda el registro de salida (lote y vencimiento) para el
   * reingreso o la recepción en destino.
   */
  private async dischargeLot(manager: EntityManager, order: Order) {
    const lot = order.inventoryItemId
      ? await manager.findOne(InventoryItem, {
          where: { id: order.inventoryItemId },
          lock: { mode: 'pessimistic_write' },
        })
      : null;
    if (
      !lot ||
      lot.hubId !== order.originHubId ||
      lot.quantity < order.quantity ||
      lot.expirationDate < todayInColombia()
    ) {
      throw new BadRequestException(LOT_NOT_AVAILABLE);
    }
    lot.quantity -= order.quantity;
    await manager.save(lot);
    order.dispatchedLot = lot.lot;
    order.dispatchedLotExpiresOn = lot.expirationDate;
  }

  private async expireLocked(manager: EntityManager, order: Order, now: Date) {
    if (order.droneId) {
      const drone = await manager.findOne(Drone, {
        where: { id: order.droneId },
        lock: { mode: 'pessimistic_write' },
      });
      if (drone?.status === DroneStatus.IN_MISSION) {
        drone.status = DroneStatus.AVAILABLE;
        await manager.save(drone);
      }
      await this.routes.deleteOutbound(order.id, manager);
      order.droneId = null;
      order.inventoryItemId = null;
    }
    const window = dispatchWindow(order);
    if (window && !order.scheduledAt) {
      order.scheduledAt = new Date(window.opensAt.getTime() + SCHEDULE_LEAD_MS);
    }
    if (window && !order.windowEndsAt) {
      order.windowEndsAt = window.closesAt;
    }
    order.statusReason = WINDOW_MISSED;
    const hub = order.originHubId
      ? await manager.findOne(Hub, { where: { id: order.originHubId } })
      : null;
    if (!hub || order.latitude == null || order.longitude == null) {
      order.status = OrderStatus.EXPIRED;
      await manager.save(order);
      return { ...presentOrder(order), assignment: null };
    }
    const polygons = await this.routes.loadPolygons(manager);
    const trace: HubTrace[] = [];
    await this.fallback.resolve(
      manager,
      order,
      hub,
      todayInColombia(now),
      polygons,
      now,
      trace,
    );
    order.statusReason = WINDOW_MISSED;
    order.decisionTrace = buildDecisionTrace(order, trace, now);
    await manager.save(order);
    return { ...presentOrder(order), assignment: null };
  }

  private async rejectForbiddenDestination(
    manager: EntityManager,
    order: Order,
    now: Date,
  ) {
    clearFallback(order);
    order.status = OrderStatus.REJECTED;
    order.statusReason = DESTINATION_IN_GEOFENCE;
    order.decisionTrace = buildDecisionTrace(order, [], now);
    await manager.save(order);
    return { ...presentOrder(order), assignment: null };
  }

  private async withFallback(
    manager: EntityManager,
    order: Order,
    failingHub: Hub,
    today: string,
    polygons: GeoJsonPolygon[],
    now: Date,
    trace: HubTrace[],
  ) {
    await this.fallback.resolve(
      manager,
      order,
      failingHub,
      today,
      polygons,
      now,
      trace,
    );
    order.decisionTrace = buildDecisionTrace(order, trace, now);
    await manager.save(order);
    return { ...presentOrder(order), assignment: null };
  }

  /**
   * Avisos por el socket, ya confirmada la transacción. Un aviso que no sale
   * (Redis caído) no deshace la decisión: la app también refresca sola.
   */
  private async notifyMissed(order: {
    id: string;
    destinationKind: DestinationKind;
    requesterId: string | null;
    destinationHubId: string | null;
    scheduledAt: Date | null;
    windowEndsAt: Date | null;
    fallback: { kind: FallbackKind } | null;
  }): Promise<void> {
    if (!order.scheduledAt || !order.windowEndsAt) {
      return;
    }
    const notice = {
      kind: NotificationKind.DELIVERY_MISSED,
      orderId: order.id,
      ...missedCopy(
        order.scheduledAt,
        order.windowEndsAt,
        order.fallback?.kind === FallbackKind.HUB,
      ),
    };
    try {
      if (order.destinationKind === DestinationKind.HUB) {
        if (order.destinationHubId) {
          await this.inbox.notifyHubDispatchers(order.destinationHubId, notice);
        }
        return;
      }
      if (order.requesterId) {
        await this.inbox.notifyUser(order.requesterId, notice);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'aviso';
      this.logger.warn(
        `No se pudo avisar el vencimiento de ${order.id}: ${message}`,
      );
    }
  }

  /** CU-29: cada salida del motor que cambia el pedido se avisa por el socket. */
  private async announce(order: {
    id: string;
    status: OrderStatus;
    originHubId: string | null;
  }): Promise<void> {
    const changed =
      order.status === OrderStatus.REASSIGNED ||
      order.status === OrderStatus.REJECTED ||
      order.status === OrderStatus.EXPIRED ||
      order.status === OrderStatus.PENDING_LOAD;
    if (!changed) {
      return;
    }
    try {
      await this.notifications.statusChanged(order.id, order.status);
      if (order.originHubId) {
        await this.notifications.queueChanged(order.originHubId, order.id);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'socket';
      this.logger.warn(`No se pudo avisar del pedido ${order.id}: ${message}`);
    }
  }

  private assignmentFor(
    order: { id: string; droneId: string | null },
    dronesById: Map<string, Drone>,
    modelsById: Map<string, DroneModel>,
    routes: Map<string, PlannedCorridor>,
    returnRoutes: Map<string, PlannedCorridor>,
  ): OrderAssignment | null {
    if (!order.droneId) {
      return null;
    }
    const drone = dronesById.get(order.droneId);
    const model = drone ? modelsById.get(drone.droneModelId) : undefined;
    const route = routes.get(order.id);
    if (!drone || !model || !route) {
      return null;
    }
    return {
      droneId: drone.id,
      identifier: drone.identifier,
      modelName: model.name,
      route,
      returnRoute: returnRoutes.get(order.id) ?? null,
    };
  }

  private async requireDispatcherHub(user: User): Promise<Hub> {
    if (user.role !== UserRole.DISPATCHER) {
      throw new ForbiddenException('Solo el despachador autoriza una salida.');
    }
    const hubIds = assignedHubIds(user);
    if (hubIds.length !== 1) {
      throw new ForbiddenException(
        'Debes tener una central asignada para gestionar pedidos.',
      );
    }
    return this.hubsService.requireActive(hubIds[0]);
  }
}

/** RF-36: sin energía no se autoriza ni se confirma la carga. */
function assertPowered(hub: Hub): void {
  if (!isPowered(hub, simClock.now())) {
    throw new ConflictException(HUB_WITHOUT_POWER);
  }
}
