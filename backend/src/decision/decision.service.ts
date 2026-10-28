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
import { DroneModel } from '../fleet/drone-model.entity';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { presentOrder } from '../orders/order.presenter';
import { Order } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { PlannedCorridor } from '../routing/routing.rules';
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
import { clearFallback } from './fallback.rules';
import { FallbackService } from './fallback.service';
import { HubEvaluationService } from './hub-evaluation.service';

export type OrderAssignment = {
  droneId: string;
  identifier: string;
  modelName: string;
  route: PlannedCorridor;
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
  ) {}

  async authorize(user: User, orderId: string, dto: AuthorizeOrderDto = {}) {
    const hub = await this.requireDispatcherHub(user);
    const result = await this.dataSource.transaction((manager) =>
      this.authorizeIn(
        manager,
        hub,
        orderId,
        dto.prescriptionVerified === true,
        new Date(),
      ),
    );
    await this.announce(result, false);
    return result;
  }

  /**
   * Reintento automático de un programado que esperaba dron. Autoriza como
   * la central que lo intentó, con la fórmula que ya verificó.
   */
  async retryScheduled(orderId: string, now = new Date()) {
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
      return this.authorizeIn(
        manager,
        hub,
        orderId,
        order.prescriptionVerifiedAt != null,
        now,
      );
    });
    if (result) {
      await this.announce(result, true);
    }
    return result;
  }

  async confirmLoad(user: User, orderId: string) {
    const hub = await this.requireDispatcherHub(user);
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
      const corridor = await this.routes.findOutboundMany([orderId]);
      if (!current.droneId || !corridor.has(orderId)) {
        throw new BadRequestException(FLIGHT_NOT_READY);
      }
      await this.dischargeLot(manager, current);
      current.loadConfirmedAt = new Date();
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
   * sale de la cola y de pending-load, y esta es su entrada al mapa.
   */
  async listInFlight(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const rows = await this.dataSource.getRepository(Order).find({
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
    return this.attachAssignments(rows.map((row) => presentOrder(row)));
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
    const routes = await this.routes.findOutboundMany(
      assigned.map((order) => order.id),
    );
    const dronesById = new Map(drones.map((drone) => [drone.id, drone]));
    const modelsById = new Map(models.map((model) => [model.id, model]));
    return orders.map((order) => ({
      ...order,
      assignment: this.assignmentFor(order, dronesById, modelsById, routes),
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
    assertCanAuthorize(order, today, prescriptionVerified);
    assertAuthorizingHub(order.originHubId, dispatcherHub.id);
    const originHubId = order.originHubId ?? dispatcherHub.id;
    const origin = await manager.findOne(Hub, { where: { id: originHubId } });
    if (!origin) {
      throw new NotFoundException('La central no existe.');
    }
    // Un programado que esperaba dron no se queda reintentando en una
    // central suspendida o sin el lote: busca otra.
    const retrying = order.fallbackKind === FallbackKind.RETRY;
    const polygons = await this.routes.loadPolygons(manager);
    if (origin.status !== HubStatus.ACTIVE) {
      if (!retrying) {
        throw new ForbiddenException('La central está suspendida.');
      }
      return this.withFallback(manager, order, origin, today, polygons, now);
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
    const lot = evaluation.lot;
    if (!lot) {
      if (!retrying) {
        throw new BadRequestException(LOT_NOT_AVAILABLE);
      }
      return this.withFallback(manager, order, origin, today, polygons, now);
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
      return this.withFallback(manager, order, origin, today, polygons, now);
    }
    clearFallback(order);
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

  private async withFallback(
    manager: EntityManager,
    order: Order,
    failingHub: Hub,
    today: string,
    polygons: GeoJsonPolygon[],
    now: Date,
  ) {
    await this.fallback.resolve(
      manager,
      order,
      failingHub,
      today,
      polygons,
      now,
    );
    return { ...presentOrder(order), assignment: null };
  }

  /**
   * Avisos por el socket, ya confirmada la transacción. Un aviso que no sale
   * (Redis caído) no deshace la decisión: la app también refresca sola.
   */
  private async announce(
    order: { id: string; status: OrderStatus; originHubId: string | null },
    retried: boolean,
  ): Promise<void> {
    const changed =
      order.status === OrderStatus.REASSIGNED ||
      (retried && order.status === OrderStatus.PENDING_LOAD);
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
