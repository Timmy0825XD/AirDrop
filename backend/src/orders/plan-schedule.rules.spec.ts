import { BadRequestException } from '@nestjs/common';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { occurrenceDates, windowEnd } from './orders.rules';
import {
  SCHEDULE_BAD_TIME,
  SCHEDULE_COUNT_DOES_NOT_FIT,
  SCHEDULE_EMPTY,
  SCHEDULE_END_OR_COUNT,
  SCHEDULE_NEEDS_DAYS,
  SCHEDULE_PAST_PRESCRIPTION,
  SCHEDULE_START_IN_THE_PAST,
  SCHEDULE_TOO_LONG,
  buildSchedule,
  isoWeekday,
  legacySchedule,
  slotFor,
} from './plan-schedule.rules';

// Lunes 2 de noviembre de 2026, 08:00 en Colombia.
const now = new Date('2026-11-02T13:00:00.000Z');
const dates = (result: ReturnType<typeof buildSchedule>) =>
  result.occurrences.map((occurrence) => occurrence.date);

describe('buildSchedule (RU-30)', () => {
  it('un mes, todos los jueves a las 10:00', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.WEEKLY,
        startDate: '2026-11-02',
        endDate: '2026-12-02',
        daysOfWeek: [4],
        time: '10:00',
      },
      { now },
    );
    expect(dates(result)).toEqual([
      '2026-11-05',
      '2026-11-12',
      '2026-11-19',
      '2026-11-26',
    ]);
    expect(result.occurrences[0].scheduledAt.toISOString()).toBe(
      '2026-11-05T15:00:00.000Z',
    );
    expect(result.occurrences[0].windowEndsAt.toISOString()).toBe(
      '2026-11-05T16:00:00.000Z',
    );
  });

  it('martes y jueves cada 15 días, 4 entregas', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.WEEKLY,
        startDate: '2026-11-02',
        count: 4,
        daysOfWeek: [4, 2],
        everyWeeks: 2,
        time: '08:00',
      },
      { now },
    );
    expect(dates(result)).toEqual([
      '2026-11-03',
      '2026-11-05',
      '2026-11-17',
      '2026-11-19',
    ]);
    expect(result.schedule.daysOfWeek).toEqual([2, 4]);
    expect(result.lastDate).toBe('2026-11-19');
  });

  it('el 31 de cada mes cae en el último día de los meses cortos', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.MONTHLY,
        startDate: '2026-11-02',
        count: 3,
        dayOfMonth: 31,
        time: '09:00',
      },
      { now },
    );
    expect(dates(result)).toEqual(['2026-11-30', '2026-12-31', '2027-01-31']);
  });

  it('fechas sueltas, ordenadas y sin repetir', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.DATES,
        dates: ['2026-11-21', '2026-11-07', '2026-11-21'],
        time: '16:00',
      },
      { now },
    );
    expect(dates(result)).toEqual(['2026-11-07', '2026-11-21']);
    expect(result.schedule.startDate).toBe('2026-11-07');
  });

  it('no agenda lo que empieza en menos de 2 horas y lo informa', () => {
    // Hoy a las 09:00 queda a 1 hora; a las 10:00 queda justo a 2 horas.
    const early = buildSchedule(
      {
        kind: ScheduleKind.DATES,
        dates: ['2026-11-02', '2026-11-03'],
        time: '09:00',
      },
      { now },
    );
    expect(dates(early)).toEqual(['2026-11-03']);
    expect(early.tooSoon).toEqual(['2026-11-02']);
    const onTime = buildSchedule(
      { kind: ScheduleKind.DATES, dates: ['2026-11-02'], time: '10:00' },
      { now },
    );
    expect(dates(onTime)).toEqual(['2026-11-02']);
  });

  it('con número de entregas, las que no se agendan no cuentan', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.WEEKLY,
        startDate: '2026-11-02',
        count: 2,
        daysOfWeek: [1],
        time: '09:00',
      },
      { now },
    );
    expect(dates(result)).toEqual(['2026-11-09', '2026-11-16']);
  });

  it('rechaza las reglas imposibles', () => {
    const weekly = {
      kind: ScheduleKind.WEEKLY,
      startDate: '2026-11-02',
      daysOfWeek: [4],
      time: '10:00',
    };
    const cases: Array<[object, string]> = [
      [
        { ...weekly, startDate: '2026-11-01', count: 1 },
        SCHEDULE_START_IN_THE_PAST,
      ],
      [{ ...weekly }, SCHEDULE_END_OR_COUNT],
      [{ ...weekly, count: 2, endDate: '2026-11-30' }, SCHEDULE_END_OR_COUNT],
      [{ ...weekly, endDate: '2027-02-03' }, SCHEDULE_TOO_LONG],
      [{ ...weekly, daysOfWeek: [], count: 1 }, SCHEDULE_NEEDS_DAYS],
      [{ ...weekly, count: 1, time: '18:00' }, SCHEDULE_BAD_TIME],
      [{ ...weekly, count: 1, time: '06:00' }, SCHEDULE_BAD_TIME],
      [{ ...weekly, count: 1, time: '10:30' }, SCHEDULE_BAD_TIME],
      [{ ...weekly, count: 20 }, SCHEDULE_COUNT_DOES_NOT_FIT],
      [
        { kind: ScheduleKind.DATES, dates: ['2026-11-02'], time: '08:00' },
        SCHEDULE_EMPTY,
      ],
    ];
    for (const [input, message] of cases) {
      expect(() =>
        buildSchedule(input as Parameters<typeof buildSchedule>[0], { now }),
      ).toThrow(new BadRequestException(message));
    }
  });

  it('tres meses justos sí caben', () => {
    const result = buildSchedule(
      {
        kind: ScheduleKind.WEEKLY,
        startDate: '2026-11-02',
        endDate: '2027-02-02',
        daysOfWeek: [2],
        time: '10:00',
      },
      { now },
    );
    expect(result.lastDate).toBe('2027-02-02');
  });

  it('bajo fórmula, el plan no pasa de su vigencia', () => {
    const input = {
      kind: ScheduleKind.WEEKLY,
      startDate: '2026-11-02',
      endDate: '2026-11-30',
      daysOfWeek: [4],
      time: '10:00',
    };
    expect(() =>
      buildSchedule(input, { now, prescriptionValidUntil: '2026-11-20' }),
    ).toThrow(new BadRequestException(SCHEDULE_PAST_PRESCRIPTION));
    expect(
      buildSchedule(input, { now, prescriptionValidUntil: '2026-11-26' })
        .lastDate,
    ).toBe('2026-11-26');
  });
});

