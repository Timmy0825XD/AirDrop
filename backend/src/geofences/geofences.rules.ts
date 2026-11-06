import { BadRequestException } from '@nestjs/common';
import { isInsideGeofence } from '../routing/routing.rules';

export type GeoJsonPolygon = {
  type: 'Polygon';
  coordinates: number[][][];
};

export function assertGeoJsonPolygon(value: unknown): GeoJsonPolygon {
  if (!value || typeof value !== 'object') {
    throw new BadRequestException('El polígono no es válido.');
  }
  const polygon = value as GeoJsonPolygon;
  if (polygon.type !== 'Polygon' || !Array.isArray(polygon.coordinates)) {
    throw new BadRequestException('El polígono debe ser GeoJSON de tipo Polygon.');
  }
  const ring = polygon.coordinates[0];
  if (!Array.isArray(ring) || ring.length < 4) {
    throw new BadRequestException(
      'El polígono necesita al menos 4 puntos y debe estar cerrado.',
    );
  }
  for (const point of ring) {
    if (
      !Array.isArray(point) ||
      point.length !== 2 ||
      typeof point[0] !== 'number' ||
      typeof point[1] !== 'number' ||
      Number.isNaN(point[0]) ||
      Number.isNaN(point[1]) ||
      point[0] < -180 ||
      point[0] > 180 ||
      point[1] < -90 ||
      point[1] > 90
    ) {
      throw new BadRequestException(
        'Cada punto debe ser [longitud, latitud] con rangos válidos.',
      );
    }
  }
  const first = ring[0];
  const last = ring[ring.length - 1];
  if (first[0] !== last[0] || first[1] !== last[1]) {
    throw new BadRequestException(
      'El primer y el último punto del polígono deben coincidir.',
    );
  }
  return polygon;
}

/**
 * RF-36: una geovalla rige si no vence (del operador) o si su vencimiento
 * todavía no llega en la hora simulada. `$param` es esa hora.
 */
export function activeGeofenceSql(param: string, alias = ''): string {
  const column = `${alias ? `${alias}.` : ''}"expiresAt"`;
  return `(${column} IS NULL OR ${column} > ${param})`;
}

export function isGeofenceActive(
  fence: { expiresAt: Date | null },
  now: Date,
): boolean {
  return fence.expiresAt === null || fence.expiresAt.getTime() > now.getTime();
}

/** Vencimiento de una geovalla temporal que dura `durationMin` desde `now`. */
export function temporaryExpiry(now: Date, durationMin: number): Date {
  return new Date(now.getTime() + durationMin * 60_000);
}

type HubPoint = { name: string; latitude: number; longitude: number };

/**
 * Una central dentro de una geovalla se queda sin corredor para siempre: no
 * vuelve a salir ni a llegar ningún dron. Por eso no se dibuja una encima.
 */
export function assertCoversNoHub(
  polygon: GeoJsonPolygon,
  hubs: HubPoint[],
): void {
  const covered = hubs.filter((hub) => isInsideGeofence(hub, [polygon]));
  if (covered.length) {
    throw new BadRequestException(
      `La geovalla no puede cubrir una central: ${covered
        .map((hub) => hub.name)
        .join(', ')} queda dentro.`,
    );
  }
}
