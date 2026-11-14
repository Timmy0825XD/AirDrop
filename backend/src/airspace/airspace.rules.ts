import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import {
  LngLat,
  PlannedCorridor,
  haversineKm,
  isInsideGeofence,
} from '../routing/routing.rules';

/**
 * RF-43: zonas legales del RAC 100 y el paso por las zonas coordinadas
 * (`context/operacion/espacio-aereo.md`). Solo geometría y reglas: el
 * servicio decide de dónde salen las zonas.
 */

const EARTH_RADIUS_KM = 6371;

/** Un sitio pactado dentro de una zona coordinada: el destino debe estar a esta distancia. */
export const PACTED_SITE_TOLERANCE_KM = 0.1;

export const DESTINATION_IN_COORDINATED_ZONE =
  'El destino está en una zona coordinada (policía o resguardo): solo se vuela a sus puntos pactados.';

export const NODE_IN_RESTRICTED_AIRSPACE =
  'Un nodo no puede quedar en zona urbana, en el anillo de un aeródromo, en una zona prohibida ni en una zona coordinada (RF-43).';

export const HUB_IN_PROHIBITED_AIRSPACE =
  'La central queda en una zona donde no se vuela: zona urbana, anillo de un aeródromo o zona prohibida (RF-43).';

export type PactedSite = { name: string; latitude: number; longitude: number };

export type AirspaceZone = {
  code: string;
  kind: AirspaceZoneKind;
  name: string;
  /** Artículo que la respalda. */
  legalBasis: string;
  /** De dónde sale el dato (OSM, AIP, GeoNames…). */
  source: string;
  polygon: GeoJsonPolygon;
  /** Solo zona coordinada: entrada pactada, fuera del polígono. */
  gateway: LngLat | null;
  /** Solo zona coordinada: los únicos destinos permitidos dentro. */
  sites: PactedSite[];
};

/** Las que un corredor no cruza nunca. La coordinada y la de precaución, no. */
export const BLOCKING_KINDS: readonly AirspaceZoneKind[] = [
  AirspaceZoneKind.AERODROME,
  AirspaceZoneKind.PROHIBITED,
  AirspaceZoneKind.HELIPORT,
  AirspaceZoneKind.URBAN,
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

/** Entrada pactada: fuera del círculo, en el rumbo hacia el nodo que la usa. */
export function gatewayToward(
  center: LngLat,
  radiusKm: number,
  toward: LngLat,
): LngLat {
  const point = destinationPoint(
    center,
    bearingDeg(center, toward),
    radiusKm + 0.3,
  );
  return {
    latitude: round6(point.latitude),
    longitude: round6(point.longitude),
  };
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

export function coordinatedZones(zones: AirspaceZone[]): AirspaceZone[] {
  return zones.filter((zone) => zone.kind === AirspaceZoneKind.COORDINATED);
}

export function zoneAt(
  point: LngLat,
  zones: AirspaceZone[],
): AirspaceZone | null {
  return zones.find((zone) => isInsideGeofence(point, [zone.polygon])) ?? null;
}

/** ¿El punto es uno de los sitios pactados de la zona? */
export function isPactedSite(point: LngLat, zone: AirspaceZone): boolean {
  return zone.sites.some(
    (site) => haversineKm(point, site) <= PACTED_SITE_TOLERANCE_KM,
  );
}

export type GatewayPlan = {
  /** Donde empieza y termina el tramo libre (fuera de toda zona coordinada). */
  start: LngLat;
  end: LngLat;
  /** Tramos fijos dentro de la zona coordinada de cada extremo. */
  head: LngLat[];
  tail: LngLat[];
};

/**
 * RF-12: un extremo dentro de una zona coordinada entra o sale por su
 * entrada pactada. `null` si un extremo está en la zona sin entrada, o si el
 * destino no es un sitio pactado y no se permite (`allowUnpactedEnd`).
 */
export function gatewayPlan(
  origin: LngLat,
  destination: LngLat,
  coordinated: AirspaceZone[],
  allowUnpacted: { origin: boolean; destination: boolean },
): GatewayPlan | null {
  const atOrigin = zoneAt(origin, coordinated);
  const atDestination = zoneAt(destination, coordinated);
  const head: LngLat[] = [];
  const tail: LngLat[] = [];
  let start = origin;
  let end = destination;
  if (atOrigin) {
    if (
      !atOrigin.gateway ||
      (!allowUnpacted.origin && !isPactedSite(origin, atOrigin))
    ) {
      return null;
    }
    head.push(origin);
    start = atOrigin.gateway;
  }
  if (atDestination) {
    if (
      !atDestination.gateway ||
      (!allowUnpacted.destination && !isPactedSite(destination, atDestination))
    ) {
      return null;
    }
    tail.push(destination);
    end = atDestination.gateway;
  }
  return { start, end, head, tail };
}

/** Pega los tramos pactados al corredor libre y recalcula la distancia. */
export function joinGatewayLegs(
  plan: GatewayPlan,
  core: PlannedCorridor,
): PlannedCorridor {
  const coordinates: Array<[number, number]> = [
    ...plan.head.map((point): [number, number] => [
      point.longitude,
      point.latitude,
    ]),
    ...core.coordinates,
    ...plan.tail.map((point): [number, number] => [
      point.longitude,
      point.latitude,
    ]),
  ];
  let distanceKm = 0;
  for (let index = 1; index < coordinates.length; index += 1) {
    distanceKm += haversineKm(
      {
        longitude: coordinates[index - 1][0],
        latitude: coordinates[index - 1][1],
      },
      { longitude: coordinates[index][0], latitude: coordinates[index][1] },
    );
  }
  return {
    altitudeM: core.altitudeM,
    distanceKm: Math.round(distanceKm * 100) / 100,
    coordinates,
  };
}
