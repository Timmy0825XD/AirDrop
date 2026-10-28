import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { FallbackOption } from '../orders/order.entity';
import {
  CONVENTIONAL_WITHOUT_STOCK,
  CONVENTIONAL_WITH_STOCK,
  DEFAULT_SCHEDULED_RETRY_MS,
  FallbackOrder,
  MAX_FALLBACK_OPTIONS,
  applyConventional,
  applyHubReassignment,
  applyRetry,
  canReassign,
  clearFallback,
  droneSearchExclusions,
  isAwaitingHub,
  rankHubsByDistance,
  scheduledRetryMs,
  shouldRetry,
} from './fallback.rules';

const morning = new Date('2026-10-16T15:00:00.000Z');
const lateNight = new Date('2026-10-17T04:50:00.000Z');

function order(overrides: Partial<FallbackOrder> = {}): FallbackOrder {
  return {
    status: OrderStatus.RECEIVED,
    missionType: MissionType.SCHEDULED,
    originHubId: null,
    destinationHubId: null,
    fallbackKind: null,
    fallbackReason: null,
    fallbackOptions: null,
    reassignedFromHubId: null,
    reassignedAt: null,
    retryAfter: null,
    prescriptionVerifiedAt: null,
    ...overrides,
  };
}

function option(hubId: string, distanceKm = 1): FallbackOption {
  return {
    hubId,
    name: `Central ${hubId}`,
    address: 'Calle 1',
    contactPhone: '3000000000',
    contactEmail: null,
    distanceKm,
  };
}

describe('shouldRetry', () => {
  it('retries a scheduled order while the next try falls the same day', () => {
    const next = new Date(morning.getTime() + DEFAULT_SCHEDULED_RETRY_MS);
    expect(shouldRetry(order(), morning, next)).toBe(true);
  });

  it('does not retry once the next try would miss the slot', () => {
    const closes = new Date(morning.getTime() + 10 * 60 * 1000);
    const next = new Date(morning.getTime() + DEFAULT_SCHEDULED_RETRY_MS);
    expect(shouldRetry(order({ windowEndsAt: closes }), morning, next)).toBe(
      false,
    );
  });

  it('does not retry past midnight in Colombia', () => {
    const next = new Date(lateNight.getTime() + DEFAULT_SCHEDULED_RETRY_MS);
    expect(shouldRetry(order(), lateNight, next)).toBe(false);
  });

  it('never retries an emergency or an order already reassigned', () => {
    const next = new Date(morning.getTime() + 1000);
    expect(
      shouldRetry(order({ missionType: MissionType.EMERGENCY }), morning, next),
    ).toBe(false);
    expect(
      shouldRetry(order({ reassignedFromHubId: 'hub-a' }), morning, next),
    ).toBe(false);
  });
});

describe('scheduledRetryMs', () => {
  const previous = process.env.SCHEDULED_RETRY_MS;

  afterEach(() => {
    process.env.SCHEDULED_RETRY_MS = previous;
  });

  it('reads the variable and falls back to 15 minutes', () => {
    process.env.SCHEDULED_RETRY_MS = '5000';
    expect(scheduledRetryMs()).toBe(5000);
    process.env.SCHEDULED_RETRY_MS = 'nada';
    expect(scheduledRetryMs()).toBe(DEFAULT_SCHEDULED_RETRY_MS);
  });
});

