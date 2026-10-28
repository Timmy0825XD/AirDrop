import { BadRequestException } from '@nestjs/common';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import {
  DISPATCH_TOO_EARLY,
  WINDOW_CLOSED,
  assertDispatchWindow,
  buildAgenda,
  departBefore,
  isMissedDeparture,
  prescriptionStillValid,
} from './plan-dispatch.rules';

const SLOT_START = new Date('2026-11-05T15:00:00.000Z');
const SLOT_END = new Date('2026-11-05T16:00:00.000Z');

function scheduled(overrides: Record<string, unknown> = {}) {
  return {
    missionType: MissionType.SCHEDULED,
    fallbackKind: null,
    reassignedFromHubId: null,
    scheduledFor: '2026-11-05',
    scheduledAt: SLOT_START,
    windowEndsAt: SLOT_END,
    status: OrderStatus.RECEIVED,
    loadConfirmedAt: null,
    ...overrides,
  };
}

describe('dispatch window', () => {
  it('opens two hours before the slot and closes with it', () => {
    expect(() =>
      assertDispatchWindow(scheduled(), new Date('2026-11-05T14:00:00.000Z')),
    ).not.toThrow();
    expect(() =>
      assertDispatchWindow(scheduled(), new Date('2026-11-05T12:59:00.000Z')),
    ).toThrow(new BadRequestException(DISPATCH_TOO_EARLY));
    expect(() =>
      assertDispatchWindow(scheduled(), new Date('2026-11-05T16:00:00.000Z')),
    ).toThrow(new BadRequestException(WINDOW_CLOSED));
  });

  it('does not bound an emergency or a hub that received the fallback', () => {
    expect(() =>
      assertDispatchWindow(
        scheduled({ missionType: MissionType.EMERGENCY }),
        new Date('2026-11-05T12:00:00.000Z'),
      ),
    ).not.toThrow();
    expect(() =>
      assertDispatchWindow(
        scheduled({ fallbackKind: FallbackKind.HUB }),
        new Date('2026-11-05T18:00:00.000Z'),
      ),
    ).not.toThrow();
  });

  it('misses a departure that is still on the ground when the slot closes', () => {
    const closed = new Date('2026-11-05T16:00:00.000Z');
    expect(isMissedDeparture(scheduled(), closed)).toBe(true);
    expect(
      isMissedDeparture(
        scheduled({ loadConfirmedAt: closed, status: OrderStatus.PENDING_LOAD }),
        closed,
      ),
    ).toBe(false);
    expect(
      isMissedDeparture(scheduled({ status: OrderStatus.IN_FLIGHT }), closed),
    ).toBe(false);
  });
});

describe('agenda facts', () => {
  it('puts the latest departure one ETA before the slot closes', () => {
    expect(departBefore(SLOT_END, 20 * 60 * 1000).toISOString()).toBe(
      '2026-11-05T15:40:00.000Z',
    );
  });

  it('groups the day by slot and marks a slot with more deliveries than drones', () => {
    const row = {
      time: '10:00',
      status: OrderStatus.RECEIVED,
      confirmed: true,
      stockOk: true,
      prescriptionValid: null,
      departBefore: SLOT_START.toISOString(),
      availableQuantity: 4,
    };
    const agenda = buildAgenda(1, [row, { ...row, status: OrderStatus.SKIPPED }]);
    expect(agenda.drones).toBe(1);
    expect(agenda.slots).toEqual([
      {
        time: '10:00',
        deliveries: 1,
        overCapacity: false,
        orders: [row, { ...row, status: OrderStatus.SKIPPED }],
      },
    ]);
    expect(buildAgenda(1, [row, row]).slots[0].overCapacity).toBe(true);
  });

  it('treats a missing prescription date as still valid', () => {
    expect(
      prescriptionStillValid(SaleType.OVER_THE_COUNTER, null, '2026-11-05'),
    ).toBeNull();
    expect(
      prescriptionStillValid(SaleType.PRESCRIPTION, '2026-11-05', '2026-11-05'),
    ).toBe(true);
    expect(
      prescriptionStillValid(SaleType.PRESCRIPTION, '2026-11-04', '2026-11-05'),
    ).toBe(false);
  });
});
