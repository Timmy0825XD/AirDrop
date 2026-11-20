import { GeofenceClass } from '../common/enums/geofence-class.enum';
import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { OperationalCategory } from '../common/enums/operational-category.enum';
import { LngLat } from '../routing/routing.rules';
import { GeofenceGeometry } from './geofence-shape.rules';
import { GeoJsonPolygon } from './geofences.rules';

/** Las columnas que lee toda consulta de geovallas. */
export const GEOFENCE_COLUMNS = `id, class, shape, name, reason, category, "centerLatitude", "centerLongitude", "radiusM", ST_AsGeoJSON(polygon) AS polygon, code, "legalBasis", source, active, "createdByUserId", "updatedByUserId", "createdAt", "updatedAt", "expiresAt"`;

export type GeofenceRow = {
  id: string;
  class: GeofenceClass;
  shape: GeofenceShape;
  name: string;
  reason: string | null;
  category: OperationalCategory | null;
  centerLatitude: string | null;
  centerLongitude: string | null;
  radiusM: number | null;
  polygon: string;
  code: string | null;
  legalBasis: string | null;
  source: string | null;
  active: boolean;
  createdByUserId: string | null;
  updatedByUserId: string | null;
  createdAt: Date;
  updatedAt: Date;
  expiresAt: Date | null;
};

/** La ficha de una geovalla (RU-19): lo que ven el operador y el admin. */
export type PublicGeofence = {
  id: string;
  class: GeofenceClass;
  /** RF-21: círculo (con `center` y `radiusM`) o polígono de vértices. */
  shape: GeofenceShape;
  name: string;
  /** Operativa y temporal. */
  reason: string | null;
  category: OperationalCategory | null;
  center: LngLat | null;
  radiusM: number | null;
  /** Siempre: es lo que rodean las rutas (el círculo, ya en polígono). */
  polygon: GeoJsonPolygon;
  /** Zona legal (RF-43). */
  code: string | null;
  legalBasis: string | null;
  source: string | null;
  /** Una zona legal desactivada no bloquea rutas. */
  active: boolean;
  createdByUserId: string | null;
  updatedByUserId: string | null;
  createdAt: Date;
  updatedAt: Date;
  /** RF-36: vencimiento de una temporal; `null`, no vence. */
  expiresAt: Date | null;
};

export function toPublicGeofence(row: GeofenceRow): PublicGeofence {
  return {
    id: row.id,
    class: row.class,
    shape: row.shape,
    name: row.name,
    reason: row.reason,
    category: row.category,
    center:
      row.centerLatitude !== null && row.centerLongitude !== null
        ? {
            latitude: Number(row.centerLatitude),
            longitude: Number(row.centerLongitude),
          }
        : null,
    radiusM: row.radiusM,
    polygon: JSON.parse(row.polygon) as GeoJsonPolygon,
    code: row.code,
    legalBasis: row.legalBasis,
    source: row.source,
    active: row.active,
    createdByUserId: row.createdByUserId,
    updatedByUserId: row.updatedByUserId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    expiresAt: row.expiresAt ? new Date(row.expiresAt) : null,
  };
}

/** `centerLatitude`, `centerLongitude`, `radiusM` y el polígono, en ese orden. */
export function geometryParams(geometry: GeofenceGeometry) {
  return [
    geometry.center?.latitude ?? null,
    geometry.center?.longitude ?? null,
    geometry.radiusM,
    JSON.stringify(geometry.polygon),
  ];
}
