import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { addCalendarDays } from './orders.rules';
import {
  Occurrence,
  SCHEDULE_LEAD_MS,
  assertTime,
  slotFor,
} from './plan-schedule.rules';

/** RU-30: el aviso para confirmar sale 24 horas antes de la franja. */
export const REMINDER_LEAD_MS = 24 * 60 * 60 * 1000;

/** Entregas de un plan que todavía no tienen dron: se pueden cambiar. */
export const NOT_YET_AUTHORIZED = [
  OrderStatus.SCHEDULED,
  OrderStatus.AWAITING_CONFIRMATION,
  OrderStatus.RECEIVED,
];

export const OCCURRENCE_LOCKED =
  'Esta entrega ya no se puede cambiar: faltan menos de 2 horas o ya tiene dron.';
export const NOT_THE_RECIPIENT =
  'Solo quien recibe la entrega puede cambiarla.';
export const ONLY_PLAN_DELIVERIES =
  'Solo las entregas de un plan se confirman.';
export const NOTHING_TO_CONFIRM = 'Esta entrega no espera confirmación.';
export const RESCHEDULE_SAME_OR_NEXT_DAY =
  'Una entrega se mueve al mismo día o al siguiente.';
export const RESCHEDULE_TOO_SOON =
  'La nueva franja debe empezar en más de 2 horas.';
export const SKIPPED_BY_RECIPIENT = 'Omitida por quien la recibe.';
export const SKIPPED_UNCONFIRMED = 'No se confirmó 2 horas antes de la franja.';
export const SKIPPED_PAUSED = 'El plan está en pausa.';

type OccurrenceOrder = {
  status: OrderStatus;
  planId: string | null;
  droneId: string | null;
  scheduledAt: Date | null;
  scheduledFor: string | null;
  destinationKind: DestinationKind;
  requesterId: string | null;
  destinationHubId: string | null;
};

/**
 * Con qué estado nace una entrega. Los planes anteriores (sin franja) nacen
 * en recibido, como siempre. Con franja: una central confirma sola y una
 * persona confirma el día antes; si la entrega cae en menos de 24 horas,
 * quien acaba de armar el plan ya la eligió, así que va confirmada.
 */
export function initialOccurrenceState(
  plan: { deliveryTime: string | null; destinationKind: DestinationKind },
  occurrence: Occurrence,
  now: Date,
): { status: OrderStatus; confirmedAt: Date | null } {
  if (!plan.deliveryTime) {
    return { status: OrderStatus.RECEIVED, confirmedAt: null };
  }
  const soon =
    occurrence.scheduledAt.getTime() - now.getTime() <= REMINDER_LEAD_MS;
  if (soon) {
    return { status: OrderStatus.RECEIVED, confirmedAt: now };
  }
  return { status: OrderStatus.SCHEDULED, confirmedAt: null };
}

/** Recibe la persona del pedido, o un despachador de la central de destino. */
export function assertRecipient(user: User, order: OccurrenceOrder): void {
  const isRecipient =
    order.destinationKind === DestinationKind.HUB
      ? user.role === UserRole.DISPATCHER &&
        order.destinationHubId != null &&
        assignedHubIds(user).includes(order.destinationHubId)
      : user.role === UserRole.REQUESTER && order.requesterId === user.id;
  if (!isRecipient) {
    throw new ForbiddenException(NOT_THE_RECIPIENT);
  }
}

/** Hasta 2 horas antes, y mientras no tenga dron, la entrega se cambia. */
export function assertChangeable(order: OccurrenceOrder, now: Date): void {
  if (!order.planId) {
    throw new BadRequestException(ONLY_PLAN_DELIVERIES);
  }
  const start = startOf(order);
  if (
    !NOT_YET_AUTHORIZED.includes(order.status) ||
    order.droneId ||
    !start ||
    start.getTime() - now.getTime() < SCHEDULE_LEAD_MS
  ) {
    throw new BadRequestException(OCCURRENCE_LOCKED);
  }
}

/**
 * Nueva franja de una entrega: el mismo día o el siguiente, a una hora en
 * punto válida y con más de 2 horas de margen.
 */
export function rescheduledSlot(
  order: OccurrenceOrder,
  date: string,
  time: string,
  now: Date,
): Occurrence {
  assertTime(time);
  const original = order.scheduledFor as string;
  if (date !== original && date !== addCalendarDays(original, 1)) {
    throw new BadRequestException(RESCHEDULE_SAME_OR_NEXT_DAY);
  }
  const slot = slotFor(date, time);
  if (slot.scheduledAt.getTime() - now.getTime() < SCHEDULE_LEAD_MS) {
    throw new BadRequestException(RESCHEDULE_TOO_SOON);
  }
  return slot;
}

/** T-24 h: toca avisar a quien recibe. */
export function isReminderDue(order: OccurrenceOrder, now: Date): boolean {
  const start = startOf(order);
  return (
    order.status === OrderStatus.SCHEDULED &&
    start != null &&
    start.getTime() - now.getTime() <= REMINDER_LEAD_MS
  );
}

/** T-2 h sin confirmar (o con el plan en pausa): la entrega se omite. */
export function isPastConfirmation(order: OccurrenceOrder, now: Date): boolean {
  const start = startOf(order);
  return (
    (order.status === OrderStatus.SCHEDULED ||
      order.status === OrderStatus.AWAITING_CONFIRMATION) &&
    start != null &&
    start.getTime() - now.getTime() < SCHEDULE_LEAD_MS
  );
}

/** «jueves 5 de noviembre, de 10:00 a 11:00», en hora de Colombia. */
export function describeSlot(start: Date, end: Date): string {
  const day = new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(start);
  return `${day}, de ${clock(start)} a ${clock(end)}`;
}

/** La hora límite para confirmar (2 horas antes de la franja). */
export function confirmBy(start: Date): string {
  return clock(new Date(start.getTime() - SCHEDULE_LEAD_MS));
}

function clock(date: Date): string {
  return new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(date);
}

function startOf(order: OccurrenceOrder): Date | null {
  if (order.scheduledAt) {
    return order.scheduledAt;
  }
  return order.scheduledFor
    ? slotFor(order.scheduledFor, null).scheduledAt
    : null;
}
