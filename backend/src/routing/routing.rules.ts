import { GeoJsonPolygon } from '../geofences/geofences.rules';

/** RF-12: el corredor de ida va a una altitud fija. El regreso se calcula después. */
export const CORRIDOR_ALTITUDE_M = 100;

/** Separación mínima, en grados, para salir del bounding box de una geovalla. */
const DETOUR_MARGIN_DEGREES = 0.01;

const EARTH_RADIUS_KM = 6371;

export type LngLat = {
  longitude: number;
  latitude: number;
};

export type PlannedCorridor = {
  altitudeM: number;
  distanceKm: number;
  coordinates: Array<[number, number]>;
};

type Box = {
  minLng: number;
  maxLng: number;
  minLat: number;
  maxLat: number;
};

/** Línea directa, o un rodeo al norte o al sur de la geovalla que la bloquea. */
export function planOutboundCorridor(
  origin: LngLat,
  destination: LngLat,
  geofences: GeoJsonPolygon[],
): PlannedCorridor | null {
  const direct = [origin, destination];
  if (!pathCrosses(direct, geofences)) {
    return toCorridor(direct);
  }
  const blocking = geofences.find((fence) => pathCrosses(direct, [fence]));
  if (!blocking) {
    return null;
  }
  let best: PlannedCorridor | null = null;
  for (const side of ['north', 'south'] as const) {
    const path = [origin, detourWaypoint(blocking, side), destination];
    if (pathCrosses(path, geofences)) {
      continue;
    }
    const planned = toCorridor(path);
    if (!best || planned.distanceKm < best.distanceKm) {
      best = planned;
    }
  }
  return best;
}

function detourWaypoint(
  fence: GeoJsonPolygon,
  side: 'north' | 'south',
): LngLat {
  const box = boundingBox(fence.coordinates[0]);
  const span = Math.max(
    DETOUR_MARGIN_DEGREES,
    box.maxLng - box.minLng,
    box.maxLat - box.minLat,
  );
  const latitude = side === 'north' ? box.maxLat + span : box.minLat - span;
  return {
    longitude: clamp((box.minLng + box.maxLng) / 2, -180, 180),
    latitude: clamp(latitude, -90, 90),
  };
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

function boundingBox(ring: number[][]): Box {
  const box: Box = {
    minLng: Infinity,
    maxLng: -Infinity,
    minLat: Infinity,
    maxLat: -Infinity,
  };
  for (const [longitude, latitude] of ring) {
    box.minLng = Math.min(box.minLng, longitude);
    box.maxLng = Math.max(box.maxLng, longitude);
    box.minLat = Math.min(box.minLat, latitude);
    box.maxLat = Math.max(box.maxLat, latitude);
  }
  return box;
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

function haversineKm(start: LngLat, end: LngLat): number {
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

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