describe('planes con la frecuencia anterior', () => {
  it('la regla equivalente da las mismas fechas que occurrenceDates', () => {
    for (const frequency of [
      PlanFrequency.WEEKLY,
      PlanFrequency.BIWEEKLY,
      PlanFrequency.MONTHLY,
      PlanFrequency.ONCE,
    ]) {
      const start = '2026-11-05';
      const schedule = legacySchedule(frequency, start, windowEnd(start));
      const rebuilt = buildSchedule(
        {
          kind: schedule.kind,
          startDate: schedule.startDate,
          endDate: schedule.endDate ?? undefined,
          daysOfWeek: schedule.daysOfWeek,
          everyWeeks: schedule.everyWeeks,
          dayOfMonth: schedule.dayOfMonth ?? undefined,
          dates: schedule.dates,
          time: '10:00',
        },
        { now },
      );
      expect(dates(rebuilt)).toEqual(
        occurrenceDates(start, windowEnd(start), frequency),
      );
    }
  });

  it('sin hora, la franja es todo el horario operativo', () => {
    const slot = slotFor('2026-11-05', null);
    expect(slot.scheduledAt.toISOString()).toBe('2026-11-05T12:00:00.000Z');
    expect(slot.windowEndsAt.toISOString()).toBe('2026-11-05T23:00:00.000Z');
  });

  it('isoWeekday cuenta el lunes como 1 y el domingo como 7', () => {
    expect(isoWeekday('2026-11-02')).toBe(1);
    expect(isoWeekday('2026-11-08')).toBe(7);
  });
});
