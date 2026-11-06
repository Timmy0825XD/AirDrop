import { ClockView } from '../common/clock/clock.rules';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DecisionTrace } from '../orders/order.entity';
import { FlightAlertKind } from '../simulation/simulation.rules';
import { WeatherKind } from '../common/enums/weather-kind.enum';

/**
 * RF-39: cada paso del flujo, contado para la TV. No lleva datos de personas
 * ni el medicamento de una entrega a una persona (RNF-05).
 */

export const TIMELINE_KEY = 'control:timeline';
/** Entradas que se guardan en Redis; más viejas se descartan. */
export const TIMELINE_MAX = 200;
export const TIMELINE_DEFAULT_LIMIT = 50;

export type TimelineKind =
  | 'order'
  | 'queue'
  | 'decision'
  | 'flight'
  | 'delivery'
  | 'fallback'
  | 'alert'
  | 'console';

export type TimelineSeverity = 'info' | 'success' | 'warning' | 'danger';

export type TimelineEntry = {
  id: string;
  /** Hora simulada (RF-31), en ISO. */
  at: string;
  kind: TimelineKind;
  severity: TimelineSeverity;
  title: string;
  detail: string | null;
  orderId: string | null;
  droneId: string | null;
  hubId: string | null;
  latitude: number | null;
  longitude: number | null;
  /** `console`: lo hizo el administrador desde la consola. */
  source: 'system' | 'console';
};

export type TimelineDraft = Omit<TimelineEntry, 'id' | 'at'>;

/** Lo que se sabe del pedido al contar un paso. Nada que identifique a nadie. */
export type OrderFacts = {
  id: string;
  missionType: MissionType;
  destinationKind: DestinationKind;
  medicationName: string;
  fallbackKind: FallbackKind | null;
  originHub: { id: string; name: string } | null;
  destinationHubName: string | null;
  drone: { id: string; identifier: string } | null;
  decisionTrace: DecisionTrace | null;
};

export type Position = { latitude: number; longitude: number };

export function missionLabel(
  missionType: MissionType,
  destinationKind: DestinationKind,
): string {
  const toHub = destinationKind === DestinationKind.HUB;
  if (missionType === MissionType.EMERGENCY) {
    return toHub ? 'Urgencia entre centrales' : 'Urgencia a una persona';
  }
  return toHub ? 'Abastecimiento programado' : 'Entrega programada';
}

/** A dónde va, sin decir a quién. El insumo solo si el destino es una central. */
export function destinationText(order: OrderFacts): string {
  if (order.destinationKind === DestinationKind.HUB) {
    const hub = order.destinationHubName ?? 'otra central';
    return `${order.medicationName} hacia ${hub}`;
  }
  return 'hacia una persona';
}

/**
 * RF-11 en una línea: qué dron eligió el motor y por qué descartó a los
 * demás. Sale de la traza ya guardada; no vuelve a calcular nada.
 */
export function decisionSummary(trace: DecisionTrace | null): string | null {
  if (!trace) {
    return null;
  }
  const drones = trace.hubs.flatMap((hub) => hub.drones);
  const chosen = drones.find((drone) => drone.status === 'chosen');
  const discarded = drones.filter((drone) => drone.status === 'discarded');
  const parts: string[] = [];
  if (chosen) {
    parts.push(
      chosen.preempts
        ? `Eligió ${chosen.identifier}, que tenía un programado: la urgencia gana el dron.`
        : `Eligió ${chosen.identifier}.`,
    );
  }
  const eligible = drones.filter((drone) => drone.status === 'eligible').length;
  if (eligible) {
    parts.push(
      eligible === 1
        ? '1 dron más podía salir.'
        : `${eligible} drones más podían salir.`,
    );
  }
  if (discarded.length) {
    const reasons = discarded
      .map((drone) =>
        drone.reason
          ? `${drone.identifier} (${lowerFirst(stripPeriod(drone.reason))})`
          : drone.identifier,
      )
      .join(', ');
    parts.push(`Descartó ${reasons}.`);
  }
  if (!parts.length && trace.reason) {
    parts.push(trace.reason);
  }
  return parts.length ? parts.join(' ') : null;
}

