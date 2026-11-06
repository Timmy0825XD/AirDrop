import { GeoJsonPolygon } from '../geofences/geofences.rules';
import {
  inflateRing,
  isInsideZone,
  projectionAround,
  segmentEntersZone,
  shortestVisiblePath,
} from './visibility.rules';

/** RF-12: el corredor va a una altitud fija, tanto de ida como de regreso. */
export const CORRIDOR_ALTITUDE_M = 100;

/** RF-21: el corredor pasa a 150 m o más del borde de cualquier geovalla. */
export const GEOFENCE_MARGIN_KM = 0.15;

const EARTH_RADIUS_KM = 6371;

export const DESTINATION_IN_GEOFENCE =
  'El destino está dentro de una zona prohibida para drones. Elige otro punto de entrega.';

export type LngLat = {
  longitude: number;
  latitude: number;
};

export type PlannedCorridor = {
  altitudeM: number;
  distanceKm: number;
  coordinates: Array<[number, number]>;
};

/**
 * RF-12: el corredor más corto de `origin` a `destination` que no entra en
 * ninguna geovalla ni en su margen. Si la línea recta está libre, es ella; si
 * no, A* (Dijkstra guiado) sobre las esquinas de las geovallas infladas. `null` si un
 * extremo está dentro de una geovalla o si no existe camino.
 */
export function planCorridor(
  origin: LngLat,
  destination: LngLat,
  geofences: GeoJsonPolygon[],
): PlannedCorridor | null {
  if (
    isInsideGeofence(origin, geofences) ||
    isInsideGeofence(destination, geofences)
  ) {
    return null;
  }
  const projection = projectionAround(origin.longitude, origin.latitude);
  const toPlane = (point: LngLat) =>
    projection.toPlane(point.longitude, point.latitude);
  const ends = [toPlane(origin), toPlane(destination)];
  const fences = geofences.map((fence) => {
    const ring = fence.coordinates[0];
    const zone = inflateRing(
      ring.map(([longitude, latitude]) =>
        projection.toPlane(longitude, latitude),
      ),
      GEOFENCE_MARGIN_KM,
    );
    // Un extremo dentro del margen (pero fuera de la geovalla) sí es válido:
    // ese primer o último tramo solo tiene que no cruzar la geovalla real.
    return { ring, zone, holdsEnd: ends.map((end) => isInsideZone(end, zone)) };
  });
  const corners = fences
    .flatMap((fence) => fence.zone.hull)
    .filter(
      (corner) => !fences.some((fence) => isInsideZone(corner, fence.zone)),
    );
  const nodes = [...ends, ...corners];
  const blocked = (from: number, to: number) =>
    fences.some((fence) => {
      const relaxed =
        (from < 2 && fence.holdsEnd[from]) || (to < 2 && fence.holdsEnd[to]);
      if (!relaxed) {
        return segmentEntersZone(nodes[from], nodes[to], fence.zone);
      }
      const segment = [nodes[from], nodes[to]].map((point) => {
        const [longitude, latitude] = projection.toLngLat(point);
        return { longitude, latitude };
      });
      return crossesFence(segment, fence.ring);
    });
  const path = shortestVisiblePath(nodes, 0, 1, blocked);
  if (!path) {
    return null;
  }
  return toCorridor(
    path.map((index) => {
      if (index === 0) return origin;
      if (index === 1) return destination;
      const [longitude, latitude] = projection.toLngLat(nodes[index]);
      return { longitude, latitude };
    }),
  );
}

/** Un destino dentro de una geovalla no tiene corredor desde ninguna central. */
export function isInsideGeofence(
  point: LngLat,
  geofences: GeoJsonPolygon[],
): boolean {
  return geofences.some((fence) => pointInRing(point, fence.coordinates[0]));
}

/** ¿Algún tramo del corredor cruza una geovalla (sin contar el margen)? */
export function corridorCrossesGeofence(
  corridor: PlannedCorridor,
  geofences: GeoJsonPolygon[],
): boolean {
  return pathCrosses(corridor.coordinates.map(toLngLat), geofences);
}

/**
 * RF-12 y RF-30: regreso a la central con las geovallas vigentes al salir.
 *  1. El corredor más corto con margen.
 *  2. Si no hay, la ida al revés, siempre que no cruce ninguna geovalla.
 *  3. Si el dron o la central quedaron dentro de una geovalla nueva, el dron
 *     tiene que salir o llegar igual: se planea sin esas geovallas.
 *  4. Último recurso: la ida al revés, marcada como insegura.
 */
