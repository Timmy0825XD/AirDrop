import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { Order } from '../orders/order.entity';
import { addCalendarDays, todayInColombia } from '../orders/orders.rules';
import { PlannedCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { User } from '../users/user.entity';
import { DecisionService } from './decision.service';
import { EligibilityService } from './eligibility.service';
import {
  LOT_NOT_AVAILABLE,
  NO_ELIGIBLE_DRONE,
  NOT_THE_AUTHORIZING_HUB,
  PRESCRIPTION_NOT_VERIFIED,
  SCHEDULED_TOO_EARLY,
} from './decision.rules';

const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const OTHER_HUB_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const HELD_ID = '22222222-2222-4222-8222-222222222222';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const MODEL_ID = '44444444-4444-4444-8444-444444444444';
const LOT_ID = '55555555-5555-4555-8555-555555555555';

const corridor: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 4.5,
  coordinates: [
    [-73.26, 10.47],
    [-73.25, 10.46],
  ],
};

function dispatcher(): User {
  return {
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: HUB_ID }],
  } as unknown as User;
}

function hub(): Hub {
  return {
    id: HUB_ID,
    status: HubStatus.ACTIVE,
    latitude: 10.47,
    longitude: -73.26,
  } as Hub;
}

function model(): DroneModel {
  return {
    id: MODEL_ID,
    name: 'Wingcopter 198',
    maxPayloadKg: 6,
    maxRangeKm: 110,
  } as DroneModel;
}

function drone(overrides: Partial<Drone> = {}): Drone {
  return {
    id: DRONE_ID,
    identifier: 'WC-01',
    droneModelId: MODEL_ID,
    hubId: HUB_ID,
    status: DroneStatus.AVAILABLE,
    ...overrides,
  } as Drone;
}

function lot(): InventoryItem {
  return {
    id: LOT_ID,
    quantity: 8,
    lot: 'L-1',
    expirationDate: '2027-01-01',
  } as InventoryItem;
}

function received(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    status: OrderStatus.RECEIVED,
    priority: OrderPriority.HIGH,
    medicationName: 'Acetaminofén 500 mg',
    saleType: SaleType.OVER_THE_COUNTER,
    requiresColdChain: false,
    quantity: 1,
    description: null,
    requesterId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    createdByUserId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    destinationHubId: null,
    originHubId: null,
    address: 'Calle 20 # 8-15',
    latitude: 10.46,
    longitude: -73.25,
    droneId: null,
    inventoryItemId: null,
    statusReason: null,
    planId: null,
    scheduledFor: null,
    createdAt: new Date('2026-10-08T15:00:00.000Z'),
    updatedAt: new Date('2026-10-08T15:00:00.000Z'),
    ...overrides,
  };
}

