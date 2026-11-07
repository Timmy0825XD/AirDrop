import { ClockView } from '../common/clock/clock.rules';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DecisionTrace } from '../orders/order.entity';
import { FlightAlertKind } from '../simulation/simulation.rules';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { IncidentOutcome } from '../common/enums/incident-outcome.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';

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
  /**
   * `console`: lo hizo el administrador desde la consola. `chaos`: lo
   * sorteó el modo caos (RF-38).
   */
  source: 'system' | 'console' | 'chaos';
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
  /** RF-37: lo autorizó el despachador automático. */
  autoDispatched?: boolean;
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
        title: order.autoDispatched
          ? `${origin} autorizó (despachador automático): sale ${drone}`
          : `${origin} autorizó: sale ${drone}`,
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

export type GeofenceFacts = {
  name: string;
  reason: string;
  polygon: { coordinates: number[][][] };
  createdAt: string;
  expiresAt: string;
};

/** Promedio de los vértices (sin repetir el de cierre): dónde enfocar el mapa. */
export function polygonCenter(polygon: {
  coordinates: number[][][];
}): Position | null {
  const ring = polygon.coordinates[0] ?? [];
  const points = ring.length > 1 ? ring.slice(0, -1) : ring;
  if (!points.length) {
    return null;
  }
  const sum = points.reduce(
    (acc, [lng, lat]) => ({ lng: acc.lng + lng, lat: acc.lat + lat }),
    { lng: 0, lat: 0 },
  );
  return {
    latitude: sum.lat / points.length,
    longitude: sum.lng / points.length,
  };
}

/** RF-36: empezó o terminó una geovalla temporal. */
export function geofenceDraft(
  action: 'created' | 'ended',
  fence: GeofenceFacts,
): TimelineDraft {
  const center = polygonCenter(fence.polygon);
  const base = {
    kind: 'console' as const,
    orderId: null,
    droneId: null,
    hubId: null,
    latitude: center?.latitude ?? null,
    longitude: center?.longitude ?? null,
  };
  if (action === 'ended') {
    return {
      ...base,
      severity: 'success',
      title: `Terminó la geovalla temporal ${fence.name}`,
      detail: 'Las rutas nuevas ya pueden cruzar esa zona.',
      source: 'system',
    };
  }
  const minutes = Math.round(
    (Date.parse(fence.expiresAt) - Date.parse(fence.createdAt)) / 60_000,
  );
  return {
    ...base,
    severity: 'warning',
    title: `Geovalla temporal ${fence.name} por ${minutes} min`,
    detail: `${fence.reason}. Las rutas la rodean y los drones en el aire cambian de camino.`,
    source: 'console',
  };
}

export type IncidentFacts = {
  orderId: string;
  droneId: string;
  hubId: string;
  kind: IncidentKind;
  leg: RouteLeg;
  protocol: ContingencyProtocol;
  outcome: IncidentOutcome;
  latitude: number;
  longitude: number;
  batteryPercent: number;
  landingLatitude: number | null;
  landingLongitude: number | null;
  packageOnBoard: boolean;
};

const INCIDENT_NAME: Record<IncidentKind, string> = {
  [IncidentKind.BATTERY_CRITICAL]: 'batería crítica',
  [IncidentKind.WIND_LIMIT]: 'viento sobre el límite',
  [IncidentKind.ROUTE_BLOCKED]: 'sin camino seguro',
  [IncidentKind.BATTERY_SHORT]: 'la batería no alcanza el desvío',
  [IncidentKind.BATTERY_DEGRADED]: 'batería degradada',
  [IncidentKind.MOTOR_FAILURE]: 'falla de un motor',
  [IncidentKind.DUAL_MOTOR_FAILURE]: 'falla de dos motores',
  [IncidentKind.GPS_LOSS_MINOR]: 'GPS con falla; usa el respaldo',
  [IncidentKind.GPS_LOSS_MAJOR]: 'sin posición confiable',
  [IncidentKind.LINK_LOSS]: 'perdió el enlace',
  [IncidentKind.COOLING_FAILURE]: 'falla de la refrigeración',
  [IncidentKind.COLLISION_MINOR]: 'choque leve',
  [IncidentKind.COLLISION_MAJOR]: 'choque grave',
  [IncidentKind.DRONE_LOST]: 'dron perdido',
};

/** Choque grave o dron perdido: el paquete no se recupera (RF-34). */
function packageLost(kind: IncidentKind): boolean {
  return (
    kind === IncidentKind.COLLISION_MAJOR || kind === IncidentKind.DRONE_LOST
  );
}