export function planReturnCorridor(
  from: LngLat,
  hub: LngLat,
  geofences: GeoJsonPolygon[],
  outbound: PlannedCorridor | null,
): { corridor: PlannedCorridor; crossesGeofence: boolean } | null {
  const planned = planCorridor(from, hub, geofences);
  if (planned) {
    return { corridor: planned, crossesGeofence: false };
  }
  const back = outbound ? reverseCorridor(outbound) : null;
  if (back && !corridorCrossesGeofence(back, geofences)) {
    return { corridor: back, crossesGeofence: false };
  }
  const trapping = geofences.filter(
    (fence) =>
      isInsideGeofence(from, [fence]) || isInsideGeofence(hub, [fence]),
  );
  if (trapping.length) {
    const escape = planCorridor(
      from,
      hub,
      geofences.filter((fence) => !trapping.includes(fence)),
    );
    if (escape) {
      return { corridor: escape, crossesGeofence: true };
    }
  }
  return back ? { corridor: back, crossesGeofence: true } : null;
}

function pathCrosses(path: LngLat[], geofences: GeoJsonPolygon[]): boolean {
  return geofences.some((fence) => crossesFence(path, fence.coordinates[0]));
}

function crossesFence(path: LngLat[], ring: number[][]): boolean {
  if (path.some((point) => pointInRing(point, ring))) {
    return true;
  }
  for (let index = 1; index < path.length; index += 1) {
    if (segmentHitsRing(path[index - 1], path[index], ring)) {
      return true;
    }
  }
  return false;
}

function segmentHitsRing(
  start: LngLat,
  end: LngLat,
  ring: number[][],
): boolean {
  const last = ring.length - 1;
  for (let index = 0; index < last; index += 1) {
    const edgeStart = toLngLat(ring[index]);
    const edgeEnd = toLngLat(ring[index + 1]);
    if (segmentsIntersect(start, end, edgeStart, edgeEnd)) {
      return true;
    }
  }
  return false;
}

function segmentsIntersect(
  a: LngLat,
  b: LngLat,
  c: LngLat,
  d: LngLat,
): boolean {
  const abToC = cross(a, b, c);
  const abToD = cross(a, b, d);
  const cdToA = cross(c, d, a);
  const cdToB = cross(c, d, b);
  if (abToC === 0 && onSegment(a, c, b)) return true;
  if (abToD === 0 && onSegment(a, d, b)) return true;
  if (cdToA === 0 && onSegment(c, a, d)) return true;
  if (cdToB === 0 && onSegment(c, b, d)) return true;
  return abToC > 0 !== abToD > 0 && cdToA > 0 !== cdToB > 0;
}

function cross(origin: LngLat, end: LngLat, point: LngLat): number {
  return (
    (end.longitude - origin.longitude) * (point.latitude - origin.latitude) -
    (end.latitude - origin.latitude) * (point.longitude - origin.longitude)
  );
}

function onSegment(start: LngLat, point: LngLat, end: LngLat): boolean {
  return (
    point.longitude <= Math.max(start.longitude, end.longitude) &&
    point.longitude >= Math.min(start.longitude, end.longitude) &&
    point.latitude <= Math.max(start.latitude, end.latitude) &&
    point.latitude >= Math.min(start.latitude, end.latitude)
  );
}

function pointInRing(point: LngLat, ring: number[][]): boolean {
  let inside = false;
  for (
    let index = 0, previous = ring.length - 1;
    index < ring.length;
    previous = index, index += 1
  ) {
    const [currentLng, currentLat] = ring[index];
    const [previousLng, previousLat] = ring[previous];
    const crossesLatitude =
      currentLat > point.latitude !== previousLat > point.latitude;
    if (!crossesLatitude) {
      continue;
    }
    const longitudeAtLatitude =
      ((previousLng - currentLng) * (point.latitude - currentLat)) /
        (previousLat - currentLat) +
      currentLng;
    if (point.longitude < longitudeAtLatitude) {
      inside = !inside;
    }
  }
  return inside;
}

/** Regreso por donde vino: mismo corredor, recorrido al revés. */
export function reverseCorridor(corridor: PlannedCorridor): PlannedCorridor {
  return { ...corridor, coordinates: [...corridor.coordinates].reverse() };
}

function toCorridor(path: LngLat[]): PlannedCorridor {
  let distanceKm = 0;
  for (let index = 1; index < path.length; index += 1) {
    distanceKm += haversineKm(path[index - 1], path[index]);
  }
  return {
    altitudeM: CORRIDOR_ALTITUDE_M,
    distanceKm: Math.round(distanceKm * 100) / 100,
    coordinates: path.map((point) => [point.longitude, point.latitude]),
  };
}

export function haversineKm(start: LngLat, end: LngLat): number {
  const toRadians = (degrees: number) => (degrees * Math.PI) / 180;
  const latitudeDelta = toRadians(end.latitude - start.latitude);
  const longitudeDelta = toRadians(end.longitude - start.longitude);
  const startLat = toRadians(start.latitude);
  const endLat = toRadians(end.latitude);
  const haversine =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(startLat) * Math.cos(endLat) * Math.sin(longitudeDelta / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(haversine)));
}