function build(state?: {
  order?: Order;
  drones?: Drone[];
  held?: Order | null;
  currentLot?: InventoryItem | null;
}) {
  const order = state?.order ?? received();
  const drones = state?.drones ?? [drone()];
  const held = state?.held ?? null;
  const currentLot = state && 'currentLot' in state ? state.currentLot : lot();
  const saved: unknown[] = [];
  const lotQuery = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    addOrderBy: jest.fn().mockReturnThis(),
    setLock: jest.fn().mockReturnThis(),
    getOne: jest.fn().mockResolvedValue(currentLot),
  };
  const droneQuery = {
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    setLock: jest.fn().mockReturnThis(),
    getMany: jest.fn().mockResolvedValue(drones),
  };
  const manager = {
    findOne: jest.fn((entity: unknown, options: { where: { id?: string } }) => {
      if (entity === Order && options.where.id === order.id) return order;
      if (held && entity === Order && options.where.id === held.id) return held;
      if (entity === Hub && options.where.id === hub().id) return hub();
      return null;
    }),
    find: jest.fn((entity: unknown) => {
      if (entity === DroneModel) return [model()];
      if (entity === Order) return held ? [held] : [];
      return [];
    }),
    createQueryBuilder: jest.fn((entity: unknown) => {
      if (entity === InventoryItem) return lotQuery;
      if (entity === Drone) return droneQuery;
      throw new Error('Consulta inesperada');
    }),
    save: jest.fn((entity: unknown) => {
      saved.push(entity);
      return entity;
    }),
  };
  const dataSource = {
    transaction: jest.fn((work: (unit: EntityManager) => Promise<unknown>) =>
      work(manager as unknown as EntityManager),
    ),
    getRepository: jest.fn(),
  };
  const routes = {
    loadPolygons: jest.fn().mockResolvedValue([]),
    plan: jest.fn().mockReturnValue(corridor),
    saveOutbound: jest.fn(),
    deleteOutbound: jest.fn(),
    findOutboundMany: jest.fn().mockResolvedValue(new Map()),
  };
  const hubsService = {
    requireActive: jest.fn().mockResolvedValue(hub()),
  };
  const service = new DecisionService(
    dataSource as unknown as DataSource,
    hubsService as unknown as HubsService,
    routes as unknown as RoutePlannerService,
    new EligibilityService(),
  );
  return {
    service,
    order,
    drones,
    held,
    currentLot,
    manager,
    routes,
    saved,
    dataSource,
  };
}

