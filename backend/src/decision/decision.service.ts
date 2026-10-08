import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager, In } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { presentOrder } from '../orders/order.presenter';
import { Order } from '../orders/order.entity';
import { todayInColombia } from '../orders/orders.rules';
import { PlannedCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { AuthorizeOrderDto } from './dto/authorize-order.dto';
import { EligibilityService } from './eligibility.service';
import {
  DroneCandidate,
  LOT_NOT_AVAILABLE,
  NO_ELIGIBLE_DRONE,
  assertAuthorizingHub,
  assertCanAuthorize,
  simulatedWeather,
} from './decision.rules';

export type OrderAssignment = {
  droneId: string;
  identifier: string;
  modelName: string;
  route: PlannedCorridor;
};

@Injectable()
export class DecisionService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly hubsService: HubsService,
    private readonly routes: RoutePlannerService,
    private readonly eligibility: EligibilityService,
  ) {}

  async authorize(user: User, orderId: string, dto: AuthorizeOrderDto = {}) {
    const hub = await this.requireDispatcherHub(user);
    return this.dataSource.transaction((manager) =>
      this.authorizeIn(manager, hub, orderId, dto),
    );
  }

  async listPendingLoad(user: User) {
    const hub = await this.requireDispatcherHub(user);
    const rows = await this.dataSource.getRepository(Order).find({
      where: { originHubId: hub.id, status: OrderStatus.PENDING_LOAD },
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
    dto: AuthorizeOrderDto,
  ) {
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order) {
      throw new NotFoundException('El pedido no existe.');
    }
    const today = todayInColombia();
    assertCanAuthorize(order, today, dto.prescriptionVerified);
    assertAuthorizingHub(order.originHubId, dispatcherHub.id);
    const originHubId = order.originHubId ?? dispatcherHub.id;
    const origin = await manager.findOne(Hub, { where: { id: originHubId } });
    if (!origin) {
      throw new NotFoundException('La central no existe.');
    }
    if (origin.status !== HubStatus.ACTIVE) {
      throw new ForbiddenException('La central está suspendida.');
    }
    const lot = await this.findFefoLot(manager, originHubId, order, today);
    if (!lot) {
      throw new BadRequestException(LOT_NOT_AVAILABLE);
    }
    const drones = await manager
      .createQueryBuilder(Drone, 'drone')
      .where('drone.hubId = :hubId', { hubId: originHubId })
      .orderBy('drone.id', 'ASC')
      .setLock('pessimistic_write')
      .getMany();
    const modelsById = await this.modelsById(manager, drones);
    const heldByDrone = await this.heldByDrone(manager, drones);
    const polygons = await this.routes.loadPolygons(manager);
    const corridor = this.routes.plan(
      { longitude: origin.longitude, latitude: origin.latitude },
      {
        longitude: order.longitude as number,
        latitude: order.latitude as number,
      },
      polygons,
    );
    const choice = this.eligibility.choose({
      missionType: order.missionType,
      quantity: order.quantity,
      weatherFlyable: simulatedWeather().flyable,
      candidates: drones.flatMap((drone) => {
        const model = modelsById.get(drone.droneModelId);
        if (!model) {
          return [];
        }
        return [
          {
            drone: toCandidate(drone, model, heldByDrone.get(drone.id) ?? null),
            distanceKm: corridor?.distanceKm ?? null,
          },
        ];
      }),
    });
    if (!choice.chosen || !corridor) {
      throw new ConflictException(NO_ELIGIBLE_DRONE);
    }
    const chosen = choice.chosen;
    const drone = drones.find((item) => item.id === chosen.droneId);
    const model = drone ? modelsById.get(drone.droneModelId) : undefined;
    if (!drone || !model) {
      throw new ConflictException(NO_ELIGIBLE_DRONE);
    }
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

  private async findFefoLot(
    manager: EntityManager,
    hubId: string,
    order: Order,
    today: string,
  ) {
    return manager
      .createQueryBuilder(InventoryItem, 'item')
      .where('item.hubId = :hubId', { hubId })
      .andWhere('LOWER(item.name) = :name', {
        name: order.medicationName.trim().toLowerCase(),
      })
      .andWhere('item.saleType = :saleType', { saleType: order.saleType })
      .andWhere('item.expirationDate >= :today', { today })
      .andWhere('item.quantity >= :quantity', { quantity: order.quantity })
      .orderBy('item.expirationDate', 'ASC')
      .addOrderBy('item.lot', 'ASC')
      .setLock('pessimistic_write')
      .getOne();
  }

  private async modelsById(manager: EntityManager, drones: Drone[]) {
    const modelIds = [...new Set(drones.map((drone) => drone.droneModelId))];
    if (!modelIds.length) {
      return new Map<string, DroneModel>();
    }
    const models = await manager.find(DroneModel, {
      where: { id: In(modelIds) },
    });
    return new Map(models.map((model) => [model.id, model]));
  }

  private async heldByDrone(manager: EntityManager, drones: Drone[]) {
    const droneIds = drones.map((drone) => drone.id);
    if (!droneIds.length) {
      return new Map<string, Order>();
    }
    const held = await manager.find(Order, {
      where: { droneId: In(droneIds), status: OrderStatus.PENDING_LOAD },
    });
    return new Map(
      held
        .filter((order) => order.droneId)
        .map((order) => [order.droneId as string, order]),
    );
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

function toCandidate(
  drone: Drone,
  model: DroneModel,
  held: Order | null,
): DroneCandidate {
  return {
    id: drone.id,
    identifier: drone.identifier,
    status: drone.status,
    maxPayloadKg: model.maxPayloadKg,
    maxRangeKm: model.maxRangeKm,
    held: held
      ? {
          orderId: held.id,
          missionType: held.missionType,
          status: held.status,
        }
      : null,
  };
}