function toLngLat(pair: number[]): LngLat {
  return { longitude: pair[0], latitude: pair[1] };
}

/** Un corredor partido donde va el dron: lo volado y lo que falta. */
export type CorridorSplit = {
  flown: Array<[number, number]>;
  at: LngLat;
  remaining: Array<[number, number]>;
};

/**
 * Corta el corredor a `km` del inicio, en el mismo punto que calcula el
 * simulador para el dron. El punto de corte cierra lo volado y abre lo que
 * falta.
 */
export function splitCorridorAt(
  corridor: PlannedCorridor,
  km: number,
): CorridorSplit {
  const coordinates = corridor.coordinates;
  if (coordinates.length < 2 || km <= 0) {
    const start = toLngLat(coordinates[0] ?? [0, 0]);
    return {
      flown: coordinates.slice(0, 1),
      at: start,
      remaining: coordinates,
    };
  }
  let left = km;
  for (let index = 1; index < coordinates.length; index += 1) {
    const start = toLngLat(coordinates[index - 1]);
    const end = toLngLat(coordinates[index]);
    const segment = haversineKm(start, end);
    if (left < segment) {
      const ratio = segment === 0 ? 0 : left / segment;
      const point: [number, number] = [
        start.longitude + (end.longitude - start.longitude) * ratio,
        start.latitude + (end.latitude - start.latitude) * ratio,
      ];
      return {
        flown: [...coordinates.slice(0, index), point],
        at: toLngLat(point),
        remaining: [point, ...coordinates.slice(index)],
      };
    }
    left -= segment;
  }
  const last = coordinates[coordinates.length - 1];
  return { flown: coordinates, at: toLngLat(last), remaining: [last] };
}

export type RerouteOutcome =
  /** El tramo que falta no cruza ninguna zona: sigue igual. */
  | { kind: 'clear' }
  | {
      kind: 'rerouted';
      /** Lo volado más el tramo nuevo: el simulador sigue en el mismo km. */
      corridor: PlannedCorridor;
      /** Lo que le falta volar por el tramo nuevo. */
      remainingKm: number;
      /** Cuánto más (o menos) vuela que por el tramo viejo. */
      addedKm: number;
      /** Tuvo que cruzar la zona: el dron o el destino quedaron dentro. */
      crossesGeofence: boolean;
    }
  /** No hay camino ni saliendo de la zona: lo resuelve RF-34. */
  | { kind: 'blocked' };

/**
 * RF-33: si una zona nueva cruza el tramo que le falta al dron, traza uno
 * nuevo desde donde va hasta el mismo destino, con las reglas de RF-12. Si
 * el dron o el destino quedaron dentro de la zona, la cruza lo justo para
 * salir o llegar, y queda marcado.
 */
export function rerouteFromPosition(
  corridor: PlannedCorridor,
  flownKm: number,
  geofences: GeoJsonPolygon[],
): RerouteOutcome {
  const split = splitCorridorAt(corridor, flownKm);
  const remainingPath = split.remaining.map(toLngLat);
  if (remainingPath.length < 2 || !pathCrosses(remainingPath, geofences)) {
    return { kind: 'clear' };
  }
  const destination = remainingPath[remainingPath.length - 1];
  let planned = planCorridor(split.at, destination, geofences);
  let crossesGeofence = false;
  if (!planned) {
    const trapping = geofences.filter(
      (fence) =>
        isInsideGeofence(split.at, [fence]) ||
        isInsideGeofence(destination, [fence]),
    );
    planned = trapping.length
      ? planCorridor(
          split.at,
          destination,
          geofences.filter((fence) => !trapping.includes(fence)),
        )
      : null;
    crossesGeofence = planned != null;
  }
  if (!planned) {
    return { kind: 'blocked' };
  }
  const flownDistance = pathKm(split.flown.map(toLngLat));
  const oldRemaining = pathKm(remainingPath);
  return {
    kind: 'rerouted',
    corridor: {
      altitudeM: corridor.altitudeM,
      distanceKm: Math.round((flownDistance + planned.distanceKm) * 100) / 100,
      coordinates: [...split.flown, ...planned.coordinates.slice(1)],
    },
    remainingKm: planned.distanceKm,
    addedKm: Math.round((planned.distanceKm - oldRemaining) * 100) / 100,
    crossesGeofence,
  };
}

function pathKm(path: LngLat[]): number {
  let total = 0;
  for (let index = 1; index < path.length; index += 1) {
    total += haversineKm(path[index - 1], path[index]);
  }
  return total;
}
