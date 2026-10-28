import { DroneStatus } from '../common/enums/drone-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { Hub } from '../hubs/hub.entity';
import { PlannedCorridor } from '../routing/routing.rules';
import { FlightClockService } from './flight-clock.service';
import { IsNull } from 'typeorm';
import {
  COLD_CHAIN_RANGE_C,
  FlightPhase,
  LANDING_MS,
  LiveFlight,
  initialProgress,
  returnProgress,
} from './simulation.rules';

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
  const missions = {
    findOne: jest.fn(),
    save: jest.fn(),
    update: jest.fn().mockResolvedValue(undefined),
  };
  const service = new FlightClockService(
    orders as never,
    drones as never,
    missions as never,
    routes as never,
    telemetry as never,
    notifications as never,
  );
  service['waiting'].set(ORDER_ID, LANDED_AT);
  return {
    service,
    orders,
    drones,
    missions,
    routes,
    telemetry,
    notifications,
  };
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
    const { service, orders, drones, missions, notifications } = build();
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
    expect(missions.update).toHaveBeenCalledWith(
      { orderId: ORDER_ID },
      { returnedAt: expect.any(Date) as Date },
    );
    expect(service['active'].has(ORDER_ID)).toBe(false);
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });
});

describe('FlightClockService regreso tras la entrega', () => {
  function buildDelivered() {
    const built = build();
    built.orders.findOne.mockResolvedValue(order(OrderStatus.DELIVERED));
    return built;
  }

  it('el dron vuelve a su central y el pedido sigue entregado', async () => {
    const { service, orders, routes } = buildDelivered();

    await service.startReturn(ORDER_ID);

    const session = service['active'].get(ORDER_ID)!;
    expect(session.leg).toBe(RouteLeg.RETURN);
    expect(session.keepStatus).toBe(true);
    expect(session.progress.orderStatus).toBe(OrderStatus.DELIVERED);
    expect(routes.saveReturn).toHaveBeenCalled();
    expect(orders.update).not.toHaveBeenCalled();
  });

  it('al aterrizar libera el dron sin tocar el estado del pedido', async () => {
    const { service, orders, drones, notifications, telemetry } =
      buildDelivered();
    await service.startReturn(ORDER_ID);
    const session = service['active'].get(ORDER_ID)!;
    session.progress = {
      ...returnProgress(null),
      orderStatus: OrderStatus.DELIVERED,
      phase: FlightPhase.LANDING,
      phaseElapsedMs: LANDING_MS - 1,
    };

    await service['tick'](ORDER_ID);

    expect(drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      { status: DroneStatus.AVAILABLE },
    );
    expect(orders.update).not.toHaveBeenCalled();
    expect(notifications.statusChanged).not.toHaveBeenCalled();
    const [published] = telemetry.publishFlight.mock.calls.at(-1) as [
      { status: OrderStatus; leg: RouteLeg },
    ];
    expect(published.status).toBe(OrderStatus.DELIVERED);
    expect(published.leg).toBe(RouteLeg.RETURN);
    expect(service['active'].has(ORDER_ID)).toBe(false);
  });
});