/**
 * RF-34 y CU-32: el incidente y lo que decidió el sistema, y después en qué
 * quedó. `rescueMinutes` solo para el aterrizaje de emergencia.
 */
export function incidentDraft(
  incident: IncidentFacts,
  identifier: string | null,
  rescueMinutes: number | null = null,
): TimelineDraft {
  const drone = identifier ?? 'El dron';
  const landed = incident.landingLatitude != null;
  const base = {
    kind: 'alert' as const,
    orderId: incident.orderId,
    droneId: incident.droneId,
    hubId: incident.hubId,
    latitude: landed ? incident.landingLatitude : incident.latitude,
    longitude: landed ? incident.landingLongitude : incident.longitude,
    source: 'system' as const,
  };
  const battery = `Batería ${Math.round(incident.batteryPercent)} %.`;
  const what = `${drone}: ${INCIDENT_NAME[incident.kind]}`;
  switch (incident.outcome) {
    case IncidentOutcome.CONTINUED:
      return {
        ...base,
        severity: 'warning',
        title:
          incident.leg === RouteLeg.RETURN
            ? `${what}; sigue hacia la central`
            : `${what}; sigue su misión`,
        detail:
          incident.kind === IncidentKind.COOLING_FAILURE
            ? 'La carga se empieza a calentar: si sale de 2 a 8 °C, queda en cuarentena.'
            : `${battery} Le alcanza con la reserva.`,
      };
    case IncidentOutcome.RETURNING:
      return {
        ...base,
        severity: 'danger',
        title: `${what}; vuelve a la central con el paquete`,
        detail: `${battery} No le alcanza para entregar y volver; al aterrizar sale otro dron.`,
      };
    case IncidentOutcome.LANDING:
      if (incident.protocol === ContingencyProtocol.CRASH) {
        return {
          ...base,
          severity: 'danger',
          title: `${what}; cae donde va`,
          detail: 'Sale el rescate. El dron queda fuera de servicio.',
        };
      }
      return {
        ...base,
        severity: 'danger',
        title: `${what}; aterrizaje de emergencia`,
        detail: `${battery} Baja en el punto más cercano fuera de toda zona.`,
      };
    case IncidentOutcome.GROUNDED:
      return {
        ...base,
        severity: 'warning',
        title:
          incident.protocol === ContingencyProtocol.CRASH
            ? `${drone} cayó por un choque grave`
            : `${drone} aterrizó de emergencia`,
        detail:
          rescueMinutes != null
            ? `El rescate llega en unos ${rescueMinutes} min.`
            : 'Espera el rescate.',
      };
    case IncidentOutcome.RETURNED:
      return {
        ...base,
        severity: 'info',
        title: `${drone} llegó a la central tras el incidente`,
        detail: incident.packageOnBoard
          ? 'El paquete queda en cuarentena.'
          : null,
      };
    case IncidentOutcome.RESCUED:
      if (packageLost(incident.kind)) {
        return {
          ...base,
          severity: 'warning',
          title: `Recuperaron ${drone}: queda fuera de servicio`,
          detail: incident.packageOnBoard ? 'El paquete se perdió.' : null,
        };
      }
      return {
        ...base,
        severity: 'success',
        title: `${drone} rescatado: entra a mantenimiento`,
        detail: incident.packageOnBoard
          ? 'El paquete queda en cuarentena.'
          : null,
      };
    case IncidentOutcome.LOST:
      return {
        ...base,
        severity: 'danger',
        title: `Se perdió el rastro de ${drone}`,
        detail: incident.packageOnBoard
          ? 'Queda fuera de servicio y el paquete se da por perdido.'
          : 'Queda fuera de servicio.',
      };
  }
}

/** RF-36: una central se quedó sin energía, o le volvió. */
export function hubOutageDraft(
  action: 'started' | 'ended',
  outage: { hubId: string; name: string; latitude: number; longitude: number },
  minutes: number | null,
): TimelineDraft {
  const base = {
    kind: 'console' as const,
    orderId: null,
    droneId: null,
    hubId: outage.hubId,
    latitude: outage.latitude,
    longitude: outage.longitude,
  };
  if (action === 'ended') {
    return {
      ...base,
      severity: 'success',
      title: `Volvió la energía a ${outage.name}`,
      detail: 'Ya puede autorizar y confirmar cargas.',
      source: 'system',
    };
  }
  return {
    ...base,
    severity: 'danger',
    title:
      minutes != null
        ? `${outage.name} sin energía por ${minutes} min`
        : `${outage.name} sin energía`,
    detail:
      'No autoriza ni carga: sus urgencias pasan a otra central y sus programados se reintentan en la franja.',
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
