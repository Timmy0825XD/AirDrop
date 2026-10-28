import { ForbiddenException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Order } from '../orders/order.entity';
import { Mission } from '../simulation/mission.entity';
import { FlightPhase } from '../simulation/simulation.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { User } from '../users/user.entity';
import { Drone } from './drone.entity';
import { activeOrderByDrone } from './fleet-flights.rules';
import { FleetFlightsService } from './fleet-flights.service';

const HUB_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const IDLE_ID = '44444444-4444-4444-8444-444444444444';

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    droneId: DRONE_ID,
    status: OrderStatus.IN_FLIGHT,
    missionType: MissionType.EMERGENCY,
    requiresColdChain: true,
    coldChainAlertAt: null,
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
        batteryPercent: 64,
        temperatureC: 5.1,
        etaSeconds: 90,
      }),
    };
    const service = new FleetFlightsService(
      drones as unknown as Repository<Drone>,
      orders as unknown as Repository<Order>,
      missions as unknown as Repository<Mission>,
      telemetry as unknown as TelemetryPublisher,
    );
    return { service, drones, orders, telemetry };
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
  });
});