describe('FlightClockService cadena de frío (RF-17)', () => {
  const previousRate = process.env.COLD_CHAIN_FAILURE_RATE;

  afterEach(() => {
    process.env.COLD_CHAIN_FAILURE_RATE = previousRate;
  });

  function buildCold(rate: string) {
    process.env.COLD_CHAIN_FAILURE_RATE = rate;
    const built = build();
    built.service['waiting'].clear();
    built.service['random'] = () => 0;
    Object.assign(built.service, {
      missions: {
        findOne: jest.fn().mockResolvedValue(null),
        create: jest.fn((value: unknown) => value),
        save: jest.fn((value: unknown) => Promise.resolve(value)),
      },
    });
    built.orders.findOne.mockResolvedValue({
      ...order(OrderStatus.PENDING_LOAD),
      requiresColdChain: true,
    });
    return built;
  }

  function published(telemetry: { publishFlight: jest.Mock }) {
    return telemetry.publishFlight.mock.calls.map(
      ([flight]) => flight as LiveFlight,
    );
  }

  it('con falla, alerta una sola vez y marca el pedido', async () => {
    const { service, orders, notifications, telemetry } = buildCold('1');
    await service['activate'](ORDER_ID);
    expect(
      service['active'].get(ORDER_ID)?.progress.coldChainExcursionAtMs,
    ).toBe(0);

    await service['tick'](ORDER_ID);
    await service['tick'](ORDER_ID);

    const coldAlerts = notifications.alert.mock.calls.filter(
      ([, , kind]) => kind === 'cold_chain',
    );
    expect(coldAlerts).toHaveLength(1);
    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID, coldChainAlertAt: IsNull() },
      { coldChainAlertAt: expect.any(Date) as Date },
    );
    expect(published(telemetry)[0].temperatureC).toBeGreaterThan(
      COLD_CHAIN_RANGE_C.max,
    );
  });

  it('sin falla, la carga viaja en rango y no hay alerta', async () => {
    const { service, orders, notifications, telemetry } = buildCold('0');
    await service['activate'](ORDER_ID);
    await service['tick'](ORDER_ID);

    const [flight] = published(telemetry);
    expect(flight.temperatureC).toBeGreaterThanOrEqual(COLD_CHAIN_RANGE_C.min);
    expect(flight.temperatureC).toBeLessThanOrEqual(COLD_CHAIN_RANGE_C.max);
    expect(notifications.alert).not.toHaveBeenCalled();
    expect(orders.update).not.toHaveBeenCalledWith(
      expect.objectContaining({ coldChainAlertAt: IsNull() }),
      expect.anything(),
    );
  });

  it('en la espera sigue midiendo y alerta una vez', async () => {
    const { service, orders, notifications, telemetry } = buildCold('1');
    let stored: LiveFlight = {
      orderId: ORDER_ID,
      droneId: DRONE_ID,
      identifier: 'WG-198-001',
      latitude: 10.46,
      longitude: -73.25,
      altitudeM: 0,
      speedKmh: 0,
      batteryPercent: 80,
      payloadKg: 0.5,
      temperatureC: 5,
      latencyMs: 40,
      phase: FlightPhase.LANDED,
      leg: RouteLeg.OUTBOUND,
      status: OrderStatus.AWAITING_DELIVERY,
      etaSeconds: null,
      progress: {
        ...initialProgress(),
        phase: FlightPhase.LANDED,
        coldChainExcursionAtMs: 0,
        orderStatus: OrderStatus.AWAITING_DELIVERY,
      },
    };
    telemetry.readFlight.mockImplementation(() => Promise.resolve(stored));
    telemetry.publishFlight.mockImplementation((flight: LiveFlight) => {
      stored = flight;
      return Promise.resolve();
    });
    service['waiting'].set(ORDER_ID, LANDED_AT);
    service['coldWaits'].set(ORDER_ID, {
      droneId: DRONE_ID,
      loadConfirmedAt: order(OrderStatus.AWAITING_DELIVERY).loadConfirmedAt,
    });

    await service['watchColdWaits'](AFTER_WAIT);
    await service['watchColdWaits'](AFTER_WAIT);

    expect(stored.temperatureC).toBeGreaterThan(COLD_CHAIN_RANGE_C.max);
    expect(stored.progress.coldChainAlertSent).toBe(true);
    expect(notifications.alert).toHaveBeenCalledTimes(1);
    expect(notifications.alert).toHaveBeenCalledWith(
      ORDER_ID,
      DRONE_ID,
      'cold_chain',
    );
    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID, coldChainAlertAt: IsNull() },
      { coldChainAlertAt: AFTER_WAIT },
    );
  });

  it('deja de medir la espera cuando el dron ya va de regreso', async () => {
    const { service, telemetry } = buildCold('1');
    service['waiting'].set(ORDER_ID, LANDED_AT);
    service['coldWaits'].set(ORDER_ID, {
      droneId: DRONE_ID,
      loadConfirmedAt: LANDED_AT,
    });
    service['active'].set(ORDER_ID, {} as never);

    await service['watchColdWaits'](AFTER_WAIT);

    expect(telemetry.readFlight).not.toHaveBeenCalled();
    expect(service['coldWaits'].has(ORDER_ID)).toBe(false);
  });

  it('tras la entrega el dron vuelve vacío: no publica temperatura', async () => {
    const { service, orders, telemetry, notifications } = buildCold('1');
    orders.findOne.mockResolvedValue({
      ...order(OrderStatus.DELIVERED),
      requiresColdChain: true,
    });
    await service.startReturn(ORDER_ID);
    await service['tick'](ORDER_ID);

    expect(published(telemetry).at(-1)?.temperatureC).toBeNull();
    expect(notifications.alert).not.toHaveBeenCalled();
  });
});

