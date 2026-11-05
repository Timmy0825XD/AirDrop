import { ForbiddenException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Order } from '../orders/order.entity';
import { RoutePlannerService } from '../routing/route-planner.service';
import { PlannedCorridor } from '../routing/routing.rules';
import { Mission } from '../simulation/mission.entity';
import { FlightPhase } from '../simulation/simulation.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import {
  activeOrderByDrone,
  presentOperatorFlight,
} from './fleet-flights.rules';
import { FleetFlightsService } from './fleet-flights.service';

const HUB_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const IDLE_ID = '44444444-4444-4444-8444-444444444444';
const ORDER_ID = '11111111-1111-4111-8111-111111111111';

const outboundRoute: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 2.4,
  coordinates: [
    [-73.2532, 10.4631],
    [-73.2401, 10.4802],
  ],
};
const returnRoute: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 2.4,
  coordinates: [
    [-73.2401, 10.4802],
    [-73.2532, 10.4631],
  ],
};

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    droneId: DRONE_ID,
    status: OrderStatus.IN_FLIGHT,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    destinationHubId: null,
    requiresColdChain: true,
    coldChainAlertAt: null,
    latitude: 10.48,
    longitude: -73.24,
    // Lo que el operador no debe ver nunca.
    medicationName: 'Insulina glargina',
    requesterId: '55555555-5555-4555-8555-555555555555',
    address: 'Calle 12 No. 4-50, Valledupar',
    prescriptionKey: 'prescriptions/clave.jpg',
    updatedAt: new Date('2026-10-28T15:00:00.000Z'),
    ...overrides,
  } as Order;
}

function drone(overrides: Partial<Drone> = {}): Drone {
  return {
    id: DRONE_ID,
    identifier: 'WG-198-001',
    hubId: HUB_A,
    status: DroneStatus.IN_MISSION,
    ...overrides,
  } as Drone;
}

function operator(hubIds = [HUB_A]): User {
  return {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.FLEET_OPERATOR,
    hubAssignments: hubIds.map((hubId) => ({ hubId })),
  } as unknown as User;
}

describe('activeOrderByDrone', () => {
  it('un pedido entregado viejo no tapa el pedido vivo del dron', () => {
    const old = order({
      id: 'old',
      status: OrderStatus.DELIVERED,
      updatedAt: new Date('2026-10-28T16:00:00.000Z'),
    });
    const live = order({ id: 'live', status: OrderStatus.PENDING_LOAD });
    expect(activeOrderByDrone([old, live], [DRONE_ID]).get(DRONE_ID)?.id).toBe(
      'live',
    );
  });

  it('entre entregados gana el más reciente: es el regreso vacío', () => {
    const before = order({ id: 'before', status: OrderStatus.DELIVERED });
    const latest = order({
      id: 'latest',
      status: OrderStatus.DELIVERED,
      updatedAt: new Date('2026-10-28T16:00:00.000Z'),
    });
    expect(
      activeOrderByDrone([latest, before], [DRONE_ID]).get(DRONE_ID)?.id,
    ).toBe('latest');
  });

  it('ignora los drones que no están en misión', () => {
    expect(activeOrderByDrone([order()], []).size).toBe(0);
  });
});

