import { ConfigService } from '@nestjs/config';
import { simClock } from '../common/clock/sim-clock';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PendingAlertsService } from './pending-alerts.service';
import { pendingAlertKinds } from './pending-alerts.rules';
import { TIMELINE_KEY, TIMELINE_MAX, TimelineEntry } from './timeline.rules';
import { TimelineService } from './timeline.service';

const NOW = new Date('2026-11-05T15:00:00.000Z');
const HUB = {
  id: 'hub-1',
  name: 'Clínica del Cesar',
  latitude: 10.47,
  longitude: -73.25,
};
const OTHER = {
  id: 'hub-2',
  name: 'Hospital de Aguachica',
  latitude: 8.3,
  longitude: -73.6,
};

function order(overrides: Record<string, unknown> = {}) {
  return {
    id: 'order-1',
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    medicationName: 'Insulina',
    status: OrderStatus.RECEIVED,
    fallbackKind: null,
    originHubId: HUB.id,
    destinationHubId: null,
    droneId: null,
    decisionTrace: null,
    ...overrides,
  };
}

function build(enabled = 'true', current = order()) {
  const handlers: Array<(event: unknown) => void> = [];
  const redis = {
    pushCapped: jest.fn().mockResolvedValue(undefined),
    readList: jest.fn().mockResolvedValue([]),
  };
  const publisher = {
    onEvent: jest.fn((handler: (event: unknown) => void) =>
      handlers.push(handler),
    ),
    publish: jest.fn().mockResolvedValue(undefined),
    readFlight: jest.fn().mockResolvedValue(null),
  };
  const orders = {
    findOne: jest.fn().mockImplementation(() => Promise.resolve(current)),
  };
  const hubs = {
    findOne: jest.fn(({ where }: { where: { id: string } }) =>
      Promise.resolve([HUB, OTHER].find((hub) => hub.id === where.id) ?? null),
    ),
  };
  const drones = {
    findOne: jest
      .fn()
      .mockResolvedValue({ id: 'drone-1', identifier: 'WC-03', hubId: HUB.id }),
  };
  const service = new TimelineService(
    { get: () => enabled } as unknown as ConfigService,
    redis as never,
    publisher as never,
    orders as never,
    hubs as never,
    drones as never,
  );
  return { service, redis, publisher, orders, handlers };
}

function pushed(redis: { pushCapped: jest.Mock }): TimelineEntry[] {
  return redis.pushCapped.mock.calls.map(
    ([, raw]) => JSON.parse(raw as string) as TimelineEntry,
  );
}