describe('FlightClockService minuto de retiro tras la entrega', () => {
  const DELIVERED_AT = new Date('2026-10-19T15:02:00.000Z');
  const previousPickup = process.env.PICKUP_WAIT_MS;

  afterEach(() => {
    process.env.PICKUP_WAIT_MS = previousPickup;
  });

  function buildDelivered() {
    const built = build();
    built.orders.findOne.mockResolvedValue(order(OrderStatus.DELIVERED));
    built.telemetry.readFlight.mockResolvedValue({
      orderId: ORDER_ID,
      phase: FlightPhase.LANDED,
      status: OrderStatus.AWAITING_DELIVERY,
      speedKmh: 0,
      etaSeconds: null,
      temperatureC: 5,
      progress: initialProgress(),
    });
    return built;
  }

  it('publica la fase unloading y deja de esperar el código', async () => {
    const { service, telemetry } = buildDelivered();
    service['coldWaits'].set(ORDER_ID, {
      droneId: DRONE_ID,
      loadConfirmedAt: LANDED_AT,
    });

    await service.schedulePickup(ORDER_ID, DELIVERED_AT);

    expect(service['waiting'].has(ORDER_ID)).toBe(false);
    expect(service['coldWaits'].has(ORDER_ID)).toBe(false);
    const [flight] = telemetry.publishFlight.mock.calls.at(-1) as [LiveFlight];
    expect(flight.phase).toBe(FlightPhase.UNLOADING);
    expect(flight.status).toBe(OrderStatus.DELIVERED);
    expect(flight.temperatureC).toBeNull();
  });

  it('despega de regreso cuando pasa el minuto, no antes', async () => {
    const { service } = buildDelivered();
    await service.schedulePickup(ORDER_ID, DELIVERED_AT);

    await service['releasePickups'](new Date(DELIVERED_AT.getTime() + 59_000));
    expect(service['active'].has(ORDER_ID)).toBe(false);

    await service['releasePickups'](new Date(DELIVERED_AT.getTime() + 60_000));
    const session = service['active'].get(ORDER_ID);
    expect(session?.leg).toBe(RouteLeg.RETURN);
    expect(session?.keepStatus).toBe(true);
    expect(service['pickups'].has(ORDER_ID)).toBe(false);
  });

  it('respeta PICKUP_WAIT_MS', async () => {
    process.env.PICKUP_WAIT_MS = '5000';
    const { service } = buildDelivered();
    await service.schedulePickup(ORDER_ID, DELIVERED_AT);
    expect(service['pickups'].get(ORDER_ID)).toEqual(
      new Date(DELIVERED_AT.getTime() + 5000),
    );
  });

  it('tras un reinicio termina el retiro desde la hora de la entrega', async () => {
    const { service, orders, routes } = buildDelivered();
    routes.findReturn.mockResolvedValue(null);
    Object.assign(orders.manager, {
      findOne: jest.fn().mockResolvedValue({ usedAt: DELIVERED_AT }),
    });

    await service['resumeDelivered'](ORDER_ID);

    expect(service['pickups'].get(ORDER_ID)).toEqual(
      new Date(DELIVERED_AT.getTime() + 60_000),
    );
    expect(service['active'].has(ORDER_ID)).toBe(false);
  });

  it('tras un reinicio, si el regreso ya había empezado, lo sigue', async () => {
    const { service, routes } = buildDelivered();
    routes.findReturn.mockResolvedValue(planned);

    await service['resumeDelivered'](ORDER_ID);

    expect(service['active'].get(ORDER_ID)?.leg).toBe(RouteLeg.RETURN);
    expect(service['pickups'].has(ORDER_ID)).toBe(false);
  });
});

describe('FlightClockService returnWithPackage', () => {
  it('pasa a returning, avisa y arranca el regreso con el paquete', async () => {
    const { service, orders, notifications } = build();
    await expect(service.returnWithPackage(ORDER_ID)).resolves.toBe(true);
    expect(orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID, status: OrderStatus.AWAITING_DELIVERY },
      { status: OrderStatus.RETURNING },
    );
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      ORDER_ID,
      OrderStatus.RETURNING,
    );
    expect(service['active'].get(ORDER_ID)?.keepStatus).toBe(false);
    expect(service['waiting'].has(ORDER_ID)).toBe(false);
  });

  it('si la base falla, el pedido sigue esperando para que lo venza el tick', async () => {
    const { service, orders } = build();
    orders.update.mockRejectedValueOnce(new Error('sin base'));
    await expect(service.returnWithPackage(ORDER_ID)).rejects.toThrow(
      'sin base',
    );
    expect(service['waiting'].has(ORDER_ID)).toBe(true);
  });
});