describe('FleetFlightsService', () => {
  function build(state: { drones?: Drone[]; orders?: Order[] } = {}) {
    const drones = { find: jest.fn().mockResolvedValue(state.drones ?? []) };
    const orders = {
      find: jest.fn().mockResolvedValue(state.orders ?? [order()]),
    };
    const missions = {
      find: jest.fn().mockResolvedValue([
        {
          orderId: '11111111-1111-4111-8111-111111111111',
          batteryAlert: true,
          failureAlert: false,
        },
      ]),
    };
    const telemetry = {
      readFlight: jest.fn().mockResolvedValue({
        phase: FlightPhase.CRUISE,
        leg: 'outbound',
        latitude: 10.46,
        longitude: -73.25,
        altitudeM: 100,
        speedKmh: 98,
        batteryPercent: 64,
        payloadKg: 1.2,
        temperatureC: 5.1,
        latencyMs: 42,
        etaSeconds: 90,
      }),
    };
    const routes = {
      findOutboundMany: jest
        .fn()
        .mockResolvedValue(new Map([[ORDER_ID, outboundRoute]])),
      findReturnMany: jest.fn().mockResolvedValue(new Map()),
    };
    const service = new FleetFlightsService(
      drones as unknown as Repository<Drone>,
      orders as unknown as Repository<Order>,
      missions as unknown as Repository<Mission>,
      telemetry as unknown as TelemetryPublisher,
      routes as unknown as RoutePlannerService,
    );
    return { service, drones, orders, telemetry, routes };
  }

  it('cada dron en misión trae su pedido y su fase; el libre, null', async () => {
    const { service } = build();
    const rows = await service.withActiveOrders([
      { id: DRONE_ID, status: DroneStatus.IN_MISSION },
      { id: IDLE_ID, status: DroneStatus.AVAILABLE },
    ]);
    expect(rows).toEqual([
      {
        id: DRONE_ID,
        status: DroneStatus.IN_MISSION,
        activeOrderId: '11111111-1111-4111-8111-111111111111',
        phase: FlightPhase.CRUISE,
      },
      {
        id: IDLE_ID,
        status: DroneStatus.AVAILABLE,
        activeOrderId: null,
        phase: null,
      },
    ]);
  });

  it('sin drones en misión no consulta pedidos', async () => {
    const { service, orders } = build();
    await service.withActiveOrders([
      { id: IDLE_ID, status: DroneStatus.AVAILABLE },
    ]);
    expect(orders.find).not.toHaveBeenCalled();
  });

  it('lista los vuelos de las centrales del operador con sus alertas', async () => {
    const { service } = build({ drones: [drone()] });
    const flights = await service.listFlights(operator());
    expect(flights).toEqual([
      expect.objectContaining({
        droneId: DRONE_ID,
        identifier: 'WG-198-001',
        orderId: '11111111-1111-4111-8111-111111111111',
        orderStatus: OrderStatus.IN_FLIGHT,
        phase: FlightPhase.CRUISE,
        batteryPercent: 64,
        temperatureC: 5.1,
        alerts: { battery: true, failure: false, coldChain: false },
      }),
    ]);
  });

  it('cada vuelo trae el paquete de RU-18, la ruta y el punto de llegada', async () => {
    const { service } = build({ drones: [drone()] });
    const [flight] = await service.listFlights(operator());
    expect(flight).toMatchObject({
      altitudeM: 100,
      speedKmh: 98,
      batteryPercent: 64,
      payloadKg: 1.2,
      temperatureC: 5.1,
      latencyMs: 42,
      route: outboundRoute,
      returnRoute: null,
      destination: {
        kind: DestinationKind.PERSON,
        hubId: null,
        latitude: 10.4802,
        longitude: -73.2401,
      },
    });
  });

  it('no le manda al operador nada de quién recibe ni qué lleva', async () => {
    const { service } = build({ drones: [drone()] });
    const [flight] = await service.listFlights(operator());
    const json = JSON.stringify(flight);
    for (const leak of [
      'medicationName',
      'Insulina',
      'requesterId',
      'address',
      'Calle 12',
      'prescription',
    ]) {
      expect(json).not.toContain(leak);
    }
  });

  it('sin vuelos no busca rutas con una lista vacía de más', async () => {
    const { service, routes } = build({ drones: [] });
    expect(await service.listFlights(operator())).toEqual([]);
    expect(routes.findOutboundMany).toHaveBeenCalledWith([]);
  });

  it('no deja ver una central que no es del operador', async () => {
    const { service } = build();
    await expect(service.listFlights(operator(), HUB_B)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('sin Redis el vuelo sigue en la lista, sin fase ni posición', async () => {
    const { service, telemetry } = build({ drones: [drone()] });
    telemetry.readFlight.mockRejectedValue(new Error('Redis caído'));
    const [flight] = await service.listFlights(operator());
    expect(flight.orderId).toBe('11111111-1111-4111-8111-111111111111');
    expect(flight.phase).toBeNull();
    expect(flight.latitude).toBeNull();
    // La ruta no depende de Redis: sigue en el mapa.
    expect(flight.route).toEqual(outboundRoute);
  });
});

describe('presentOperatorFlight', () => {
  const noAlerts = { battery: false, failure: false };

  it('en el regreso trae las dos rutas', () => {
    const flight = presentOperatorFlight(drone(), order(), null, noAlerts, {
      route: outboundRoute,
      returnRoute,
    });
    expect(flight.returnRoute).toEqual(returnRoute);
  });

  it('un traslado nombra la central de destino por su id', () => {
    const transfer = order({
      destinationKind: DestinationKind.HUB,
      destinationHubId: HUB_B,
    });
    const flight = presentOperatorFlight(drone(), transfer, null, noAlerts, {
      route: outboundRoute,
      returnRoute: null,
    });
    expect(flight.destination).toEqual({
      kind: DestinationKind.HUB,
      hubId: HUB_B,
      latitude: 10.4802,
      longitude: -73.2401,
    });
  });

  it('sin corredor todavía, el destino es el punto del pedido', () => {
    const flight = presentOperatorFlight(drone(), order(), null, noAlerts, {
      route: null,
      returnRoute: null,
    });
    expect(flight.destination).toMatchObject({
      latitude: 10.48,
      longitude: -73.24,
    });
  });

  it('sin corredor ni punto, no inventa un destino', () => {
    const lost = order({ latitude: null, longitude: null });
    const flight = presentOperatorFlight(drone(), lost, null, noAlerts, {
      route: null,
      returnRoute: null,
    });
    expect(flight.destination).toBeNull();
  });
});