/** Un cambio de estado del pedido, o `null` si no vale la pena contarlo. */
export function statusDraft(
  status: OrderStatus,
  order: OrderFacts,
  position: Position | null,
): TimelineDraft | null {
  const label = missionLabel(order.missionType, order.destinationKind);
  const drone = order.drone?.identifier ?? 'El dron';
  const origin = order.originHub?.name ?? 'la central';
  const base = {
    orderId: order.id,
    droneId: order.drone?.id ?? null,
    hubId: order.originHub?.id ?? null,
    latitude: position?.latitude ?? null,
    longitude: position?.longitude ?? null,
    source: 'system' as const,
  };
  switch (status) {
    case OrderStatus.RECEIVED:
      return {
        ...base,
        kind: 'order',
        severity: 'info',
        title: `${label} recibida`,
        detail: capitalize(destinationText(order)),
      };
    case OrderStatus.PENDING_LOAD:
      return {
        ...base,
        kind: 'decision',
        severity: 'info',
        title: `${origin} autorizó: sale ${drone}`,
        detail: decisionSummary(order.decisionTrace),
      };
    case OrderStatus.IN_FLIGHT:
      return {
        ...base,
        kind: 'flight',
        severity: 'info',
        title: `Carga confirmada: despegó ${drone}`,
        detail: `Desde ${origin}, ${destinationText(order)}`,
      };
    case OrderStatus.AWAITING_DELIVERY:
      return {
        ...base,
        kind: 'delivery',
        severity: 'info',
        title: `${drone} aterrizó y espera el código`,
        detail: 'Tiene 5 minutos para recibir el código de entrega.',
      };
    case OrderStatus.DELIVERED:
      return {
        ...base,
        kind: 'delivery',
        severity: 'success',
        title: `${label} entregada`,
        detail: `${drone} vuelve vacío a ${origin}.`,
      };
    case OrderStatus.RETURNING:
      return {
        ...base,
        kind: 'delivery',
        severity: 'warning',
        title: `${drone} vuelve con el paquete`,
        detail: 'No llegó un código válido a tiempo.',
      };
    case OrderStatus.RETURNED:
      return {
        ...base,
        kind: 'delivery',
        severity: 'warning',
        title: `${drone} volvió con el paquete a ${origin}`,
        detail: 'El insumo pasa por la cuarentena antes de reingresar.',
      };
    case OrderStatus.REASSIGNED:
      return {
        ...base,
        kind: 'fallback',
        severity: 'warning',
        title:
          order.fallbackKind === FallbackKind.CONVENTIONAL
            ? `${label}: traslado convencional`
            : `${label} reasignada a ${origin}`,
        detail:
          order.fallbackKind === FallbackKind.CONVENTIONAL
            ? 'Ningún dron puede llegar: se ofrecen centrales con el insumo.'
            : decisionSummary(order.decisionTrace),
      };
    case OrderStatus.REJECTED:
      return {
        ...base,
        kind: 'order',
        severity: 'danger',
        title: `${label} rechazada por ${origin}`,
        detail: null,
      };
    case OrderStatus.EXPIRED:
      return {
        ...base,
        kind: 'fallback',
        severity: 'warning',
        title: `${label}: la franja cerró sin despegue`,
        detail: null,
      };
    default:
      return null;
  }
}

/**
 * El dron aterrizó en su central tras entregar: el pedido ya no cambia de
 * estado, así que este es el único aviso de que el vuelo terminó.
 */
export function homeDraft(
  order: OrderFacts,
  position: Position | null,
): TimelineDraft {
  const drone = order.drone?.identifier ?? 'El dron';
  return {
    kind: 'flight',
    severity: 'success',
    title: `${drone} volvió vacío a ${order.originHub?.name ?? 'su central'}`,
    detail: 'Queda disponible para otra misión.',
    orderId: order.id,
    droneId: order.drone?.id ?? null,
    hubId: order.originHub?.id ?? null,
    latitude: position?.latitude ?? null,
    longitude: position?.longitude ?? null,
    source: 'system',
  };
}

/** Lo que la línea de tiempo necesita de una celda de clima. */
export type WeatherFacts = {
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  windSpeedMs: number | null;
  windFromDeg: number | null;
  startsAt: string;
  endsAt: string;
};

const WEATHER_NAME: Record<WeatherKind, string> = {
  [WeatherKind.WIND]: 'Viento',
  [WeatherKind.RAIN]: 'Lluvia',
  [WeatherKind.STORM]: 'Tormenta',
};

const WEATHER_ENDED: Record<WeatherKind, string> = {
  [WeatherKind.WIND]: 'Se calmó el viento',
  [WeatherKind.RAIN]: 'Paró la lluvia',
  [WeatherKind.STORM]: 'Pasó la tormenta',
};

const COMPASS = [
  'norte',
  'noreste',
  'este',
  'sureste',
  'sur',
  'suroeste',
  'oeste',
  'noroeste',
];

/** "del noreste": de dónde sopla, en ocho rumbos. */
export function windFrom(degrees: number): string {
  return `del ${COMPASS[Math.round((((degrees % 360) + 360) % 360) / 45) % 8]}`;
}

/** RF-32: empezó o terminó una celda de clima. */
export function weatherDraft(
  action: 'created' | 'ended',
  cell: WeatherFacts,
): TimelineDraft {
  const name = WEATHER_NAME[cell.kind];
  const radius = cell.radiusKm.toLocaleString('es-CO', {
    maximumFractionDigits: 1,
  });
  const base = {
    kind: 'console' as const,
    orderId: null,
    droneId: null,
    hubId: null,
    latitude: cell.latitude,
    longitude: cell.longitude,
  };
  if (action === 'ended') {
    return {
      ...base,
      severity: 'success',
      title: WEATHER_ENDED[cell.kind],
      detail: null,
      source: 'system',
    };
  }
  const minutes = Math.round(
    (Date.parse(cell.endsAt) - Date.parse(cell.startsAt)) / 60_000,
  );
  const wind =
    cell.kind === WeatherKind.WIND && cell.windSpeedMs != null
      ? ` de ${cell.windSpeedMs.toLocaleString('es-CO', { maximumFractionDigits: 1 })} m/s${
          cell.windFromDeg != null ? ` ${windFrom(cell.windFromDeg)}` : ''
        }`
      : '';
  return {
    ...base,
    severity: cell.kind === WeatherKind.STORM ? 'danger' : 'warning',
    title: `${name}${wind} en ${radius} km por ${minutes} min`,
    detail:
      cell.kind === WeatherKind.STORM
        ? 'Zona no volable: las rutas la rodean y los drones en el aire cambian de camino.'
        : cell.kind === WeatherKind.RAIN
          ? 'Se vuela con un 10 % más de consumo.'
          : 'En contra frena al dron y gasta más; a favor, al revés.',
    source: 'console',
  };
}

