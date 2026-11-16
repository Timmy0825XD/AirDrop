import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat, isInsideGeofence } from '../routing/routing.rules';

/**
 * RF-43: zonas legales del RAC 100 a escala de demo
 * (`context/operacion/espacio-aereo.md`). Solo geometría y reglas: el
 * servicio decide de dónde salen las zonas.
 */

const EARTH_RADIUS_KM = 6371;

export const NODE_IN_RESTRICTED_AIRSPACE =
  'Un nodo no puede quedar en el anillo de un aeródromo, en un helipuerto ni en una zona prohibida (RF-43).';

export const HUB_IN_PROHIBITED_AIRSPACE =
  'La central queda en una zona donde no se vuela: anillo de un aeródromo, helipuerto o zona prohibida (RF-43).';

export type AirspaceZone = {
  code: string;
  kind: AirspaceZoneKind;
  name: string;
  /** Artículo que la respalda. */
  legalBasis: string;
  /** De dónde sale el dato (OSM, AIP, GeoNames…). */
  source: string;
  polygon: GeoJsonPolygon;
};

/** Las que un corredor no cruza nunca: todas las de la demo. */
export const BLOCKING_KINDS: readonly AirspaceZoneKind[] = [
  AirspaceZoneKind.AERODROME,
  AirspaceZoneKind.PROHIBITED,
  AirspaceZoneKind.HELIPORT,
];

export function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

function toDeg(rad: number): number {
  return (rad * 180) / Math.PI;
}

/** El punto a `distanceKm` de `from` con rumbo `bearingDeg` (0 = norte). */
export function destinationPoint(
  from: LngLat,
  bearingDeg: number,
  distanceKm: number,
): LngLat {
  const angular = distanceKm / EARTH_RADIUS_KM;
  const bearing = toRad(bearingDeg);
  const lat1 = toRad(from.latitude);
  const lng1 = toRad(from.longitude);
  const lat2 = Math.asin(
    Math.sin(lat1) * Math.cos(angular) +
      Math.cos(lat1) * Math.sin(angular) * Math.cos(bearing),
  );
  const lng2 =
    lng1 +
    Math.atan2(
      Math.sin(bearing) * Math.sin(angular) * Math.cos(lat1),
      Math.cos(angular) - Math.sin(lat1) * Math.sin(lat2),
    );
  return { latitude: toDeg(lat2), longitude: toDeg(lng2) };
}

/** Rumbo inicial de `from` a `to`, en grados de 0 a 360. */
export function bearingDeg(from: LngLat, to: LngLat): number {
  const lat1 = toRad(from.latitude);
  const lat2 = toRad(to.latitude);
  const dLng = toRad(to.longitude - from.longitude);
  const y = Math.sin(dLng) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

/**
 * Un círculo como polígono cerrado de `sides` lados, para que el
 * planificador lo rodee como a cualquier geovalla. Los vértices quedan sobre
 * un radio algo mayor, para que el polígono contenga al círculo entero.
 */
export function circlePolygon(
  center: LngLat,
  radiusKm: number,
  sides: number,
): GeoJsonPolygon {
  const outer = radiusKm / Math.cos(Math.PI / sides);
  const ring: number[][] = [];
  for (let side = 0; side < sides; side += 1) {
    const point = destinationPoint(center, (360 * side) / sides, outer);
    ring.push([round6(point.longitude), round6(point.latitude)]);
  }
  ring.push([...ring[0]]);
  return { type: 'Polygon', coordinates: [ring] };
}

function round6(value: number): number {
  return Math.round(value * 1e6) / 1e6;
}

export function isBlocking(zone: AirspaceZone): boolean {
  return BLOCKING_KINDS.includes(zone.kind);
}

/**
 * Polígonos que bloquean rutas. Una zona que queda entera dentro de otra
 * bloqueante (la cárcel dentro del anillo del aeropuerto) no suma: el mapa la
 * dibuja, pero el planificador no necesita rodearla dos veces.
 */
export function blockingPolygons(zones: AirspaceZone[]): GeoJsonPolygon[] {
  const blocking = zones.filter(isBlocking);
  return blocking
    .filter(
      (zone) =>
        !blocking.some(
          (other) =>
            other !== zone && containsPolygon(other.polygon, zone.polygon),
        ),
    )
    .map((zone) => zone.polygon);
}

function containsPolygon(
  outer: GeoJsonPolygon,
  inner: GeoJsonPolygon,
): boolean {
  return inner.coordinates[0].every(([longitude, latitude]) =>
    isInsideGeofence({ longitude, latitude }, [outer]),
  );
}

export function zoneAt(
  point: LngLat,
  zones: AirspaceZone[],
): AirspaceZone | null {
  return zones.find((zone) => isInsideGeofence(point, [zone.polygon])) ?? null;
}
