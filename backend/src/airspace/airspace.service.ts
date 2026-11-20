import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
  Optional,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import {
  GeofenceClass,
  LEGAL_GEOFENCE_CLASSES,
} from '../common/enums/geofence-class.enum';
import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { Geofence } from '../geofences/geofence.entity';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat } from '../routing/routing.rules';
import {
  AirspaceZone,
  HUB_IN_PROHIBITED_AIRSPACE,
  blockingPolygons,
  isBlocking,
  zoneAt,
} from './airspace.rules';
import { regionalAirspace } from './regional-airspace';

type LegalRow = {
  id: string;
  class: GeofenceClass;
  shape: GeofenceShape;
  code: string;
  name: string;
  legalBasis: string;
  source: string;
  centerLatitude: string | null;
  centerLongitude: string | null;
  radiusM: number | null;
  polygon: string;
};

type QueryRunner = Pick<Repository<Geofence>, 'query'>;

/**
 * RF-43: las zonas legales son geovallas de clase legal (RF-21) que mantiene
 * el administrador (RU-36). El planificador las consulta en cada ruta, así
 * que viven en memoria: las activas se cargan al arrancar y se recargan con
 * `reload()` cuando una cambia. Sin base (pruebas), son las de la semilla.
 */
@Injectable()
export class AirspaceService implements OnModuleInit {
  private readonly logger = new Logger(AirspaceService.name);
  private zones: AirspaceZone[] = [];
  private blocking: GeoJsonPolygon[] = [];

  constructor(
    @Optional()
    @InjectRepository(Geofence)
    private readonly geofences?: Repository<Geofence>,
  ) {
    this.use(regionalAirspace());
  }

  async onModuleInit(): Promise<void> {
    if (!this.geofences) {
      return;
    }
    try {
      await seedLegalZonesIfEmpty(this.geofences);
      await this.reload();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'zonas';
      this.logger.error(`No se cargaron las zonas legales: ${message}`);
    }
  }

  /** Vuelve a leer las zonas legales activas. */
  async reload(): Promise<void> {
    if (!this.geofences) {
      return;
    }
    const rows: LegalRow[] = await this.geofences.query(
      `SELECT id, class, shape, code, name, "legalBasis", source,
              "centerLatitude", "centerLongitude", "radiusM",
              ST_AsGeoJSON(polygon) AS polygon
       FROM geofences
       WHERE class = ANY($1) AND active = true
       ORDER BY code ASC`,
      [LEGAL_GEOFENCE_CLASSES],
    );
    this.use(rows.map(toZone));
  }

  all(): AirspaceZone[] {
    return this.zones;
  }

  /** Lo que ningún corredor cruza. */
  blockingPolygons(): GeoJsonPolygon[] {
    return this.blocking;
  }

  /** La zona que contiene el punto, si hay una. */
  restrictionAt(point: LngLat): AirspaceZone | null {
    return zoneAt(point, this.zones.filter(isBlocking));
  }

  /** RF-06 y RF-07: ninguna central queda dentro de una zona legal. */
  assertHubLocation(point: LngLat): void {
    const zone = this.restrictionAt(point);
    if (zone) {
      throw new BadRequestException(
        `${HUB_IN_PROHIBITED_AIRSPACE} (${zone.name})`,
      );
    }
  }

  /** Para el mapa: cada zona con su regla y su fuente. */
  view() {
    return this.zones.map((zone) => ({
      id: zone.id ?? null,
      code: zone.code,
      kind: zone.kind,
      name: zone.name,
      legalBasis: zone.legalBasis,
      source: zone.source,
      blocking: isBlocking(zone),
      circle: zone.circle ?? null,
      polygon: zone.polygon,
    }));
  }

  private use(zones: AirspaceZone[]): void {
    this.zones = zones;
    this.blocking = blockingPolygons(zones);
  }
}

function toZone(row: LegalRow): AirspaceZone {
  const circle =
    row.shape === GeofenceShape.CIRCLE &&
    row.centerLatitude !== null &&
    row.centerLongitude !== null &&
    row.radiusM !== null
      ? {
          center: {
            latitude: Number(row.centerLatitude),
            longitude: Number(row.centerLongitude),
          },
          radiusM: row.radiusM,
        }
      : undefined;
  return {
    id: row.id,
    code: row.code,
    kind: row.class as unknown as AirspaceZoneKind,
    name: row.name,
    legalBasis: row.legalBasis,
    source: row.source,
    circle,
    polygon: JSON.parse(row.polygon) as GeoJsonPolygon,
  };
}

/** La primera vez, la base recibe las zonas de la semilla. */
export async function seedLegalZonesIfEmpty(
  runner: QueryRunner,
): Promise<void> {
  const [{ count }]: Array<{ count: number }> = await runner.query(
    `SELECT COUNT(*)::int AS count FROM geofences WHERE class = ANY($1)`,
    [LEGAL_GEOFENCE_CLASSES],
  );
  if (count === 0) {
    await insertLegalZones(runner, regionalAirspace());
  }
}

/**
 * RF-43 y RF-40: escribe las zonas de la semilla tal cual. La usan el primer
 * arranque y el reinicio del escenario.
 */
export async function insertLegalZones(
  runner: QueryRunner,
  zones: AirspaceZone[],
): Promise<void> {
  for (const zone of zones) {
    await runner.query(
      `INSERT INTO geofences (
         id, class, shape, code, name, "legalBasis", source,
         "centerLatitude", "centerLongitude", "radiusM", polygon, active
       ) VALUES (
         gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9,
         ST_SetSRID(ST_GeomFromGeoJSON($10), 4326), true
       )`,
      [
        zone.kind,
        zone.circle ? GeofenceShape.CIRCLE : GeofenceShape.POLYGON,
        zone.code,
        zone.name,
        zone.legalBasis,
        zone.source,
        zone.circle?.center.latitude ?? null,
        zone.circle?.center.longitude ?? null,
        zone.circle?.radiusM ?? null,
        JSON.stringify(zone.polygon),
      ],
    );
  }
}
