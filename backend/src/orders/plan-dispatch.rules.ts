import { BadRequestException } from '@nestjs/common';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { SCHEDULE_LEAD_MS, slotFor } from './plan-schedule.rules';
import { describeSlot } from './plan-occurrence.rules';

export const DISPATCH_TOO_EARLY =
  'Esta entrega se despacha desde 2 horas antes de la franja.';
export const WINDOW_CLOSED = 'La franja de esta entrega ya cerró.';
export const WINDOW_MISSED = 'La franja cerró sin despegue.';

/** Crucero del Wingcopter 198 si la central todavía no tiene un dron. */
export const DEFAULT_CRUISE_KMH = 150;

/** Todavía no despegó: al cerrar la franja entra el fallback. */
export const MISSED_STATUSES = [
  OrderStatus.RECEIVED,
  OrderStatus.UNDER_REVIEW,
  OrderStatus.ASSIGNED,
  OrderStatus.PENDING_LOAD,
];

export const SLOT_LOAD = [
  OrderStatus.SCHEDULED,
  OrderStatus.AWAITING_CONFIRMATION,
  OrderStatus.RECEIVED,
  OrderStatus.UNDER_REVIEW,
  OrderStatus.ASSIGNED,
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
];

export type DispatchOrder = {
  missionType: MissionType;
  fallbackKind?: FallbackKind | null;
  reassignedFromHubId?: string | null;
  scheduledFor?: string | null;
  scheduledAt?: Date | null;
  windowEndsAt?: Date | null;
};

export type DispatchWindow = {
  opensAt: Date;
  closesAt: Date;
};

export type AgendaEntry = {
  time: string;
  status: OrderStatus;
  confirmed: boolean;
  stockOk: boolean;
  prescriptionValid: boolean | null;
  departBefore: string | null;
  availableQuantity: number;
};

export type AgendaSlot = {
  time: string;
  deliveries: number;
  overCapacity: boolean;
  orders: AgendaEntry[];
};

/** Franja en la que se autoriza y se carga. Sin hora, es el día operativo. */
export function dispatchWindow(order: DispatchOrder): DispatchWindow | null {
  if (order.missionType !== MissionType.SCHEDULED) {
    return null;
  }
  if (order.scheduledAt && order.windowEndsAt) {
    return {
      opensAt: new Date(order.scheduledAt.getTime() - SCHEDULE_LEAD_MS),
      closesAt: order.windowEndsAt,
    };
  }
  if (!order.scheduledFor) {
    return null;
  }
  const slot = slotFor(order.scheduledFor, null);
  return {
    opensAt: new Date(slot.scheduledAt.getTime() - SCHEDULE_LEAD_MS),
    closesAt: slot.windowEndsAt,
  };
}

/**
 * La central que recibe el fallback autoriza y carga aunque la franja
 * original ya haya cerrado: esa salida ya no es la del plan.
 */
export function skipsDispatchWindow(order: DispatchOrder): boolean {
  return (
    order.fallbackKind === FallbackKind.HUB || order.reassignedFromHubId != null
  );
}

export function assertDispatchWindow(order: DispatchOrder, now: Date): void {
  if (skipsDispatchWindow(order)) {
    return;
  }
  const window = dispatchWindow(order);
  if (!window) {
    return;
  }
  if (now.getTime() < window.opensAt.getTime()) {
    throw new BadRequestException(DISPATCH_TOO_EARLY);
  }
  if (now.getTime() >= window.closesAt.getTime()) {
    throw new BadRequestException(WINDOW_CLOSED);
  }
}

export function isWindowClosed(order: DispatchOrder, now: Date): boolean {
  if (skipsDispatchWindow(order)) {
    return false;
  }
  const window = dispatchWindow(order);
  return window != null && now.getTime() >= window.closesAt.getTime();
}

export function isMissedDeparture(
  order: DispatchOrder & {
    status: OrderStatus;
    loadConfirmedAt: Date | null;
  },
  now: Date,
): boolean {
  return (
    order.loadConfirmedAt == null &&
    MISSED_STATUSES.includes(order.status) &&
    isWindowClosed(order, now)
  );
}

/** Hay que despegar a más tardar a esta hora para aterrizar al cerrar. */
export function departBefore(closesAt: Date, etaMs: number): Date {
  return new Date(closesAt.getTime() - etaMs);
}

export function colombiaClock(date: Date): string {
  return new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(date);
}

/** `null` si el ítem no pide fórmula. Sin fecha de vigencia, se toma por vigente. */
export function prescriptionStillValid(
  saleType: SaleType,
  validUntil: string | null,
  date: string,
): boolean | null {
  if (saleType !== SaleType.PRESCRIPTION) {
    return null;
  }
  if (!validUntil) {
    return true;
  }
  return validUntil >= date;
}

export function buildAgenda(
  drones: number,
  orders: AgendaEntry[],
): { drones: number; slots: AgendaSlot[] } {
  const groups = new Map<string, AgendaEntry[]>();
  for (const order of orders) {
    const group = groups.get(order.time) ?? [];
    group.push(order);
    groups.set(order.time, group);
  }
  const slots = [...groups.entries()].map(([time, rows]) => {
    const deliveries = rows.filter((row) => SLOT_LOAD.includes(row.status)).length;
    return {
      time,
      deliveries,
      overCapacity: deliveries > drones,
      orders: rows,
    };
  });
  return { drones, slots };
}

export function departureCopy(
  arrival: Date,
  toHub: boolean,
): { title: string; body: string } {
  const time = colombiaClock(arrival);
  if (toHub) {
    return {
      title: 'Salió un abastecimiento programado',
      body: `Ya va en camino. Llega a tu central alrededor de las ${time}.`,
    };
  }
  return {
    title: 'Tu entrega programada salió',
    body: `Ya va en camino. Llega alrededor de las ${time}.`,
  };
}

export function missedCopy(
  start: Date,
  end: Date,
  movedToHub: boolean,
): { title: string; body: string } {
  const slot = describeSlot(start, end);
  return {
    title: 'Una entrega programada no despegó',
    body: movedToHub
      ? `La entrega del ${slot} no despegó. Otra central puede sacarla.`
      : `La entrega del ${slot} no despegó. Toca un traslado convencional.`,
  };
}