describe('TimelineService (RF-39)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('con la consola apagada no escucha nada', () => {
    const { service, publisher } = build('false');
    service.onModuleInit();
    expect(publisher.onEvent).not.toHaveBeenCalled();
  });

  it('guarda cada paso en Redis con tope, con la hora simulada, y lo publica al radar', async () => {
    simClock.change({ speed: 8 });
    jest.advanceTimersByTime(60_000);
    const { service, redis, publisher } = build();

    await service.handle({
      type: 'order-status',
      orderId: 'order-1',
      status: OrderStatus.RECEIVED,
    });

    expect(redis.pushCapped).toHaveBeenCalledWith(
      TIMELINE_KEY,
      expect.any(String),
      TIMELINE_MAX,
    );
    const [entry] = pushed(redis);
    expect(entry).toMatchObject({
      title: 'Urgencia a una persona recibida',
      at: new Date(NOW.getTime() + 8 * 60_000).toISOString(),
      latitude: HUB.latitude,
      source: 'system',
    });
    expect(publisher.publish).toHaveBeenCalledWith({ type: 'timeline', entry });
  });

  it('no cuenta dos veces el mismo estado del mismo pedido', async () => {
    const { service, redis } = build();
    const event = {
      type: 'order-status',
      orderId: 'order-1',
      status: OrderStatus.REASSIGNED,
    } as const;
    await service.handle(event);
    await service.handle(event);
    expect(redis.pushCapped).toHaveBeenCalledTimes(1);
  });

  it('cuenta la urgencia que entra a la cola de cada central, una vez por central', async () => {
    const stamp = '2026-11-06T15:00:00.000Z';
    // RU-10: sin central de origen, ofrecida a las dos.
    const { service, redis } = build(
      'true',
      order({
        originHubId: null,
        dispatchOffers: [HUB, OTHER].map((hub) => ({
          hubId: hub.id,
          name: hub.name,
          etaMs: 1,
          ready: true,
          offeredAt: stamp,
          declinedAt: null,
          declineReason: null,
        })),
      }),
    );
    await service.handle({
      type: 'queue-changed',
      hubId: HUB.id,
      orderId: 'order-1',
    });
    await service.handle({
      type: 'queue-changed',
      hubId: HUB.id,
      orderId: 'order-1',
    });
    await service.handle({
      type: 'queue-changed',
      hubId: OTHER.id,
      orderId: 'order-1',
    });
    expect(pushed(redis).map((entry) => entry.title)).toEqual([
      `Urgencia a una persona en la cola de ${HUB.name}`,
      `Urgencia a una persona en la cola de ${OTHER.name}`,
    ]);
  });

  it('no cuenta un cambio de cola que no es una urgencia esperando', async () => {
    const { service, redis } = build(
      'true',
      order({ status: OrderStatus.PENDING_LOAD }),
    );
    await service.handle({
      type: 'queue-changed',
      hubId: HUB.id,
      orderId: 'order-1',
    });
    const scheduled = build(
      'true',
      order({ missionType: MissionType.SCHEDULED }),
    );
    await scheduled.service.handle({
      type: 'queue-changed',
      hubId: HUB.id,
      orderId: 'order-1',
    });
    expect(redis.pushCapped).not.toHaveBeenCalled();
    expect(scheduled.redis.pushCapped).not.toHaveBeenCalled();
  });

  it('la cola de la que sale la urgencia (declinó o se quedó sin energía) no cuenta como entrar', async () => {
    const stamp = '2026-11-06T15:00:00.000Z';
    const { service, redis } = build(
      'true',
      order({
        originHubId: null,
        dispatchOffers: [
          {
            hubId: HUB.id,
            name: HUB.name,
            etaMs: 1,
            ready: true,
            offeredAt: stamp,
            declinedAt: stamp,
            declineReason: 'Central sin energía',
          },
          {
            hubId: OTHER.id,
            name: OTHER.name,
            etaMs: 2,
            ready: true,
            offeredAt: stamp,
            declinedAt: null,
            declineReason: null,
          },
        ],
      }),
    );
    await service.handle({
      type: 'queue-changed',
      hubId: HUB.id,
      orderId: 'order-1',
    });
    await service.handle({
      type: 'queue-changed',
      hubId: OTHER.id,
      orderId: 'order-1',
    });
    expect(pushed(redis).map((entry) => entry.title)).toEqual([
      `Urgencia a una persona en la cola de ${OTHER.name}`,
    ]);
  });

  it('cuenta la alerta donde va el dron', async () => {
    const { service, redis, publisher } = build();
    publisher.readFlight.mockResolvedValue({
      latitude: 10.2,
      longitude: -73.4,
    });
    await service.handle({
      type: 'alert',
      orderId: 'order-1',
      droneId: 'drone-1',
      kind: 'battery_critical',
      message: 'Batería crítica en el dron en vuelo.',
    });
    expect(pushed(redis)[0]).toMatchObject({
      kind: 'alert',
      title: 'Batería crítica en WC-03',
      latitude: 10.2,
      longitude: -73.4,
      hubId: HUB.id,
    });
  });

  it('cuenta los cambios del reloj como acción de la consola', async () => {
    const { service, redis } = build();
    await service.handle({
      type: 'clock',
      clock: { now: NOW.toISOString(), speed: 2, paused: false },
    });
    expect(pushed(redis)[0]).toMatchObject({
      title: 'Reloj a x2',
      source: 'console',
    });
  });

  it('la telemetría de cada tick no entra a la línea de tiempo', async () => {
    const { service, redis } = build();
    await service.handle({
      type: 'telemetry',
      orderId: 'order-1',
      flight: {} as never,
    });
    expect(redis.pushCapped).not.toHaveBeenCalled();
  });

  /** El último tick de un regreso: el dron ya está en tierra en su central. */
  const landedHome = (status: OrderStatus) =>
    ({
      type: 'telemetry',
      orderId: 'order-1',
      flight: {
        leg: 'return',
        phase: 'landed',
        status,
        latitude: HUB.latitude,
        longitude: HUB.longitude,
      },
    }) as never;

  it('cuenta, una sola vez, que el dron volvió vacío a su central tras entregar', async () => {
    const { service, redis } = build(
      'true',
      order({ status: OrderStatus.DELIVERED, droneId: 'drone-1' }),
    );
    await service.handle(landedHome(OrderStatus.DELIVERED));
    await service.handle(landedHome(OrderStatus.DELIVERED));
    expect(pushed(redis)).toHaveLength(1);
    expect(pushed(redis)[0]).toMatchObject({
      kind: 'flight',
      severity: 'success',
      title: `WC-03 volvió vacío a ${HUB.name}`,
      latitude: HUB.latitude,
    });
  });

  it('el regreso con el paquete no se cuenta dos veces: ya lo cuenta su estado', async () => {
    const { service, redis } = build(
      'true',
      order({ status: OrderStatus.RETURNED }),
    );
    await service.handle(landedHome(OrderStatus.RETURNED));
    expect(redis.pushCapped).not.toHaveBeenCalled();
  });

  it('lee las últimas entradas y salta las dañadas', async () => {
    const { service, redis } = build();
    redis.readList.mockResolvedValue([JSON.stringify({ id: 'a' }), '{roto']);
    await expect(service.recent(10)).resolves.toEqual([{ id: 'a' }]);
    expect(redis.readList).toHaveBeenCalledWith(TIMELINE_KEY, 10);
  });
});

