import { BadRequestException } from '@nestjs/common';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { addCalendarDays, todayInColombia } from './orders.rules';

/** RU-30: la primera franja empieza a las 07:00 y la última a las 17:00. */
export const FIRST_SLOT_HOUR = 7;
export const LAST_SLOT_HOUR = 17;
export const SLOT_MS = 60 * 60 * 1000;
/** Antes de esto no da tiempo de avisar ni de preparar la carga. */
export const SCHEDULE_LEAD_MS = 2 * 60 * 60 * 1000;
export const MAX_PLAN_MONTHS = 3;
export const MAX_PLAN_DATES = 30;
export const MAX_EVERY_WEEKS = 4;

export const SCHEDULE_START_IN_THE_PAST =
  'El plan no puede empezar antes de hoy.';
export const SCHEDULE_END_BEFORE_START =
  'La fecha de fin no puede ser anterior a la de inicio.';
export const SCHEDULE_TOO_LONG = `Un plan dura como máximo ${MAX_PLAN_MONTHS} meses.`;
export const SCHEDULE_END_OR_COUNT =
  'Indica cuándo termina el plan: una fecha de fin o un número de entregas, no las dos.';
export const SCHEDULE_NEEDS_DAYS = 'Elige al menos un día de la semana.';
export const SCHEDULE_NEEDS_DAY_OF_MONTH = 'Elige el día del mes.';
export const SCHEDULE_NEEDS_DATES = `Elige entre 1 y ${MAX_PLAN_DATES} fechas.`;
export const SCHEDULE_BAD_TIME =
  'La hora debe ser en punto, entre las 07:00 y las 17:00.';
export const SCHEDULE_COUNT_DOES_NOT_FIT = `Esas entregas no caben en ${MAX_PLAN_MONTHS} meses.`;
export const SCHEDULE_EMPTY =
  'El plan no tiene entregas a más de 2 horas. Revisa las fechas y la hora.';
export const SCHEDULE_PAST_PRESCRIPTION =
  'El plan no puede durar más que la vigencia de la fórmula.';
export const PRESCRIPTION_VALIDITY_REQUIRED =
  'Indica hasta cuándo vale la fórmula.';

/** La regla del calendario, como la guarda el plan. */
export type PlanSchedule = {
  kind: ScheduleKind;
  startDate: string;
  endDate: string | null;
  count: number | null;
  daysOfWeek: number[];
  everyWeeks: number;
  dayOfMonth: number | null;
  dates: string[];
  /** `HH:00`; `null` en los planes anteriores: todo el horario operativo. */
  time: string | null;
};

export type ScheduleInput = {
  kind: ScheduleKind;
  startDate?: string;
  endDate?: string;
  count?: number;
  daysOfWeek?: number[];
  everyWeeks?: number;
  dayOfMonth?: number;
  dates?: string[];
  time: string;
};

export type Occurrence = {
  date: string;
  scheduledAt: Date;
  windowEndsAt: Date;
};

export type ScheduleResult = {
  schedule: PlanSchedule;
  occurrences: Occurrence[];
  /** Fechas que caían a menos de 2 horas y no se agendan. */
  tooSoon: string[];
  /** Último día que cubre el plan. */
  lastDate: string;
};

/**
 * Valida la regla y la convierte en entregas. Puro: recibe `now` para que
 * los tests y la vista previa den siempre lo mismo.
 */
