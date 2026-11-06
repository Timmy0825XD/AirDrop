import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import {
  LngLat,
  PlannedCorridor,
  haversineKm,
  isInsideGeofence,
  planCorridor,
  splitCorridorAt,
} from '../routing/routing.rules';
import type { IncidentSeverity } from './flight-incident.entity';
import {
  CRITICAL_BATTERY_PERCENT,
  DESCENT_BATTERY_PERCENT,
  LANDING_BATTERY_PERCENT,
  cruiseBatteryPercent,
  legBatteryPercent,
} from './flight-energy.rules';
import { FlightPhase } from './simulation.rules';

/**
 * RF-34 y CU-32: qué hace el dron después de un incidente. Reglas puras: el
 * reloj de vuelo las consulta y aplica lo que deciden.
 */

/**
 * En batería crítica la reserva del 20 % ya se gastó: basta con llegar con
 * este margen para bajar y aterrizar (decisión del 2026-11-06).
 */
export const LANDING_MARGIN_PERCENT = 5;

/** El rescate sale por tierra desde la central a esta velocidad. */
export const RESCUE_SPEED_KMH = 30;
/** Lo que tarda el equipo en recoger el dron donde bajó. */
export const RESCUE_PICKUP_MS = 10 * 60_000;

/** Cuánto se aleja el aterrizaje del borde de la zona que lo atrapa. */
export const LANDING_CLEARANCE_KM = 0.1;

/** Bajando ya, el dron termina de bajar: no hay otro protocolo que aplicar. */
const LANDING_PHASES = new Set<FlightPhase>([
  FlightPhase.DESCENT,
  FlightPhase.LANDING,
  FlightPhase.LANDED,
  FlightPhase.UNLOADING,
]);

/** Los leves dejan seguir con alerta o degradan el vuelo; los graves no. */
const MINOR_INCIDENTS = new Set<IncidentKind>([
  IncidentKind.BATTERY_SHORT,
  IncidentKind.BATTERY_DEGRADED,
  IncidentKind.MOTOR_FAILURE,
  IncidentKind.GPS_LOSS_MINOR,
  IncidentKind.COOLING_FAILURE,
  IncidentKind.COLLISION_MINOR,
]);

export function incidentSeverity(kind: IncidentKind): IncidentSeverity {
  return MINOR_INCIDENTS.has(kind) ? 'minor' : 'major';
}

/**
 * RF-34: cuánto cambia el resto del vuelo (decisión del 2026-11-06, efectos
 * moderados). `burnFactor` multiplica el consumo; `speedFactor`, la velocidad.
 */
export type IncidentEffect = { burnFactor: number; speedFactor: number };

export const INCIDENT_EFFECTS: Partial<Record<IncidentKind, IncidentEffect>> = {
  [IncidentKind.BATTERY_DEGRADED]: { burnFactor: 1.25, speedFactor: 1 },
  [IncidentKind.MOTOR_FAILURE]: { burnFactor: 1.15, speedFactor: 0.9 },
  [IncidentKind.COLLISION_MINOR]: { burnFactor: 1.1, speedFactor: 1 },
};

/** Los efectos se acumulan: dos incidentes leves pesan los dos. */
export function applyEffect(
  current: IncidentEffect,
  kind: IncidentKind,
): IncidentEffect {
  const effect = INCIDENT_EFFECTS[kind];
  if (!effect) {
    return current;
  }
  return {
    burnFactor: current.burnFactor * effect.burnFactor,
    speedFactor: current.speedFactor * effect.speedFactor,
  };
}

/** RF-34: los que no dependen del alcance. */
const FIXED_PROTOCOLS: Partial<Record<IncidentKind, ContingencyProtocol>> = {
  [IncidentKind.DUAL_MOTOR_FAILURE]: ContingencyProtocol.EMERGENCY_LANDING,
  [IncidentKind.GPS_LOSS_MAJOR]: ContingencyProtocol.EMERGENCY_LANDING,
  [IncidentKind.GPS_LOSS_MINOR]: ContingencyProtocol.CONTINUE,
  [IncidentKind.COOLING_FAILURE]: ContingencyProtocol.CONTINUE,
};

/** La batería con que tiene que llegar: la reserva, o el margen si ya es crítica. */
export function reserveFor(kind: IncidentKind): number {
  return kind === IncidentKind.BATTERY_CRITICAL
    ? LANDING_MARGIN_PERCENT
    : CRITICAL_BATTERY_PERCENT;
}

/**
 * Con viento sobre el límite, sin camino seguro o sin enlace (procedimiento
 * de enlace perdido: vuelve solo), seguir no es opción.
 */
export function allowsContinuing(kind: IncidentKind): boolean {
  return (
    kind !== IncidentKind.WIND_LIMIT &&
    kind !== IncidentKind.ROUTE_BLOCKED &&
    kind !== IncidentKind.LINK_LOSS
  );
}

export type ContingencyInput = {
  kind: IncidentKind;
  leg: RouteLeg;
  phase: FlightPhase;
  batteryPercent: number;
  /** Batería para terminar el tramo (y volver, si va de ida), sin reserva. `null`: no hay camino. */
  finishPercent: number | null;
  /** Batería para llegar a la central desde donde va, sin reserva. `null`: no hay camino. */
  homePercent: number | null;
};

/**
 * RF-34, "según alcance":
 * 1. Si termina la misión con la reserva, sigue.
 * 2. Si no, pero alcanza a volver a la central con la reserva, vuelve.
 * 3. Si tampoco, aterrizaje de emergencia.
 * De regreso, el paso 1 es llegar a la central.
 * Un dron perdido o un choque grave no dejan elegir; dos motores o el GPS
 * sin respaldo bajan siempre, y el GPS leve o el frío siguen con alerta.
 */