describe('alertas pendientes (RF-39)', () => {
  const open = { batteryAlert: true, failureAlert: false, returnedAt: null };

  it('una alerta sigue abierta mientras el dron no vuelva a su central', () => {
    expect(
      pendingAlertKinds(open, {
        status: OrderStatus.IN_FLIGHT,
        coldChainAlertAt: NOW,
      }),
    ).toEqual(['battery_critical', 'cold_chain']);
    expect(
      pendingAlertKinds(open, {
        status: OrderStatus.DELIVERED,
        coldChainAlertAt: null,
      }),
    ).toEqual(['battery_critical']);
  });

  it('se resuelve cuando la misión cierra', () => {
    expect(
      pendingAlertKinds(
        { ...open, returnedAt: NOW },
        { status: OrderStatus.RETURNED, coldChainAlertAt: null },
      ),
    ).toEqual([]);
  });

  it('lista cada dron con alerta y su posición en vivo', async () => {
    const service = new PendingAlertsService(
      {
        find: jest
          .fn()
          .mockResolvedValue([
            { orderId: 'order-1', droneId: 'drone-1', ...open },
          ]),
      } as never,
      {
        find: jest.fn().mockResolvedValue([
          {
            id: 'order-1',
            status: OrderStatus.RETURNING,
            coldChainAlertAt: null,
          },
        ]),
      } as never,
      {
        find: jest
          .fn()
          .mockResolvedValue([
            { id: 'drone-1', identifier: 'WC-03', hubId: HUB.id },
          ]),
      } as never,
      {
        readFlight: jest
          .fn()
          .mockResolvedValue({ latitude: 10.3, longitude: -73.3 }),
      } as never,
      { openLandings: jest.fn().mockResolvedValue(new Map()) } as never,
    );
    await expect(service.list()).resolves.toEqual([
      {
        orderId: 'order-1',
        droneId: 'drone-1',
        identifier: 'WC-03',
        hubId: HUB.id,
        kinds: ['battery_critical'],
        latitude: 10.3,
        longitude: -73.3,
      },
    ]);
  });
});
