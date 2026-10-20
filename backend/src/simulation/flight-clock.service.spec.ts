import { DroneStatus } from '../common/enums/drone-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { Hub } from '../hubs/hub.entity';
import { PlannedCorridor } from '../routing/routing.rules';
import { FlightClockService } from './flight-clock.service';
import { FlightPhase, LANDING_MS, returnProgress } from './simulation.rules';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const LANDED_AT = new Date('2026-10-19T15:00:00.000Z');
const AFTER_WAIT = new Date('2026-10-19T15:05:00.000Z');

const outbound: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 5,
  coordinates: [
    [-73.26, 10.47],
    [-73.25, 10.46],
  ],
};
const planned: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 5.5,
  coordinates: [
    [-73.25, 10.46],
    [-73.255, 10.49],
    [-73.26, 10.47],
  ],
};

function order(status: OrderStatus) {
  return {
    id: ORDER_ID,
    status,
    droneId: DRONE_ID,
    originHubId: HUB_ID,
    loadConfirmedAt: new Date('2026-10-19T14:00:00.000Z'),
    quantity: 1,
    requiresColdChain: false,
    latitude: 10.46,
    longitude: -73.25,
  };
}

function build(
  options: { affected?: number; planResult?: PlannedCorridor | null } = {},
) {
  const manager = {
    findOne: jest.fn((entity: unknown) =>
      Promise.resolve(
        entity === Hub
          ? { id: HUB_ID, latitude: 10.47, longitude: -73.26 }
          : null,
      ),
    ),
  };
  const orders = {
    update: jest.fn().mockResolvedValue({ affected: options.affected ?? 1 }),
    findOne: jest.fn().mockResolvedValue(order(OrderStatus.RETURNING)),
    manager,
  };
  const drones = {
    findOne: jest.fn().mockResolvedValue({
      id: DRONE_ID,
      identifier: 'WG-198-001',
      droneModel: { maxSpeedKmh: 150, maxRangeKm: 110 },
    }),
    update: jest.fn().mockResolvedValue(undefined),
  };
  const routes = {
    findReturn: jest.fn().mockResolvedValue(null),
    findOutboundMany: jest
      .fn()
      .mockResolvedValue(new Map([[ORDER_ID, outbound]])),
    loadPolygons: jest.fn().mockResolvedValue([]),
    plan: jest
      .fn()
      .mockReturnValue(
        options.planResult === undefined ? planned : options.planResult,
      ),
    saveReturn: jest.fn().mockResolvedValue(undefined),
  };
  const telemetry = {
    readFlight: jest.fn().mockResolvedValue(null),
    publishFlight: jest.fn().mockResolvedValue(undefined),
  };
  const notifications = {
    statusChanged: jest.fn().mockResolvedValue(undefined),
    alert: jest.fn().mockResolvedValue(undefined),
  };
  const service = new FlightClockService(
    orders as never,
    drones as never,
    { findOne: jest.fn(), save: jest.fn() } as never,
    routes as never,
    telemetry as never,
    notifications as never,
  );
  service['waiting'].set(ORDER_ID, LANDED_AT);
  return { service, orders, drones, routes, telemetry, notifications };
}

describe('FlightClockService expireDeliveryWaits', () => {
  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  it('CH-07 pasa a returning y avisa cuando vence la espera', async () => {
    const { service, orders, notifications } = build();

    await service.expireDeliveryWaits(AFTER_WAIT);

    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID, status: OrderStatus.AWAITING_DELIVERY },
      { status: OrderStatus.RETURNING },
    );
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      ORDER_ID,
      OrderStatus.RETURNING,
    );
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });

  it('no hace nada mientras la espera sigue vigente', async () => {
    const { service, orders, notifications } = build();

    await service.expireDeliveryWaits(new Date('2026-10-19T15:04:59.000Z'));

    expect(orders.update).not.toHaveBeenCalled();
    expect(notifications.statusChanged).not.toHaveBeenCalled();
    expect(service['waiting'].has(ORDER_ID)).toBe(true);
  });

  it('respeta DELIVERY_WAIT_MS', async () => {
    process.env.DELIVERY_WAIT_MS = '10000';
    const { service, orders } = build();

    await service.expireDeliveryWaits(new Date('2026-10-19T15:00:10.000Z'));

    expect(orders.update).toHaveBeenCalled();
  });

  it('no avisa ni inicia el regreso si el pedido ya se entregó', async () => {
    const { service, notifications, routes } = build({ affected: 0 });

    await service.expireDeliveryWaits(AFTER_WAIT);

    expect(notifications.statusChanged).not.toHaveBeenCalled();
    expect(routes.saveReturn).not.toHaveBeenCalled();
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });
});

describe('FlightClockService regreso', () => {
  it('al vencer la espera planifica y guarda la ruta de regreso a la central', async () => {
    const { service, routes } = build();

    await service.expireDeliveryWaits(AFTER_WAIT);

    expect(routes.plan).toHaveBeenCalledWith(
      { longitude: -73.25, latitude: 10.46 },
      { longitude: -73.26, latitude: 10.47 },
      [],
    );
    expect(routes.saveReturn).toHaveBeenCalledWith(
      ORDER_ID,
      planned,
      expect.anything(),
    );
    const session = service['active'].get(ORDER_ID);
    expect(session?.leg).toBe(RouteLeg.RETURN);
    expect(session?.corridor).toEqual(planned);
    expect(session?.progress.orderStatus).toBe(OrderStatus.RETURNING);
  });

  it('si una geovalla bloquea el regreso, vuelve por donde vino', async () => {
    const { service, routes } = build({ planResult: null });

    await service.expireDeliveryWaits(AFTER_WAIT);

    const [, saved] = routes.saveReturn.mock.calls[0] as [
      string,
      PlannedCorridor,
    ];
    expect(saved.coordinates).toEqual([...outbound.coordinates].reverse());
  });

  it('reutiliza la ruta de regreso ya guardada', async () => {
    const { service, routes } = build();
    routes.findReturn.mockResolvedValue(planned);

    await service.expireDeliveryWaits(AFTER_WAIT);

    expect(routes.plan).not.toHaveBeenCalled();
    expect(routes.saveReturn).not.toHaveBeenCalled();
    expect(service['active'].get(ORDER_ID)?.corridor).toEqual(planned);
  });

  it('al aterrizar de regreso el pedido queda returned y el dron available', async () => {
    const { service, orders, drones, notifications } = build();
    await service.expireDeliveryWaits(AFTER_WAIT);
    const session = service['active'].get(ORDER_ID)!;
    session.progress = {
      ...returnProgress(null),
      phase: FlightPhase.LANDING,
      phaseElapsedMs: LANDING_MS - 1,
    };

    await service['tick'](ORDER_ID);

    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID },
      { status: OrderStatus.RETURNED },
    );
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      ORDER_ID,
      OrderStatus.RETURNED,
    );
    expect(drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      { status: DroneStatus.AVAILABLE },
    );
    expect(service['active'].has(ORDER_ID)).toBe(false);
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });
});