export function buildSchedule(
  input: ScheduleInput,
  options: { now?: Date; prescriptionValidUntil?: string | null } = {},
): ScheduleResult {
  const now = options.now ?? new Date();
  const today = todayInColombia(now);
  assertTime(input.time);
  const schedule = normalize(input, today);
  if (schedule.startDate < today) {
    throw new BadRequestException(SCHEDULE_START_IN_THE_PAST);
  }
  const limit = addMonths(schedule.startDate, MAX_PLAN_MONTHS);
  if (schedule.endDate) {
    if (schedule.endDate < schedule.startDate) {
      throw new BadRequestException(SCHEDULE_END_BEFORE_START);
    }
    if (schedule.endDate > limit) {
      throw new BadRequestException(SCHEDULE_TOO_LONG);
    }
  }
  const candidates = candidateDates(schedule, schedule.endDate ?? limit);
  const occurrences: Occurrence[] = [];
  const tooSoon: string[] = [];
  for (const date of candidates) {
    if (schedule.count != null && occurrences.length >= schedule.count) {
      break;
    }
    const slot = slotFor(date, schedule.time);
    if (slot.scheduledAt.getTime() - now.getTime() < SCHEDULE_LEAD_MS) {
      tooSoon.push(date);
      continue;
    }
    occurrences.push(slot);
  }
  if (schedule.count != null && occurrences.length < schedule.count) {
    throw new BadRequestException(SCHEDULE_COUNT_DOES_NOT_FIT);
  }
  if (!occurrences.length) {
    throw new BadRequestException(SCHEDULE_EMPTY);
  }
  const lastDate = occurrences[occurrences.length - 1].date;
  if (
    options.prescriptionValidUntil &&
    lastDate > options.prescriptionValidUntil
  ) {
    throw new BadRequestException(SCHEDULE_PAST_PRESCRIPTION);
  }
  return { schedule, occurrences, tooSoon, lastDate };
}

/**
 * Franja de una fecha. Sin hora (planes anteriores), la franja es todo el
 * horario operativo de ese día.
 */
export function slotFor(date: string, time: string | null): Occurrence {
  if (time == null) {
    return {
      date,
      scheduledAt: colombiaInstant(date, hourText(FIRST_SLOT_HOUR)),
      windowEndsAt: colombiaInstant(date, hourText(LAST_SLOT_HOUR + 1)),
    };
  }
  const scheduledAt = colombiaInstant(date, time);
  return {
    date,
    scheduledAt,
    windowEndsAt: new Date(scheduledAt.getTime() + SLOT_MS),
  };
}

/** La regla equivalente a un plan con la frecuencia anterior. */
export function legacySchedule(
  frequency: PlanFrequency,
  startDate: string,
  windowEndsOn: string,
): PlanSchedule {
  const base = {
    startDate,
    endDate: addCalendarDays(windowEndsOn, -1),
    count: null,
    dayOfMonth: null,
    dates: [] as string[],
    time: null,
  };
  switch (frequency) {
    case PlanFrequency.ONCE:
      return {
        ...base,
        kind: ScheduleKind.DATES,
        endDate: startDate,
        daysOfWeek: [],
        everyWeeks: 1,
        dates: [startDate],
      };
    case PlanFrequency.MONTHLY:
      return {
        ...base,
        kind: ScheduleKind.MONTHLY,
        daysOfWeek: [],
        everyWeeks: 1,
        dayOfMonth: Number(startDate.slice(8, 10)),
      };
    default:
      return {
        ...base,
        kind: ScheduleKind.WEEKLY,
        daysOfWeek: [isoWeekday(startDate)],
        everyWeeks: frequency === PlanFrequency.BIWEEKLY ? 2 : 1,
      };
  }
}

/** 1 = lunes … 7 = domingo. */
export function isoWeekday(date: string): number {
  return dateToUtc(date).getUTCDay() || 7;
}

/** Colombia no tiene horario de verano: siempre UTC−5. */
export function colombiaInstant(date: string, time: string): Date {
  return new Date(`${date}T${time}:00-05:00`);
}

