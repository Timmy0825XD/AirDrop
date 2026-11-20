import { BadRequestException } from '@nestjs/common';
import { circlePolygon } from '../airspace/airspace.rules';
import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { LngLat } from '../routing/routing.rules';
import { GeoJsonPolygon } from './geofences.rules';

/** RF-21: de un CAI (100 m) al anillo del aeropuerto (1,5 km), con margen. */
export const RADIUS_MIN_M = 50;
export const RADIUS_MAX_M = 5_000;
export const VERTICES_MIN = 3;
export const VERTICES_MAX = 50;

export const RADIUS_OUT_OF_RANGE = `El radio debe estar entre ${RADIUS_MIN_M} m y ${RADIUS_MAX_M / 1000} km.`;
export const VERTICES_OUT_OF_RANGE = `El polígono necesita entre ${VERTICES_MIN} y ${VERTICES_MAX} vértices.`;
export const POLYGON_SELF_INTERSECTS =
  'Los lados del polígono no se pueden cruzar.';
export const POLYGON_REPEATED_VERTEX =
  'El polígono tiene vértices repetidos o sin área.';

export type ShapeInput = {
  shape: GeofenceShape;
  center?: LngLat;
  radiusM?: number;
  vertices?: LngLat[];
};

/** Lo que se guarda: la forma editable y el polígono que rodean las rutas. */
export type GeofenceGeometry = {
  shape: GeofenceShape;
  center: LngLat | null;
  radiusM: number | null;
  polygon: GeoJsonPolygon;
};

export function toGeofenceGeometry(input: ShapeInput): GeofenceGeometry {
  if (input.shape === GeofenceShape.CIRCLE) {
    return circleGeometry(input.center, input.radiusM);
  }
  return polygonGeometry(input.vertices);
}

function circleGeometry(
  center: LngLat | undefined,
  radiusM: number | undefined,
): GeofenceGeometry {
  if (!center) {
    throw new BadRequestException('El círculo necesita su centro.');
  }
  if (
    radiusM === undefined ||
    !Number.isInteger(radiusM) ||
    radiusM < RADIUS_MIN_M ||
    radiusM > RADIUS_MAX_M
  ) {
    throw new BadRequestException(RADIUS_OUT_OF_RANGE);
  }
  return {
    shape: GeofenceShape.CIRCLE,
    center,
    radiusM,
    polygon: circlePolygon(center, radiusM / 1000, circleSides(radiusM)),
  };
}

/** Más lados en los círculos grandes, para que el borde no se note. */
export function circleSides(radiusM: number): number {
  if (radiusM >= 1_000) return 32;
  if (radiusM >= 300) return 16;
  return 12;
}

function polygonGeometry(vertices: LngLat[] | undefined): GeofenceGeometry {
  if (
    !vertices ||
    vertices.length < VERTICES_MIN ||
    vertices.length > VERTICES_MAX
  ) {
    throw new BadRequestException(VERTICES_OUT_OF_RANGE);
  }
  const ring = vertices.map(
    (point) => [point.longitude, point.latitude] as [number, number],
  );
  if (hasRepeatedVertex(ring) || Math.abs(signedArea(ring)) < 1e-12) {
    throw new BadRequestException(POLYGON_REPEATED_VERTEX);
  }
  if (selfIntersects(ring)) {
    throw new BadRequestException(POLYGON_SELF_INTERSECTS);
  }
  return {
    shape: GeofenceShape.POLYGON,
    center: null,
    radiusM: null,
    polygon: { type: 'Polygon', coordinates: [[...ring, ring[0]]] },
  };
}

type Point = [number, number];

function hasRepeatedVertex(ring: Point[]): boolean {
  const seen = new Set(ring.map(([x, y]) => `${x},${y}`));
  return seen.size !== ring.length;
}

function signedArea(ring: Point[]): number {
  let sum = 0;
  for (let i = 0; i < ring.length; i += 1) {
    const [x1, y1] = ring[i];
    const [x2, y2] = ring[(i + 1) % ring.length];
    sum += x1 * y2 - x2 * y1;
  }
  return sum / 2;
}

/** Dos lados no vecinos que se tocan: el polígono no es simple. */
export function selfIntersects(ring: Point[]): boolean {
  const n = ring.length;
  for (let i = 0; i < n; i += 1) {
    const a = ring[i];
    const b = ring[(i + 1) % n];
    for (let j = i + 1; j < n; j += 1) {
      const neighbours = j === i + 1 || (i === 0 && j === n - 1);
      if (neighbours) continue;
      if (segmentsTouch(a, b, ring[j], ring[(j + 1) % n])) {
        return true;
      }
    }
  }
  return false;
}

function orientation(p: Point, q: Point, r: Point): number {
  const value = (q[1] - p[1]) * (r[0] - q[0]) - (q[0] - p[0]) * (r[1] - q[1]);
  if (Math.abs(value) < 1e-15) return 0;
  return value > 0 ? 1 : 2;
}

function onSegment(p: Point, q: Point, r: Point): boolean {
  return (
    Math.min(p[0], r[0]) <= q[0] &&
    q[0] <= Math.max(p[0], r[0]) &&
    Math.min(p[1], r[1]) <= q[1] &&
    q[1] <= Math.max(p[1], r[1])
  );
}

function segmentsTouch(p1: Point, q1: Point, p2: Point, q2: Point): boolean {
  const o1 = orientation(p1, q1, p2);
  const o2 = orientation(p1, q1, q2);
  const o3 = orientation(p2, q2, p1);
  const o4 = orientation(p2, q2, q1);
  if (o1 !== o2 && o3 !== o4) return true;
  if (o1 === 0 && onSegment(p1, p2, q1)) return true;
  if (o2 === 0 && onSegment(p1, q2, q1)) return true;
  if (o3 === 0 && onSegment(p2, p1, q2)) return true;
  if (o4 === 0 && onSegment(p2, q1, q2)) return true;
  return false;
}
