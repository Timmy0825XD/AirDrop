import { ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import {
  EVERY_HUB_DECLINED,
  NOT_OFFERED_TO_HUB,
  NO_HUB_WITHIN_RANGE,
} from './dispatch.rules';
import { EmergencyDispatchService } from './emergency-dispatch.service';

const MIN = 60_000;
const t0 = new Date('2026-11-02T15:00:00.000Z');
const ORDER_ID = '11111111-1111-4111-8111-111111111111';

function hubAt(id: string, longitude: number): Hub {
  return {
    id,
    name: `Central ${id}`,
    status: HubStatus.ACTIVE,
    address: 'Calle 1',
    contactPhone: '3000000000',
    contactEmail: null,
    latitude: 10.46,
    longitude,
  } as unknown as Hub;
}

/** A queda a 6 min, B a 7,5 min y C a 14 min del destino. */
const hubs = {
  A: hubAt('A', -73.26),
  B: hubAt('B', -73.3),
  C: hubAt('C', -73.4),
};

type Reach = {
  lot: boolean;
  etaMin?: number;
  inRange?: boolean;
  ready?: boolean;
};

function emergency(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    status: OrderStatus.RECEIVED,
    originHubId: null,
    destinationHubId: null,
    reassignedFromHubId: null,
    fallbackKind: null,
    fallbackReason: null,
    fallbackOptions: null,
    dispatchOffers: null,
    nextEscalationAt: null,
    latitude: 10.46,
    longitude: -73.25,
    ...overrides,
  } as Order;
}

function dispatcherOf(hubId: string): User {
  return {
    id: `user-${hubId}`,
    role: UserRole.DISPATCHER,
    hubAssignments: [{ hubId }],
  } as unknown as User;
}

function build(reach: Record<string, Reach>, order = emergency()) {
  const state = { order };
  const manager = {
    findOne: jest.fn(() => Promise.resolve(state.order)),
    find: jest.fn(() => Promise.resolve(Object.values(hubs))),
    save: jest.fn((value: Order) => {
      state.order = value;
      return Promise.resolve(value);
    }),
  };
  const due = { find: jest.fn(() => Promise.resolve([state.order])) };
  const dataSource = {
    transaction: jest.fn((work: (m: typeof manager) => unknown) =>
      work(manager),
    ),
    getRepository: jest.fn(() => due),
  };
  const hubEvaluation = {
    evaluate: jest.fn((_m: unknown, hub: Hub) => {
      const row = reach[hub.id] ?? { lot: false };
      return Promise.resolve({
        lot: row.lot ? { id: `lot-${hub.id}` } : null,
        etaMs: row.etaMin != null ? row.etaMin * MIN : null,
        inRange: row.inRange ?? row.etaMin != null,
        choice: { chosen: row.ready === false ? null : { droneId: 'd' } },
      });
    }),
  };
  const routes = { loadPolygons: jest.fn(() => Promise.resolve([])) };
  const hubsService = {
    requireActive: jest.fn((id: string) =>
      Promise.resolve(hubs[id as keyof typeof hubs]),
    ),
  };
  const notifications = {
    queueChanged: jest.fn(() => Promise.resolve()),
    statusChanged: jest.fn(() => Promise.resolve()),
  };
  const service = new EmergencyDispatchService(
    dataSource as never,
    hubEvaluation as never,
    routes as never,
    hubsService as never,
    notifications as never,
  );
  return { service, state, notifications };
}

const threeHubs: Record<string, Reach> = {
  A: { lot: true, etaMin: 6 },
  B: { lot: true, etaMin: 7.5 },
  C: { lot: true, etaMin: 14 },
};

