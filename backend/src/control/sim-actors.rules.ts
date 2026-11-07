import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DispatchOffer } from '../orders/order.entity';
import { addCalendarDays, todayInColombia } from '../orders/orders.rules';
import { dispatchWindow } from '../orders/plan-dispatch.rules';
import {
  FIRST_SLOT_HOUR,
  LAST_SLOT_HOUR,
  SCHEDULE_LEAD_MS,
  colombiaInstant,
} from '../orders/plan-schedule.rules';

/**
 * RF-37: los actores simulados de la consola. Reglas puras: cuándo le toca
 * a cada uno y qué hace. Quien autoriza, carga, crea pedidos o ingresa el
 * código son los mismos servicios que usa una persona.
 */

/** El despachador automático autoriza 10 s simulados después de que le toca. */
export const AUTHORIZE_DELAY_MS = 10_000;
/** Y confirma la carga 20 s simulados después de autorizar. */
export const LOAD_DELAY_MS = 20_000;
/** Si una orden suya falla (sin lote, sin energía…), espera esto para volver a intentar. */
export const ACTOR_RETRY_MS = 60_000;
/** Cada cuánto revisan los actores (ms simulados). */
export const ACTOR_SWEEP_MS = 5_000;

/** El receptor simulado ingresa el código a tiempo en el 85 % de los pedidos. */
export const RECEIVER_ON_TIME_RATE = 0.85;
/** Lo ingresa entre 20 s y 2 min simulados después del aterrizaje. */
export const RECEIVER_MIN_DELAY_MS = 20_000;
export const RECEIVER_MAX_DELAY_MS = 120_000;

/** Flujo continuo: un pedido cada 3 min simulados, 70 % urgencias. */
export const ORDER_FLOW_EVERY_MS = 3 * 60_000;
export const FLOW_EMERGENCY_SHARE = 0.7;

/** Pico de urgencias (RF-36): de 2 a 15 seguidas en una zona del mapa. */
export const SURGE_MIN = 2;
export const SURGE_MAX = 15;
export const SURGE_MIN_RADIUS_KM = 0.3;
export const SURGE_MAX_RADIUS_KM = 3;

/** Unidades de un programado generado. */
export const SCHEDULED_MIN_QUANTITY = 1;
export const SCHEDULED_MAX_QUANTITY = 3;

export const ACTORS_STATE_KEY = 'control:actors';

export const NO_SIMULATED_STOCK =
  'Ninguna central tiene en stock un insumo de venta libre para el generador.';
export const NO_SIMULATED_DESTINATION =
  'El generador no encontró un destino fuera de las geovallas.';

/** Un número en [0, 1), como `Math.random`; los tests pasan uno fijo. */
export type Random = () => number;

export type ActorsState = {
  /** Autoriza y confirma la carga en cualquier central activa. */
  autoDispatcher: boolean;
  /** Crea un pedido cada `ORDER_FLOW_EVERY_MS`. */
  orderFlow: boolean;
};

/** Los dos arrancan apagados, y el reinicio los vuelve a apagar. */
export const ACTORS_OFF: ActorsState = {
  autoDispatcher: false,
  orderFlow: false,
};

export type ActorsChange = Partial<ActorsState>;

export type GeneratedKind = 'emergency' | 'scheduled';

export function parseActorsState(raw: string | null): ActorsState {
  if (!raw) {
    return { ...ACTORS_OFF };
  }
  try {
    const value = JSON.parse(raw) as Partial<ActorsState>;
    return {
      autoDispatcher: value.autoDispatcher === true,
      orderFlow: value.orderFlow === true,
    };
  } catch {
    return { ...ACTORS_OFF };
  }
}

export function applyActorsChange(
  state: ActorsState,
  change: ActorsChange,
): ActorsState {
  return {
    autoDispatcher: change.autoDispatcher ?? state.autoDispatcher,
    orderFlow: change.orderFlow ?? state.orderFlow,
  };
}

/** Lo que cambió, dicho para la línea de tiempo. */
export function actorsChangeText(
  before: ActorsState,
  after: ActorsState,
): string[] {
  const lines: string[] = [];
  if (before.autoDispatcher !== after.autoDispatcher) {
    lines.push(
      after.autoDispatcher
        ? 'Despachador automático encendido'
        : 'Despachador automático apagado',
    );
  }
  if (before.orderFlow !== after.orderFlow) {
    lines.push(
      after.orderFlow
        ? 'Flujo continuo de pedidos encendido'
        : 'Flujo continuo de pedidos apagado',
    );
  }
  return lines;
}

type AwaitingOrder = {
  status: OrderStatus;
  fallbackKind: FallbackKind | null;
  droneId: string | null;
};

/**
 * Lo que el despachador automático autoriza: lo que espera a una central
 * (como `isAwaitingHub`), sin dron todavía. El programado que espera dron
 * lo reintenta `ScheduledRetryService`, no el actor.
 */
export function awaitsAutoAuthorization(order: AwaitingOrder): boolean {
  if (order.droneId != null || order.fallbackKind === FallbackKind.RETRY) {
    return false;
  }
  return (
    order.status === OrderStatus.RECEIVED ||
    (order.status === OrderStatus.REASSIGNED &&
      order.fallbackKind === FallbackKind.HUB)
  );
}

type TurnOrder = {
  missionType: MissionType;
  createdAt: Date;
  reassignedAt: Date | null;
  dispatchOffers: DispatchOffer[] | null;
  scheduledAt?: Date | null;
  windowEndsAt?: Date | null;
  scheduledFor: string | null;
  fallbackKind: FallbackKind | null;
  reassignedFromHubId: string | null;
};

