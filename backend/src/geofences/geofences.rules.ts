import { BadRequestException } from '@nestjs/common';

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