describe('EmergencyDispatchService.start', () => {
  it('ofrece la urgencia solo a la central que llega primero y le avisa', async () => {
    const { service, state, notifications } = build(threeHubs);

    await service.start(ORDER_ID, t0);

    const offers = state.order.dispatchOffers!;
    expect(offers.map((offer) => offer.hubId)).toEqual(['A', 'B', 'C']);
    expect(offers.map((offer) => offer.offeredAt != null)).toEqual([
      true,
      false,
      false,
    ]);
    expect(state.order.nextEscalationAt).toEqual(
      new Date(t0.getTime() + 1.5 * MIN),
    );
    expect(state.order.originHubId).toBeNull();
    expect(notifications.queueChanged).toHaveBeenCalledTimes(1);
    expect(notifications.queueChanged).toHaveBeenCalledWith('A', ORDER_ID);
  });

  it('la central más cercana sin dron va después de una lista', async () => {
    const { service, state } = build({
      A: { lot: true, etaMin: 6, ready: false },
      B: { lot: true, etaMin: 7.5 },
    });

    await service.start(ORDER_ID, t0);

    expect(state.order.dispatchOffers!.map((offer) => offer.hubId)).toEqual([
      'B',
      'A',
    ]);
  });

  it('deja fuera a las centrales fuera de alcance o sin lote', async () => {
    const { service, state } = build({
      A: { lot: false },
      B: { lot: true, etaMin: 30, inRange: false },
      C: { lot: true, etaMin: 14 },
    });

    await service.start(ORDER_ID, t0);

    expect(state.order.dispatchOffers!.map((offer) => offer.hubId)).toEqual([
      'C',
    ]);
    expect(state.order.nextEscalationAt).toBeNull();
  });

  it('sin ninguna central en alcance pasa de una vez a traslado convencional', async () => {
    const { service, state, notifications } = build({
      A: { lot: true, inRange: false },
      B: { lot: false },
      C: { lot: true, inRange: false },
    });

    await service.start(ORDER_ID, t0);

    expect(state.order.status).toBe(OrderStatus.REASSIGNED);
    expect(state.order.fallbackKind).toBe(FallbackKind.CONVENTIONAL);
    expect(state.order.fallbackReason).toBe(NO_HUB_WITHIN_RANGE);
    expect(state.order.fallbackOptions!.map((option) => option.hubId)).toEqual([
      'A',
      'C',
    ]);
    expect(notifications.statusChanged).toHaveBeenCalledWith(
      ORDER_ID,
      OrderStatus.REASSIGNED,
    );
  });
});

describe('EmergencyDispatchService.escalateDue', () => {
  it('al vencer la ventaja amplía la oferta a la siguiente central', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);
    built.notifications.queueChanged.mockClear();

    await built.service.escalateDue(new Date(t0.getTime() + 1.5 * MIN));

    const offered = built.state.order.dispatchOffers!.filter(
      (offer) => offer.offeredAt != null,
    );
    expect(offered.map((offer) => offer.hubId)).toEqual(['A', 'B']);
    expect(built.notifications.queueChanged).toHaveBeenCalledWith(
      'B',
      ORDER_ID,
    );
  });

  it('antes de tiempo no amplía nada', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);

    await built.service.escalateDue(new Date(t0.getTime() + MIN));

    const offered = built.state.order.dispatchOffers!.filter(
      (offer) => offer.offeredAt != null,
    );
    expect(offered).toHaveLength(1);
  });

  it('no toca una urgencia que ya autorizó una central', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);
    built.state.order.originHubId = 'A';
    built.state.order.status = OrderStatus.PENDING_LOAD;
    const before = built.state.order.dispatchOffers;

    await built.service.escalateDue(new Date(t0.getTime() + 10 * MIN));

    expect(built.state.order.dispatchOffers).toBe(before);
  });
});

describe('EmergencyDispatchService.decline', () => {
  it('si la central declina, la siguiente la ve en ese instante', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);
    built.notifications.queueChanged.mockClear();

    await built.service.decline(
      dispatcherOf('A'),
      ORDER_ID,
      'Sin dron',
      new Date(t0.getTime() + 20_000),
    );

    const [a, b] = built.state.order.dispatchOffers!;
    expect(a.declinedAt).not.toBeNull();
    expect(b.offeredAt).not.toBeNull();
    expect(built.notifications.queueChanged).toHaveBeenCalledWith(
      'A',
      ORDER_ID,
    );
    expect(built.notifications.queueChanged).toHaveBeenCalledWith(
      'B',
      ORDER_ID,
    );
  });

  it('una central a la que no se le ofreció no puede declinar', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);

    await expect(
      built.service.decline(dispatcherOf('C'), ORDER_ID, null, t0),
    ).rejects.toThrow(new ForbiddenException(NOT_OFFERED_TO_HUB));
  });

  it('si todas declinan, queda en traslado convencional', async () => {
    const built = build(threeHubs);
    await built.service.start(ORDER_ID, t0);

    for (const id of ['A', 'B', 'C']) {
      await built.service.decline(dispatcherOf(id), ORDER_ID, null, t0);
    }

    expect(built.state.order.status).toBe(OrderStatus.REASSIGNED);
    expect(built.state.order.fallbackKind).toBe(FallbackKind.CONVENTIONAL);
    expect(built.state.order.fallbackReason).toBe(EVERY_HUB_DECLINED);
    expect(built.state.order.nextEscalationAt).toBeNull();
  });
});
