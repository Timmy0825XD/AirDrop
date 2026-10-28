import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import {
  OCCURRENCE_LOCKED,
  RESCHEDULE_SAME_OR_NEXT_DAY,
  RESCHEDULE_TOO_SOON,
  assertChangeable,
  assertRecipient,
  confirmBy,
  describeSlot,
  initialOccurrenceState,
  isPastConfirmation,
  isReminderDue,
  rescheduledSlot,
} from './plan-occurrence.rules';
import { SCHEDULE_BAD_TIME, slotFor } from './plan-schedule.rules';

// Lunes 2 de noviembre de 2026, 08:00 en Colombia.
const NOW = new Date('2026-11-02T13:00:00.000Z');
const HOUR = 60 * 60 * 1000;
const REQUESTER_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

function occurrence(overrides: object = {}) {
  return {
    status: OrderStatus.SCHEDULED,
    planId: 'plan',
    droneId: null,
    scheduledFor: '2026-11-05',
    scheduledAt: new Date('2026-11-05T15:00:00.000Z'),
    destinationKind: DestinationKind.PERSON,
    requesterId: REQUESTER_ID,
    destinationHubId: null,
    ...overrides,
  };
}

const at = (hoursFromNow: number) =>
  new Date(NOW.getTime() + hoursFromNow * HOUR);

describe('initialOccurrenceState', () => {
  const person = {
    deliveryTime: '10:00',
    destinationKind: DestinationKind.PERSON,
  };

  it('un plan anterior, sin franja, nace en recibido como siempre', () => {
    expect(
      initialOccurrenceState(
        { deliveryTime: null, destinationKind: DestinationKind.PERSON },
        slotFor('2026-11-20', null),
        NOW,
      ),
    ).toEqual({ status: OrderStatus.RECEIVED, confirmedAt: null });
  });

  it('a más de 24 horas queda agendada; a 24 horas o menos, confirmada', () => {
    expect(
      initialOccurrenceState(person, slotFor('2026-11-05', '10:00'), NOW)
        .status,
    ).toBe(OrderStatus.SCHEDULED);
    expect(
      initialOccurrenceState(person, slotFor('2026-11-03', '08:00'), NOW),
    ).toEqual({ status: OrderStatus.RECEIVED, confirmedAt: NOW });
  });
});

describe('assertRecipient', () => {
  const requester = { id: REQUESTER_ID, role: UserRole.REQUESTER } as User;
  const hubDispatcher = {
    id: 'd',
    role: UserRole.DISPATCHER,
    hubAssignments: [{ hubId: HUB_ID }],
  } as unknown as User;

  it('a una persona solo la cambia ella; a una central, su despachador', () => {
    expect(() => assertRecipient(requester, occurrence())).not.toThrow();
    expect(() => assertRecipient(hubDispatcher, occurrence())).toThrow(
      ForbiddenException,
    );
    const toHub = occurrence({
      destinationKind: DestinationKind.HUB,
      requesterId: null,
      destinationHubId: HUB_ID,
    });
    expect(() => assertRecipient(hubDispatcher, toHub)).not.toThrow();
    expect(() => assertRecipient(requester, toHub)).toThrow(ForbiddenException);
  });
});

describe('assertChangeable', () => {
  it('se cambia hasta 2 horas antes y mientras no tenga dron', () => {
    expect(() => assertChangeable(occurrence(), NOW)).not.toThrow();
    for (const locked of [
      occurrence({ scheduledAt: at(1.5) }),
      occurrence({ droneId: 'drone' }),
      occurrence({ status: OrderStatus.PENDING_LOAD }),
      occurrence({ status: OrderStatus.SKIPPED }),
    ]) {
      expect(() => assertChangeable(locked, NOW)).toThrow(
        new BadRequestException(OCCURRENCE_LOCKED),
      );
    }
    expect(() =>
      assertChangeable(occurrence({ scheduledAt: at(2) }), NOW),
    ).not.toThrow();
  });
});

describe('rescheduledSlot', () => {
  it('mueve la entrega al mismo día o al siguiente, en una franja válida', () => {
    const same = rescheduledSlot(occurrence(), '2026-11-05', '15:00', NOW);
    expect(same.scheduledAt.toISOString()).toBe('2026-11-05T20:00:00.000Z');
    const next = rescheduledSlot(occurrence(), '2026-11-06', '07:00', NOW);
    expect(next.windowEndsAt.toISOString()).toBe('2026-11-06T13:00:00.000Z');
  });

  it('no la lleva a otro día, a una hora no válida ni a menos de 2 horas', () => {
    expect(() =>
      rescheduledSlot(occurrence(), '2026-11-07', '10:00', NOW),
    ).toThrow(new BadRequestException(RESCHEDULE_SAME_OR_NEXT_DAY));
    expect(() =>
      rescheduledSlot(occurrence(), '2026-11-05', '19:00', NOW),
    ).toThrow(new BadRequestException(SCHEDULE_BAD_TIME));
    const today = occurrence({ scheduledFor: '2026-11-02' });
    expect(() => rescheduledSlot(today, '2026-11-02', '09:00', NOW)).toThrow(
      new BadRequestException(RESCHEDULE_TOO_SOON),
    );
  });
});

describe('relojes de T-24 h y T-2 h', () => {
  it('avisa desde 24 horas antes', () => {
    expect(isReminderDue(occurrence({ scheduledAt: at(25) }), NOW)).toBe(false);
    expect(isReminderDue(occurrence({ scheduledAt: at(24) }), NOW)).toBe(true);
    expect(
      isReminderDue(
        occurrence({
          scheduledAt: at(5),
          status: OrderStatus.AWAITING_CONFIRMATION,
        }),
        NOW,
      ),
    ).toBe(false);
  });

  it('a menos de 2 horas, lo que no se confirmó se pasa', () => {
    const waiting = { status: OrderStatus.AWAITING_CONFIRMATION };
    expect(
      isPastConfirmation(occurrence({ ...waiting, scheduledAt: at(2) }), NOW),
    ).toBe(false);
    expect(
      isPastConfirmation(occurrence({ ...waiting, scheduledAt: at(1.9) }), NOW),
    ).toBe(true);
    expect(
      isPastConfirmation(
        occurrence({ status: OrderStatus.RECEIVED, scheduledAt: at(1) }),
        NOW,
      ),
    ).toBe(false);
  });
});

describe('textos de los avisos', () => {
  it('describe la franja en hora de Colombia y la hora límite', () => {
    const slot = slotFor('2026-11-05', '10:00');
    expect(describeSlot(slot.scheduledAt, slot.windowEndsAt)).toBe(
      'jueves, 5 de noviembre, de 10:00 a 11:00',
    );
    expect(confirmBy(slot.scheduledAt)).toBe('08:00');
  });
});