function normalize(input: ScheduleInput, today: string): PlanSchedule {
  const time = input.time;
  if (input.kind === ScheduleKind.DATES) {
    const dates = [...new Set(input.dates ?? [])].sort();
    if (!dates.length || dates.length > MAX_PLAN_DATES) {
      throw new BadRequestException(SCHEDULE_NEEDS_DATES);
    }
    return {
      kind: ScheduleKind.DATES,
      startDate: dates[0],
      endDate: dates[dates.length - 1],
      count: null,
      daysOfWeek: [],
      everyWeeks: 1,
      dayOfMonth: null,
      dates,
      time,
    };
  }
  if ((input.endDate == null) === (input.count == null)) {
    throw new BadRequestException(SCHEDULE_END_OR_COUNT);
  }
  const startDate = input.startDate ?? today;
  const common = {
    startDate,
    endDate: input.endDate ?? null,
    count: input.count ?? null,
    dates: [],
    time,
  };
  if (input.kind === ScheduleKind.MONTHLY) {
    if (input.dayOfMonth == null) {
      throw new BadRequestException(SCHEDULE_NEEDS_DAY_OF_MONTH);
    }
    return {
      ...common,
      kind: ScheduleKind.MONTHLY,
      daysOfWeek: [],
      everyWeeks: 1,
      dayOfMonth: input.dayOfMonth,
    };
  }
  const daysOfWeek = [...new Set(input.daysOfWeek ?? [])].sort();
  if (!daysOfWeek.length) {
    throw new BadRequestException(SCHEDULE_NEEDS_DAYS);
  }
  return {
    ...common,
    kind: ScheduleKind.WEEKLY,
    daysOfWeek,
    everyWeeks: input.everyWeeks ?? 1,
    dayOfMonth: null,
  };
}

/** Las fechas que cumple la regla entre el inicio y `until` (incluido). */
function candidateDates(schedule: PlanSchedule, until: string): string[] {
  if (schedule.kind === ScheduleKind.DATES) {
    return schedule.dates.filter((date) => date <= until);
  }
  if (schedule.kind === ScheduleKind.MONTHLY) {
    const dates: string[] = [];
    for (let index = 0; ; index += 1) {
      const date = dayOfMonthAfter(
        schedule.startDate,
        index,
        schedule.dayOfMonth as number,
      );
      if (date > until) {
        return dates;
      }
      if (date >= schedule.startDate) {
        dates.push(date);
      }
    }
  }
  const dates: string[] = [];
  const firstMonday = addCalendarDays(
    schedule.startDate,
    1 - isoWeekday(schedule.startDate),
  );
  for (
    let date = schedule.startDate;
    date <= until;
    date = addCalendarDays(date, 1)
  ) {
    const week = Math.floor(daysBetween(firstMonday, date) / 7);
    if (
      week % schedule.everyWeeks === 0 &&
      schedule.daysOfWeek.includes(isoWeekday(date))
    ) {
      dates.push(date);
    }
  }
  return dates;
}

function assertTime(time: string): void {
  const match = /^(\d{2}):00$/.exec(time);
  const hour = match ? Number(match[1]) : NaN;
  if (!(hour >= FIRST_SLOT_HOUR && hour <= LAST_SLOT_HOUR)) {
    throw new BadRequestException(SCHEDULE_BAD_TIME);
  }
}

/** El día `day` del mes `offset` meses después de `start`; o el último. */
function dayOfMonthAfter(start: string, offset: number, day: number): string {
  const [year, month] = start.split('-').map(Number);
  const target = new Date(Date.UTC(year, month - 1 + offset, 1));
  const last = new Date(
    Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0),
  ).getUTCDate();
  target.setUTCDate(Math.min(day, last));
  return target.toISOString().slice(0, 10);
}

function addMonths(date: string, months: number): string {
  return dayOfMonthAfter(date, months, Number(date.slice(8, 10)));
}

function daysBetween(from: string, to: string): number {
  return Math.round(
    (dateToUtc(to).getTime() - dateToUtc(from).getTime()) / 86_400_000,
  );
}

function dateToUtc(date: string): Date {
  const [year, month, day] = date.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

function hourText(hour: number): string {
  return `${String(hour).padStart(2, '0')}:00`;
}
