import {
  BadRequestException,
  ForbiddenException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { DataSource, EntityManager, In } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
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
import { NotificationsService } from '../notifications/notifications.service';
import { Order } from '../orders/order.entity';
import { addCalendarDays, todayInColombia } from '../orders/orders.rules';
import { PlannedCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { FlightClockService } from '../simulation/flight-clock.service';
import { User } from '../users/user.entity';
import { DecisionService } from './decision.service';
import { EligibilityService } from './eligibility.service';
import { CONVENTIONAL_WITH_STOCK } from './fallback.rules';
import { FallbackService } from './fallback.service';
import { HubEvaluationService } from './hub-evaluation.service';
import {
  LOT_NOT_AVAILABLE,
  NOT_THE_AUTHORIZING_HUB,
  NOT_THE_LOADING_HUB,
  ONLY_PENDING_LOAD_IS_CONFIRMED,
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

function hub(overrides: Partial<Hub> = {}): Hub {
  return {
    id: HUB_ID,
    name: 'Hospital Rosario',
    address: 'Calle 16 # 10-20',
    contactPhone: '3001234567',
    contactEmail: null,
    status: HubStatus.ACTIVE,
    latitude: 10.47,
    longitude: -73.26,
    ...overrides,
  } as Hub;
}

function otherHub(): Hub {
  return hub({
    id: OTHER_HUB_ID,
    name: 'Clínica Norte',
    latitude: 10.48,
    longitude: -73.24,
  });
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
    hubId: HUB_ID,
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
    authorizedAt: null,
    loadConfirmedAt: null,
    dispatchedLot: null,
    dispatchedLotExpiresOn: null,
    returnCheckedAt: null,
    returnOutcome: null,
    receiptRejectedReason: null,
    receiptSealIntact: null,
    coldChainAlertAt: null,
    statusReason: null,
    planId: null,
    scheduledFor: null,
    scheduledAt: null,
    windowEndsAt: null,
    confirmedAt: null,
    remindedAt: null,
    fallbackKind: null,
    fallbackReason: null,
    fallbackOptions: null,
    reassignedFromHubId: null,
    reassignedAt: null,
    retryAfter: null,
    prescriptionVerifiedAt: null,
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
  hubs?: Hub[];
  lotsByHub?: Record<string, InventoryItem | null>;
  dronesByHub?: Record<string, Drone[]>;
}) {
  const order = state?.order ?? received();
  const drones = state?.drones ?? [drone()];
  const held = state?.held ?? null;
  const currentLot = state && 'currentLot' in state ? state.currentLot : lot();
  const hubs = state?.hubs ?? [hub()];
  const lotsByHub: Record<string, InventoryItem | null | undefined> = {
    [HUB_ID]: currentLot,
    ...state?.lotsByHub,
  };
  const dronesByHub: Record<string, Drone[]> = {
    [HUB_ID]: drones,
    ...state?.dronesByHub,
  };
  const saved: unknown[] = [];
  // Cada consulta recuerda la central de su `where` para responder por ella.
  const query = (answer: (hubId: string) => unknown) => {
    let hubId = '';
    const builder: Record<string, jest.Mock> = {
      where: jest.fn((_sql: string, params: { hubId: string }) => {
        hubId = params.hubId;
        return builder;
      }),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      addOrderBy: jest.fn().mockReturnThis(),
      setLock: jest.fn().mockReturnThis(),
      getOne: jest.fn(() => Promise.resolve(answer(hubId) ?? null)),
      getMany: jest.fn(() => Promise.resolve(answer(hubId) ?? [])),
    };
    return builder;
  };
  const manager = {
    findOne: jest.fn((entity: unknown, options: { where: { id?: string } }) => {
      if (entity === Order && options.where.id === order.id) return order;
      if (held && entity === Order && options.where.id === held.id) return held;
      if (entity === Hub) {
        return hubs.find((item) => item.id === options.where.id) ?? null;
      }
      if (entity === InventoryItem && currentLot?.id === options.where.id) {
        return currentLot;
      }
      return null;
    }),
    find: jest.fn((entity: unknown) => {
      if (entity === DroneModel) return [model()];
      if (entity === Order) return held ? [held] : [];
      if (entity === Hub) return hubs;
      return [];
    }),
    createQueryBuilder: jest.fn((entity: unknown) => {
      if (entity === InventoryItem) return query((id) => lotsByHub[id]);
      if (entity === Drone) return query((id) => dronesByHub[id]);
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
    getRepository: jest.fn().mockReturnValue({
      find: jest.fn().mockResolvedValue([]),
    }),
  };
  const flights = {
    isReady: jest.fn().mockReturnValue(true),
    start: jest.fn(),
  };
  const routes = {
    loadPolygons: jest.fn().mockResolvedValue([]),
    plan: jest.fn().mockReturnValue(corridor),
    saveOutbound: jest.fn(),
    deleteOutbound: jest.fn(),
    findOutboundMany: jest.fn().mockResolvedValue(new Map()),
    findReturnMany: jest.fn().mockResolvedValue(new Map()),
  };
  const hubsService = {
    requireActive: jest.fn().mockResolvedValue(hub()),
  };
  const notifications = {
    statusChanged: jest.fn().mockResolvedValue(undefined),
    queueChanged: jest.fn().mockResolvedValue(undefined),
  };
  const hubEvaluation = new HubEvaluationService(
    routes as unknown as RoutePlannerService,
    new EligibilityService(),
  );
  const service = new DecisionService(
    dataSource as unknown as DataSource,
    hubsService as unknown as HubsService,
    routes as unknown as RoutePlannerService,
    hubEvaluation,
    new FallbackService(hubEvaluation),
    flights as unknown as FlightClockService,
    notifications as unknown as NotificationsService,
  );
  return {
    service,
    order,
    drones,
    held,
    currentLot,
    manager,
    routes,
    flights,
    notifications,
    saved,
    dataSource,
  };
}

describe('DecisionService.authorize', () => {
  it('reserves a drone in pending load without discounting stock or taking off', async () => {
    const { service, order, drones, currentLot, routes, manager, flights } =
      build();
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
      returnRoute: null,
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
    expect(flights.start).not.toHaveBeenCalled();
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

  it('does not take a drone held by another emergency: with no other hub it falls back to conventional', async () => {
    const reserved = drone({ status: DroneStatus.IN_MISSION });
    const held = received({
      id: HELD_ID,
      missionType: MissionType.EMERGENCY,
      status: OrderStatus.PENDING_LOAD,
      droneId: reserved.id,
      originHubId: HUB_ID,
    });
    const emergency = received();
    const { service, routes, notifications } = build({
      order: emergency,
      drones: [reserved],
      held,
    });
    const result = await service.authorize(dispatcher(), emergency.id, {});
    expect(result.status).toBe(OrderStatus.REASSIGNED);
    expect(result.assignment).toBeNull();
    expect(result.fallback?.kind).toBe(FallbackKind.CONVENTIONAL);
    expect(result.fallback?.reason).toBe(CONVENTIONAL_WITH_STOCK);
    // La central que falló tiene el insumo: el solicitante puede ir por él.
    expect(result.fallback?.options.map((option) => option.hubId)).toEqual([
      HUB_ID,
    ]);
    expect(emergency.droneId).toBeNull();
    expect(held.status).toBe(OrderStatus.PENDING_LOAD);
    expect(held.droneId).toBe(reserved.id);
    expect(routes.saveOutbound).not.toHaveBeenCalled();
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      emergency.id,
      OrderStatus.REASSIGNED,
    );
  });

  it('moves a civil emergency to the nearest hub with stock and a free drone', async () => {
    const grounded = drone({ status: DroneStatus.MAINTENANCE });
    const spare = drone({
      id: HELD_ID,
      identifier: 'WC-02',
      hubId: OTHER_HUB_ID,
    });
    const { service, order, routes, notifications } = build({
      drones: [grounded],
      hubs: [hub(), otherHub()],
      lotsByHub: { [OTHER_HUB_ID]: lot() },
      dronesByHub: { [OTHER_HUB_ID]: [spare] },
    });
    const result = await service.authorize(dispatcher(), order.id, {});
    expect(result.status).toBe(OrderStatus.REASSIGNED);
    expect(result.originHubId).toBe(OTHER_HUB_ID);
    expect(result.reassignedFromHubId).toBe(HUB_ID);
    expect(result.fallback?.kind).toBe(FallbackKind.HUB);
    expect(result.fallback?.options[0].name).toBe('Clínica Norte');
    expect(result.droneId).toBeNull();
    // Solo sugiere: la otra central autoriza y reserva su dron.
    expect(spare.status).toBe(DroneStatus.AVAILABLE);
    expect(grounded.status).toBe(DroneStatus.MAINTENANCE);
    expect(routes.saveOutbound).not.toHaveBeenCalled();
    expect(notifications.queueChanged).toHaveBeenCalledWith(
      OTHER_HUB_ID,
      order.id,
    );
  });

  it('lets the new hub authorize a reassigned order and keeps where it came from', async () => {
    const reassigned = received({
      status: OrderStatus.REASSIGNED,
      originHubId: HUB_ID,
      reassignedFromHubId: OTHER_HUB_ID,
      fallbackKind: FallbackKind.HUB,
      fallbackReason: 'Ningún dron de la central podía salir.',
    });
    const { service } = build({ order: reassigned });
    const result = await service.authorize(dispatcher(), reassigned.id, {});
    expect(result.status).toBe(OrderStatus.PENDING_LOAD);
    expect(result.droneId).toBe(DRONE_ID);
    expect(result.fallback).toBeNull();
    expect(result.reassignedFromHubId).toBe(OTHER_HUB_ID);
  });

  it('does not reassign twice: a reassigned order with no drone goes conventional', async () => {
    const third = hub({
      id: '66666666-6666-4666-8666-666666666666',
      name: 'Puesto Sur',
      latitude: 10.459,
      longitude: -73.25,
    });
    const reassigned = received({
      status: OrderStatus.REASSIGNED,
      originHubId: HUB_ID,
      reassignedFromHubId: OTHER_HUB_ID,
      fallbackKind: FallbackKind.HUB,
    });
    const { service } = build({
      order: reassigned,
      drones: [drone({ status: DroneStatus.MAINTENANCE })],
      hubs: [hub(), otherHub(), third],
      lotsByHub: { [third.id]: lot() },
      dronesByHub: { [third.id]: [drone({ id: HELD_ID, hubId: third.id })] },
    });
    const result = await service.authorize(dispatcher(), reassigned.id, {});
    expect(result.status).toBe(OrderStatus.REASSIGNED);
    expect(result.fallback?.kind).toBe(FallbackKind.CONVENTIONAL);
    expect(result.originHubId).toBe(HUB_ID);
    expect(result.reassignedFromHubId).toBe(OTHER_HUB_ID);
    expect(result.fallback?.options.map((option) => option.name)).toEqual([
      'Puesto Sur',
      'Hospital Rosario',
    ]);
  });

  it('a hub transfer never falls back to the hub that asked for it', async () => {
    const transfer = received({
      destinationKind: DestinationKind.HUB,
      destinationHubId: OTHER_HUB_ID,
      requesterId: null,
      originHubId: HUB_ID,
      latitude: 10.48,
      longitude: -73.24,
    });
    const { service } = build({
      order: transfer,
      drones: [drone({ status: DroneStatus.OUT_OF_SERVICE })],
      hubs: [hub(), otherHub()],
      lotsByHub: { [OTHER_HUB_ID]: lot() },
      dronesByHub: { [OTHER_HUB_ID]: [drone({ id: HELD_ID })] },
    });
    const result = await service.authorize(dispatcher(), transfer.id, {});
    expect(result.fallback?.kind).toBe(FallbackKind.CONVENTIONAL);
    expect(result.fallback?.options.map((option) => option.hubId)).toEqual([
      HUB_ID,
    ]);
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
    // Todavía no despegó: no hay regreso planificado.
    expect(rows[0].assignment?.returnRoute).toBeNull();
    expect(orders.find).toHaveBeenCalledWith({
      where: { originHubId: HUB_ID, status: OrderStatus.PENDING_LOAD },
      order: { updatedAt: 'DESC' },
    });
    expect(rows[0].assignment?.identifier).toBe('WC-01');
    expect(rows[0].assignment?.route.altitudeM).toBe(100);
  });
});

describe('DecisionService.listInFlight', () => {
  it('lists the flights in the air, awaiting delivery or returning of the dispatcher hub', async () => {
    const flying = received({
      status: OrderStatus.IN_FLIGHT,
      originHubId: HUB_ID,
      droneId: DRONE_ID,
    });
    const orders = { find: jest.fn().mockResolvedValue([flying]) };
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
    routes.findOutboundMany.mockResolvedValue(new Map([[flying.id, corridor]]));
    const back: PlannedCorridor = {
      altitudeM: 100,
      distanceKm: 4.9,
      coordinates: [
        [-73.25, 10.46],
        [-73.255, 10.465],
        [-73.26, 10.47],
      ],
    };
    routes.findReturnMany.mockResolvedValue(new Map([[flying.id, back]]));
    const rows = await service.listInFlight(dispatcher());
    expect(rows[0].assignment?.returnRoute).toEqual(back);
    expect(routes.findReturnMany).toHaveBeenCalledWith([flying.id]);
    expect(orders.find).toHaveBeenCalledWith({
      where: {
        originHubId: HUB_ID,
        status: In([
          OrderStatus.IN_FLIGHT,
          OrderStatus.AWAITING_DELIVERY,
          OrderStatus.RETURNING,
        ]),
      },
      order: { updatedAt: 'DESC' },
    });
    expect(rows[0].status).toBe(OrderStatus.IN_FLIGHT);
    expect(rows[0].assignment?.identifier).toBe('WC-01');
  });
});

describe('DecisionService.confirmLoad', () => {
  it('marks the load, discounts the reserved lot and starts the clock without taking off', async () => {
    const order = received({
      status: OrderStatus.PENDING_LOAD,
      originHubId: HUB_ID,
      droneId: DRONE_ID,
      inventoryItemId: LOT_ID,
      quantity: 3,
      loadConfirmedAt: null,
    });
    const { service, flights, routes, currentLot, manager } = build({ order });
    routes.findOutboundMany.mockResolvedValue(new Map([[order.id, corridor]]));
    const result = await service.confirmLoad(dispatcher(), order.id);
    expect(order.loadConfirmedAt).toBeInstanceOf(Date);
    expect(order.status).toBe(OrderStatus.PENDING_LOAD);
    expect(currentLot?.quantity).toBe(5);
    expect(manager.save).toHaveBeenCalledWith(currentLot);
    expect(result.dispatchedLot).toBe('L-1');
    expect(result.dispatchedLotExpiresOn).toBe('2027-01-01');
    expect(flights.start).toHaveBeenCalledWith(order.id);
    expect(result.status).toBe(OrderStatus.PENDING_LOAD);
  });

  it('does not take off when the reserved lot no longer has the units', async () => {
    const order = received({
      status: OrderStatus.PENDING_LOAD,
      originHubId: HUB_ID,
      droneId: DRONE_ID,
      inventoryItemId: LOT_ID,
      quantity: 9,
    });
    const { service, flights, routes, currentLot } = build({ order });
    routes.findOutboundMany.mockResolvedValue(new Map([[order.id, corridor]]));
    await expect(service.confirmLoad(dispatcher(), order.id)).rejects.toThrow(
      new BadRequestException(LOT_NOT_AVAILABLE),
    );
    expect(currentLot?.quantity).toBe(8);
    expect(order.loadConfirmedAt).toBeNull();
    expect(flights.start).not.toHaveBeenCalled();
  });

  it('rejects a dispatcher from another hub', async () => {
    const order = received({
      status: OrderStatus.PENDING_LOAD,
      originHubId: OTHER_HUB_ID,
      droneId: DRONE_ID,
    });
    const { service, flights } = build({ order });
    await expect(service.confirmLoad(dispatcher(), order.id)).rejects.toThrow(
      NOT_THE_LOADING_HUB,
    );
    expect(flights.start).not.toHaveBeenCalled();
  });

  it('rejects an order that is not pending load', async () => {
    const { service, flights } = build();
    await expect(
      service.confirmLoad(dispatcher(), ORDER_ID),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(service.confirmLoad(dispatcher(), ORDER_ID)).rejects.toThrow(
      ONLY_PENDING_LOAD_IS_CONFIRMED,
    );
    expect(flights.start).not.toHaveBeenCalled();
  });

  it('does not confirm when telemetry is down', async () => {
    const order = received({
      status: OrderStatus.PENDING_LOAD,
      originHubId: HUB_ID,
      droneId: DRONE_ID,
    });
    const { service, flights } = build({ order });
    flights.isReady.mockReturnValue(false);
    await expect(
      service.confirmLoad(dispatcher(), order.id),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(order.loadConfirmedAt).toBeNull();
    expect(flights.start).not.toHaveBeenCalled();
  });
});

describe('DecisionService scheduled fallback', () => {
  // 10:00 en Colombia: el siguiente intento cae el mismo día.
  const morning = new Date('2026-10-16T15:00:00.000Z');
  // 23:50 en Colombia: el siguiente intento ya sería mañana.
  const lateNight = new Date('2026-10-17T04:50:00.000Z');

  afterEach(() => {
    jest.useRealTimers();
  });

  function scheduledToday(now: Date, overrides: Partial<Order> = {}) {
    return received({
      missionType: MissionType.SCHEDULED,
      priority: OrderPriority.NORMAL,
      scheduledFor: todayInColombia(now),
      ...overrides,
    });
  }

  it('keeps a scheduled order received and retries in 15 minutes', async () => {
    jest.useFakeTimers({
      now: morning,
      doNotFake: ['nextTick', 'setImmediate'],
    });
    const order = scheduledToday(morning, {
      saleType: SaleType.PRESCRIPTION,
    });
    const { service, notifications } = build({
      order,
      drones: [drone({ status: DroneStatus.MAINTENANCE })],
    });
    const result = await service.authorize(dispatcher(), order.id, {
      prescriptionVerified: true,
    });
    expect(result.status).toBe(OrderStatus.RECEIVED);
    expect(result.originHubId).toBe(HUB_ID);
    expect(result.fallback?.kind).toBe(FallbackKind.RETRY);
    expect(order.retryAfter).toEqual(
      new Date(morning.getTime() + 15 * 60 * 1000),
    );
    expect(order.prescriptionVerifiedAt).toEqual(morning);
    expect(notifications.statusChanged).not.toHaveBeenCalled();
  });

  it('at the end of the day a scheduled order looks for another hub', async () => {
    jest.useFakeTimers({
      now: lateNight,
      doNotFake: ['nextTick', 'setImmediate'],
    });
    const order = scheduledToday(lateNight);
    const { service } = build({
      order,
      drones: [drone({ status: DroneStatus.MAINTENANCE })],
      hubs: [hub(), otherHub()],
      lotsByHub: { [OTHER_HUB_ID]: lot() },
      dronesByHub: { [OTHER_HUB_ID]: [drone({ id: HELD_ID })] },
    });
    const result = await service.authorize(dispatcher(), order.id, {});
    expect(result.status).toBe(OrderStatus.REASSIGNED);
    expect(result.fallback?.kind).toBe(FallbackKind.HUB);
    expect(result.originHubId).toBe(OTHER_HUB_ID);
    expect(order.retryAfter).toBeNull();
  });

  it('a due retry takes the drone that became free without asking for the formula again', async () => {
    const order = scheduledToday(morning, {
      saleType: SaleType.PRESCRIPTION,
      originHubId: HUB_ID,
      fallbackKind: FallbackKind.RETRY,
      fallbackReason: 'Ningún dron está libre.',
      retryAfter: new Date(morning.getTime() - 1000),
      prescriptionVerifiedAt: new Date(morning.getTime() - 900000),
    });
    const { service, notifications } = build({ order });
    const result = await service.retryScheduled(order.id, morning);
    expect(result?.status).toBe(OrderStatus.PENDING_LOAD);
    expect(result?.droneId).toBe(DRONE_ID);
    expect(result?.fallback).toBeNull();
    expect(order.retryAfter).toBeNull();
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      order.id,
      OrderStatus.PENDING_LOAD,
    );
    expect(notifications.queueChanged).toHaveBeenCalledWith(HUB_ID, order.id);
  });

  it('a retry that is not due yet does nothing', async () => {
    const order = scheduledToday(morning, {
      originHubId: HUB_ID,
      fallbackKind: FallbackKind.RETRY,
      retryAfter: new Date(morning.getTime() + 60000),
    });
    const { service, manager } = build({ order });
    await expect(service.retryScheduled(order.id, morning)).resolves.toBeNull();
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('a retry whose lot ran out searches another hub instead of failing', async () => {
    const order = scheduledToday(morning, {
      originHubId: HUB_ID,
      fallbackKind: FallbackKind.RETRY,
      retryAfter: new Date(morning.getTime() - 1000),
    });
    const { service } = build({
      order,
      currentLot: null,
      hubs: [hub(), otherHub()],
    });
    const result = await service.retryScheduled(order.id, morning);
    // Sin lote propio ni otra central: sigue esperando hasta su día.
    expect(result?.fallback?.kind).toBe(FallbackKind.RETRY);
    expect(order.retryAfter?.getTime()).toBeGreaterThan(morning.getTime());
  });
});