/** RF-33: la ruta cambió en vuelo, o no quedó una segura. */
export function rerouteDraft(
  order: OrderFacts,
  change: {
    outcome: 'rerouted' | 'blocked';
    addedKm: number | null;
    crossesGeofence: boolean;
    batteryShort: boolean;
  },
  position: Position | null,
): TimelineDraft {
  const drone = order.drone?.identifier ?? 'El dron';
  const base = {
    kind: 'flight' as const,
    orderId: order.id,
    droneId: order.drone?.id ?? null,
    hubId: order.originHub?.id ?? null,
    latitude: position?.latitude ?? null,
    longitude: position?.longitude ?? null,
    source: 'system' as const,
  };
  if (change.outcome === 'blocked') {
    return {
      ...base,
      severity: 'danger',
      title: `${drone} no tiene una ruta segura`,
      detail:
        'Una zona nueva le cierra el camino y no hay un corredor que la rodee.',
    };
  }
  const notes = [routeLengthNote(change.addedKm)];
  if (change.crossesGeofence) {
    notes.push('Tuvo que cruzar la zona: quedó dentro o su destino también.');
  }
  if (change.batteryShort) {
    notes.push('Por el camino nuevo la batería no alcanza con la reserva.');
  }
  return {
    ...base,
    severity:
      change.crossesGeofence || change.batteryShort ? 'danger' : 'warning',
    title: `${drone} cambió de ruta`,
    detail: notes.join(' '),
  };
}

function routeLengthNote(addedKm: number | null): string {
  if (addedKm == null || Math.abs(addedKm) < 0.05) {
    return 'Una zona nueva cruzaba su camino.';
  }
  const km = Math.abs(addedKm).toLocaleString('es-CO', {
    maximumFractionDigits: 1,
  });
  return addedKm > 0
    ? `Una zona nueva cruzaba su camino: el desvío suma ${km} km.`
    : `Una zona nueva cruzaba su camino: el nuevo es ${km} km más corto.`;
}

/** RU-10: la urgencia entró a la cola de una central. */
export function queueDraft(
  order: OrderFacts,
  hub: { id: string; name: string },
  position: Position | null,
): TimelineDraft {
  return {
    kind: 'queue',
    severity: 'info',
    title: `${missionLabel(order.missionType, order.destinationKind)} en la cola de ${hub.name}`,
    detail: null,
    orderId: order.id,
    droneId: null,
    hubId: hub.id,
    latitude: position?.latitude ?? null,
    longitude: position?.longitude ?? null,
    source: 'system',
  };
}

const ALERT_TITLES: Record<FlightAlertKind, string> = {
  battery_critical: 'Batería crítica',
  failure: 'Falla de batería',
  cold_chain: 'Carga fuera de 2 a 8 °C',
  wind_limit: 'Viento sobre el límite',
};

export function alertDraft(
  kind: FlightAlertKind,
  message: string,
  order: { id: string; hubId: string | null },
  drone: { id: string; identifier: string } | null,
  position: Position | null,
): TimelineDraft {
  return {
    kind: 'alert',
    severity: 'danger',
    title: `${ALERT_TITLES[kind]} en ${drone?.identifier ?? 'un dron'}`,
    detail: message,
    orderId: order.id,
    droneId: drone?.id ?? null,
    hubId: order.hubId,
    latitude: position?.latitude ?? null,
    longitude: position?.longitude ?? null,
    source: 'system',
  };
}

export function clockDraft(clock: ClockView): TimelineDraft {
  return {
    kind: 'console',
    severity: 'info',
    title: clock.paused ? 'Reloj en pausa' : `Reloj a x${clock.speed}`,
    detail: null,
    orderId: null,
    droneId: null,
    hubId: null,
    latitude: null,
    longitude: null,
    source: 'console',
  };
}

/** Las más recientes primero; un `limit` raro cae al valor por defecto. */
export function clampTimelineLimit(raw: unknown): number {
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 1) {
    return TIMELINE_DEFAULT_LIMIT;
  }
  return Math.min(value, TIMELINE_MAX);
}

function stripPeriod(text: string): string {
  return text.trim().replace(/\.$/, '');
}

function lowerFirst(text: string): string {
  return text.charAt(0).toLowerCase() + text.slice(1);
}

function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