function activeOffer(
  offers: DispatchOffer[] | null,
  hubId: string,
): DispatchOffer | undefined {
  return offers?.find(
    (offer) =>
      offer.hubId === hubId &&
      offer.offeredAt != null &&
      offer.declinedAt == null,
  );
}

/**
 * Desde cuándo le toca a esa central: la urgencia, desde que se le ofreció;
 * lo reasignado, desde la reasignación; el programado, desde que abre su
 * ventana de despacho. Lo demás, desde que se creó.
 */
export function turnStartedAt(order: TurnOrder, hubId: string): Date {
  const offer = activeOffer(order.dispatchOffers, hubId);
  if (offer?.offeredAt) {
    return new Date(offer.offeredAt);
  }
  let since = order.createdAt.getTime();
  if (order.reassignedAt) {
    since = Math.max(since, order.reassignedAt.getTime());
  }
  const window =
    order.missionType === MissionType.SCHEDULED ? dispatchWindow(order) : null;
  if (window) {
    since = Math.max(since, window.opensAt.getTime());
  }
  return new Date(since);
}

export function isDue(since: Date, delayMs: number, now: Date): boolean {
  return now.getTime() - since.getTime() >= delayMs;
}

type HubPoint = { id: string; latitude: number; longitude: number };

/**
 * Qué central autoriza, entre las que tienen el pedido en su cola: la urgencia
 * escalonada, la que se le ofreció primero; si no, la más cercana al destino.
 */
export function pickAuthorizingHub(
  order: {
    latitude: number | null;
    longitude: number | null;
    dispatchOffers: DispatchOffer[] | null;
  },
  candidates: HubPoint[],
): string | null {
  if (!candidates.length) {
    return null;
  }
  const offered = candidates
    .map((hub) => ({ hub, offer: activeOffer(order.dispatchOffers, hub.id) }))
    .filter((row) => row.offer?.offeredAt)
    .sort(
      (a, b) =>
        Date.parse(a.offer?.offeredAt as string) -
        Date.parse(b.offer?.offeredAt as string),
    );
  if (offered.length) {
    return offered[0].hub.id;
  }
  if (order.latitude == null || order.longitude == null) {
    return candidates[0].id;
  }
  const target = { latitude: order.latitude, longitude: order.longitude };
  return [...candidates].sort(
    (a, b) => squaredDistance(a, target) - squaredDistance(b, target),
  )[0].id;
}

function squaredDistance(
  a: { latitude: number; longitude: number },
  b: { latitude: number; longitude: number },
): number {
  const dLat = a.latitude - b.latitude;
  const dLng = a.longitude - b.longitude;
  return dLat * dLat + dLng * dLng;
}

/**
 * Cuándo ingresa el código el receptor simulado, contado desde que el dron
 * aterrizó, o `null` si esta vez lo deja vencer (RF-30).
 */
export function receiverCodeAt(landedAt: Date, random: Random): Date | null {
  if (random() >= RECEIVER_ON_TIME_RATE) {
    return null;
  }
  const delay =
    RECEIVER_MIN_DELAY_MS +
    random() * (RECEIVER_MAX_DELAY_MS - RECEIVER_MIN_DELAY_MS);
  return new Date(landedAt.getTime() + Math.round(delay));
}

/**
 * La primera franja (en punto, de 7:00 a 17:00, hora de Colombia) que
 * empieza al menos 2 horas después: lo mínimo para agendar (RU-30).
 */
export function nextScheduledSlot(now: Date): { date: string; time: string } {
  const today = todayInColombia(now);
  for (const date of [today, addCalendarDays(today, 1)]) {
    for (let hour = FIRST_SLOT_HOUR; hour <= LAST_SLOT_HOUR; hour += 1) {
      const time = `${String(hour).padStart(2, '0')}:00`;
      const start = colombiaInstant(date, time).getTime();
      // Un minuto de margen: entre este cálculo y el guardado corre el reloj.
      if (start - now.getTime() >= SCHEDULE_LEAD_MS + 60_000) {
        return { date, time };
      }
    }
  }
  return { date: addCalendarDays(today, 1), time: '07:00' };
}

export function flowKind(random: Random): GeneratedKind {
  return random() < FLOW_EMERGENCY_SHARE ? 'emergency' : 'scheduled';
}

export function pickOne<T>(items: readonly T[], random: Random): T {
  return items[Math.min(items.length - 1, Math.floor(random() * items.length))];
}

export function randomQuantity(random: Random): number {
  const span = SCHEDULED_MAX_QUANTITY - SCHEDULED_MIN_QUANTITY + 1;
  return (
    SCHEDULED_MIN_QUANTITY + Math.min(span - 1, Math.floor(random() * span))
  );
}

const KM_PER_DEGREE = 111.32;

/**
 * Un punto al azar dentro del círculo (uniforme en el área), redondeado a
 * 6 decimales como pide la validación de coordenadas.
 */
export function scatterAround(
  center: { latitude: number; longitude: number },
  radiusKm: number,
  random: Random,
): { latitude: number; longitude: number } {
  const distance = radiusKm * Math.sqrt(random());
  const angle = random() * 2 * Math.PI;
  const dLat = (distance * Math.cos(angle)) / KM_PER_DEGREE;
  const dLng =
    (distance * Math.sin(angle)) /
    (KM_PER_DEGREE * Math.cos((center.latitude * Math.PI) / 180));
  return {
    latitude: round6(center.latitude + dLat),
    longitude: round6(center.longitude + dLng),
  };
}

function round6(value: number): number {
  return Math.round(value * 1e6) / 1e6;
}