describe('who can take the order', () => {
  it('reassigns only once', () => {
    expect(canReassign(order())).toBe(true);
    expect(canReassign(order({ reassignedFromHubId: 'hub-a' }))).toBe(false);
  });

  it('a reassigned order waits in the new hub queue; a conventional one is closed', () => {
    expect(isAwaitingHub(order())).toBe(true);
    expect(
      isAwaitingHub(
        order({
          status: OrderStatus.REASSIGNED,
          fallbackKind: FallbackKind.HUB,
        }),
      ),
    ).toBe(true);
    expect(
      isAwaitingHub(
        order({
          status: OrderStatus.REASSIGNED,
          fallbackKind: FallbackKind.CONVENTIONAL,
        }),
      ),
    ).toBe(false);
  });

  it('skips the failing hub, the destination and the previous hub for drones', () => {
    const skipped = droneSearchExclusions(
      order({ destinationHubId: 'hub-dest', reassignedFromHubId: 'hub-prev' }),
      'hub-fail',
    );
    expect([...skipped].sort()).toEqual(['hub-dest', 'hub-fail', 'hub-prev']);
  });
});

describe('rankHubsByDistance', () => {
  it('orders from the closest hub to the destination, ties by name', () => {
    const destination = { latitude: 10.46, longitude: -73.25 };
    const ranked = rankHubsByDistance(
      [
        { id: 'far', name: 'Lejana', latitude: 10.6, longitude: -73.25 },
        { id: 'b', name: 'Beta', latitude: 10.47, longitude: -73.25 },
        { id: 'a', name: 'Alfa', latitude: 10.47, longitude: -73.25 },
      ],
      destination,
    );
    expect(ranked.map((entry) => entry.hub.id)).toEqual(['a', 'b', 'far']);
    expect(ranked[0].distanceKm).toBeCloseTo(1.11, 1);
  });
});

describe('applying the fallback', () => {
  it('retry keeps the order received at the hub that tried', () => {
    const next = new Date(morning.getTime() + DEFAULT_SCHEDULED_RETRY_MS);
    const target = order();
    applyRetry(target, 'hub-a', next, DEFAULT_SCHEDULED_RETRY_MS);
    expect(target.status).toBe(OrderStatus.RECEIVED);
    expect(target.originHubId).toBe('hub-a');
    expect(target.fallbackKind).toBe(FallbackKind.RETRY);
    expect(target.fallbackReason).toContain('15 min');
    expect(target.retryAfter).toBe(next);
  });

  it('hub reassignment moves the origin and asks for the formula again', () => {
    const target = order({ prescriptionVerifiedAt: morning });
    applyHubReassignment(target, 'hub-a', option('hub-c'), morning);
    expect(target.status).toBe(OrderStatus.REASSIGNED);
    expect(target.originHubId).toBe('hub-c');
    expect(target.reassignedFromHubId).toBe('hub-a');
    expect(target.fallbackOptions).toEqual([option('hub-c')]);
    expect(target.fallbackReason).toContain('Central hub-c');
    expect(target.prescriptionVerifiedAt).toBeNull();
  });

  it('conventional keeps up to three hubs with stock', () => {
    const target = order();
    const withStock = ['a', 'b', 'c', 'd'].map((id) => option(id));
    applyConventional(target, 'hub-a', withStock, morning);
    expect(target.status).toBe(OrderStatus.REASSIGNED);
    expect(target.fallbackKind).toBe(FallbackKind.CONVENTIONAL);
    expect(target.fallbackOptions).toHaveLength(MAX_FALLBACK_OPTIONS);
    expect(target.fallbackReason).toBe(CONVENTIONAL_WITH_STOCK);
  });

  it('conventional without stock anywhere says so, and keeps the first hub that failed', () => {
    const target = order({ reassignedFromHubId: 'hub-first' });
    applyConventional(target, 'hub-second', [], morning);
    expect(target.fallbackReason).toBe(CONVENTIONAL_WITHOUT_STOCK);
    expect(target.reassignedFromHubId).toBe('hub-first');
    expect(target.originHubId).toBe('hub-second');
  });

  it('clearing keeps the reassignment history', () => {
    const target = order();
    applyHubReassignment(target, 'hub-a', option('hub-c'), morning);
    clearFallback(target);
    expect(target.fallbackKind).toBeNull();
    expect(target.fallbackOptions).toBeNull();
    expect(target.reassignedFromHubId).toBe('hub-a');
  });
});