describe('DecisionService.authorize', () => {
  it('reserves a drone in pending load without discounting stock or taking off', async () => {
    const { service, order, drones, currentLot, routes, manager } = build();
    const result = await service.authorize(dispatcher(), order.id, {});
    expect(result.status).toBe(OrderStatus.PENDING_LOAD);
    expect(result.status).not.toBe(OrderStatus.IN_FLIGHT);
    expect(result.droneId).toBe(DRONE_ID);
    expect(result.originHubId).toBe(HUB_ID);
    expect(result.assignment).toEqual({
      droneId: DRONE_ID,
      identifier: 'WC-01',
      modelName: 'Wingcopter 198',
      route: corridor,
    });
    expect(drones[0].status).toBe(DroneStatus.IN_MISSION);
    expect(currentLot?.quantity).toBe(8);
    expect(order.inventoryItemId).toBe(LOT_ID);
    expect(manager.save).not.toHaveBeenCalledWith(currentLot);
    expect(routes.saveOutbound).toHaveBeenCalledWith(
      order.id,
      corridor,
      manager,
    );
  });

  it('gives an emergency the drone reserved by a scheduled load', async () => {
    const reserved = drone({ status: DroneStatus.IN_MISSION });
    const held = received({
      id: HELD_ID,
      missionType: MissionType.SCHEDULED,
      status: OrderStatus.PENDING_LOAD,
      droneId: reserved.id,
      inventoryItemId: LOT_ID,
      originHubId: HUB_ID,
      scheduledFor: todayInColombia(),
    });
    const emergency = received();
    const { service, routes, manager } = build({
      order: emergency,
      drones: [reserved],
      held,
    });
    const result = await service.authorize(dispatcher(), emergency.id, {});
    expect(result.status).toBe(OrderStatus.PENDING_LOAD);
    expect(result.droneId).toBe(reserved.id);
    expect(held.status).toBe(OrderStatus.RECEIVED);
    expect(held.droneId).toBeNull();
    expect(held.inventoryItemId).toBeNull();
    expect(reserved.status).toBe(DroneStatus.IN_MISSION);
    expect(routes.deleteOutbound).toHaveBeenCalledWith(held.id, manager);
    expect(routes.saveOutbound).toHaveBeenCalledWith(
      emergency.id,
      corridor,
      manager,
    );
  });

  it('does not take a drone already reserved by another emergency', async () => {
    const reserved = drone({ status: DroneStatus.IN_MISSION });
    const held = received({
      id: HELD_ID,
      missionType: MissionType.EMERGENCY,
      status: OrderStatus.PENDING_LOAD,
      droneId: reserved.id,
      originHubId: HUB_ID,
    });
    const emergency = received();
    const { service, manager } = build({
      order: emergency,
      drones: [reserved],
      held,
    });
    await expect(
      service.authorize(dispatcher(), emergency.id, {}),
    ).rejects.toThrow(new ConflictException(NO_ELIGIBLE_DRONE));
    expect(emergency.status).toBe(OrderStatus.RECEIVED);
    expect(emergency.droneId).toBeNull();
    expect(held.status).toBe(OrderStatus.PENDING_LOAD);
    expect(held.droneId).toBe(reserved.id);
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('leaves the order received when no drone is eligible', async () => {
    const grounded = drone({ status: DroneStatus.MAINTENANCE });
    const { service, order, manager } = build({ drones: [grounded] });
    await expect(service.authorize(dispatcher(), order.id, {})).rejects.toThrow(
      new ConflictException(NO_ELIGIBLE_DRONE),
    );
    expect(order.status).toBe(OrderStatus.RECEIVED);
    expect(order.droneId).toBeNull();
    expect(grounded.status).toBe(DroneStatus.MAINTENANCE);
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('rejects a missing prescription, a future date, a short lot and the wrong hub', async () => {
    const prescription = received({ saleType: SaleType.PRESCRIPTION });
    const future = received({
      missionType: MissionType.SCHEDULED,
      scheduledFor: addCalendarDays(todayInColombia(), 1),
    });
    const foreign = received({ originHubId: OTHER_HUB_ID });
    await expect(
      build({ order: prescription }).service.authorize(
        dispatcher(),
        prescription.id,
        {},
      ),
    ).rejects.toThrow(new BadRequestException(PRESCRIPTION_NOT_VERIFIED));
    await expect(
      build({ order: future }).service.authorize(dispatcher(), future.id, {}),
    ).rejects.toThrow(new BadRequestException(SCHEDULED_TOO_EARLY));
    await expect(
      build({ currentLot: null }).service.authorize(dispatcher(), ORDER_ID, {}),
    ).rejects.toThrow(new BadRequestException(LOT_NOT_AVAILABLE));
    await expect(
      build({ order: foreign }).service.authorize(dispatcher(), foreign.id, {}),
    ).rejects.toThrow(new ForbiddenException(NOT_THE_AUTHORIZING_HUB));
    expect(prescription.status).toBe(OrderStatus.RECEIVED);
    expect(future.status).toBe(OrderStatus.RECEIVED);
    expect(foreign.droneId).toBeNull();
  });
});

describe('DecisionService.listPendingLoad', () => {
  it('lists only the authorized orders of the dispatcher hub', async () => {
    const pending = received({
      status: OrderStatus.PENDING_LOAD,
      originHubId: HUB_ID,
      droneId: DRONE_ID,
    });
    const orders = { find: jest.fn().mockResolvedValue([pending]) };
    const drones = {
      find: jest
        .fn()
        .mockResolvedValue([drone({ status: DroneStatus.IN_MISSION })]),
    };
    const models = { find: jest.fn().mockResolvedValue([model()]) };
    const { service, dataSource, routes } = build();
    dataSource.getRepository.mockImplementation((entity: unknown) => {
      if (entity === Order) return orders;
      if (entity === Drone) return drones;
      if (entity === DroneModel) return models;
      throw new Error('Repositorio inesperado');
    });
    routes.findOutboundMany.mockResolvedValue(
      new Map([[pending.id, corridor]]),
    );
    const rows = await service.listPendingLoad(dispatcher());
    expect(orders.find).toHaveBeenCalledWith({
      where: { originHubId: HUB_ID, status: OrderStatus.PENDING_LOAD },
      order: { updatedAt: 'DESC' },
    });
    expect(rows[0].assignment?.identifier).toBe('WC-01');
    expect(rows[0].assignment?.route.altitudeM).toBe(100);
  });
});