export function chooseProtocol(input: ContingencyInput): ContingencyProtocol {
  if (input.kind === IncidentKind.DRONE_LOST) {
    return ContingencyProtocol.LOST;
  }
  if (input.kind === IncidentKind.COLLISION_MAJOR) {
    return ContingencyProtocol.CRASH;
  }
  if (LANDING_PHASES.has(input.phase)) {
    return ContingencyProtocol.CONTINUE;
  }
  const fixed = FIXED_PROTOCOLS[input.kind];
  if (fixed) {
    return fixed;
  }
  const reserve = reserveFor(input.kind);
  const reaches = (needed: number | null) =>
    needed != null && input.batteryPercent - needed >= reserve;
  if (input.leg === RouteLeg.RETURN) {
    return reaches(input.homePercent)
      ? ContingencyProtocol.CONTINUE
      : ContingencyProtocol.EMERGENCY_LANDING;
  }
  if (allowsContinuing(input.kind) && reaches(input.finishPercent)) {
    return ContingencyProtocol.CONTINUE;
  }
  if (reaches(input.homePercent)) {
    return ContingencyProtocol.RETURN_TO_HUB;
  }
  return ContingencyProtocol.EMERGENCY_LANDING;
}

/** Ya en el aire: lo que falta de crucero, bajar y aterrizar. */
export function percentToLand(km: number, maxRangeKm: number): number {
  return (
    cruiseBatteryPercent(km, maxRangeKm) +
    DESCENT_BATTERY_PERCENT +
    LANDING_BATTERY_PERCENT
  );
}

/** Terminar el tramo en que va y, si es la ida, el regreso entero (RF-11). */
export function percentToFinish(input: {
  remainingKm: number;
  returnKm: number | null;
  maxRangeKm: number;
}): number {
  return (
    percentToLand(input.remainingKm, input.maxRangeKm) +
    (input.returnKm != null
      ? legBatteryPercent(input.returnKm, input.maxRangeKm)
      : 0)
  );
}

/**
 * El camino a la central desde donde va el dron, con las reglas de RF-12.
 * Si el dron quedó dentro de una zona, sale por el camino más corto (RF-33).
 */
export function homeCorridor(
  from: LngLat,
  hub: LngLat,
  polygons: GeoJsonPolygon[],
): PlannedCorridor | null {
  const planned = planCorridor(from, hub, polygons);
  if (planned) {
    return planned;
  }
  const free = polygons.filter((fence) => !isInsideGeofence(from, [fence]));
  return free.length < polygons.length ? planCorridor(from, hub, free) : null;
}

/**
 * RF-34: el punto más cercano fuera de toda geovalla y tormenta. Si el dron
 * está afuera, baja donde va; si no, cruza el borde más cercano y se aleja
 * `LANDING_CLEARANCE_KM`. Con zonas encimadas lo intenta unas veces.
 */
export function safeLandingPoint(
  point: LngLat,
  polygons: GeoJsonPolygon[],
): LngLat {
  let current = point;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    const trapping = polygons.find((fence) =>
      isInsideGeofence(current, [fence]),
    );
    if (!trapping) {
      return current;
    }
    current = stepOutside(current, trapping);
  }
  return current;
}

/**
 * Proyección plana local (km), suficiente para una zona de pocos km: se
 * busca el punto del borde más cercano y se sale por él.
 */
function stepOutside(point: LngLat, polygon: GeoJsonPolygon): LngLat {
  const kmPerLat = 110.574;
  const kmPerLng = 111.32 * Math.cos((point.latitude * Math.PI) / 180);
  const toXY = ([lng, lat]: number[]) => ({
    x: (lng - point.longitude) * kmPerLng,
    y: (lat - point.latitude) * kmPerLat,
  });
  const ring = polygon.coordinates[0] ?? [];
  let best: { x: number; y: number; distance: number } | null = null;
  for (let index = 1; index < ring.length; index += 1) {
    const a = toXY(ring[index - 1]);
    const b = toXY(ring[index]);
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const lengthSq = dx * dx + dy * dy;
    const t =
      lengthSq === 0
        ? 0
        : Math.max(0, Math.min(1, -(a.x * dx + a.y * dy) / lengthSq));
    const x = a.x + t * dx;
    const y = a.y + t * dy;
    const distance = Math.hypot(x, y);
    if (!best || distance < best.distance) {
      best = { x, y, distance };
    }
  }
  if (!best) {
    return point;
  }
  const scale =
    best.distance > 0
      ? (best.distance + LANDING_CLEARANCE_KM) / best.distance
      : 1;
  return {
    longitude: point.longitude + (best.x * scale) / kmPerLng,
    latitude: point.latitude + (best.y * scale) / kmPerLat,
  };
}

/** Rescate según distancia: sale de la central por tierra y recoge el dron. */
export function rescueDurationMs(hub: LngLat, landing: LngLat): number {
  const km = haversineKm(hub, landing);
  return Math.round((km / RESCUE_SPEED_KMH) * 3_600_000) + RESCUE_PICKUP_MS;
}

/**
 * Corredor corto hasta el punto de aterrizaje, después de lo ya volado: el
 * dron sigue su crucero desde `cruiseKm` y baja al final.
 */
export function emergencyCorridor(
  corridor: PlannedCorridor,
  cruiseKm: number,
  landing: LngLat,
): PlannedCorridor {
  const split = splitCorridorAt(corridor, cruiseKm);
  return {
    altitudeM: corridor.altitudeM,
    distanceKm: cruiseKm + haversineKm(split.at, landing),
    coordinates: [...split.flown, [landing.longitude, landing.latitude]],
  };
}
