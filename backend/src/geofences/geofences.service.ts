import {
  BadRequestException,
  Logger,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { simClock } from '../common/clock/sim-clock';
import {
  GeofenceClass,
  LEGAL_GEOFENCE_CLASSES,
} from '../common/enums/geofence-class.enum';
import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { OperationalCategory } from '../common/enums/operational-category.enum';
import { LngLat } from '../routing/routing.rules';
import { Hub } from '../hubs/hub.entity';
import { FlightClockService } from '../simulation/flight-clock.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { User } from '../users/user.entity';
import { CreateGeofenceDto } from './dto/create-geofence.dto';
import { UpdateGeofenceDto } from './dto/update-geofence.dto';
import { Geofence } from './geofence.entity';
import { toGeofenceGeometry } from './geofence-shape.rules';
import {
  GEOFENCE_COLUMNS,
  GeofenceRow,
  PublicGeofence,
  geometryParams,
  toPublicGeofence,
} from './geofence.presenter';
import {
  activeGeofenceSql,
  assertCoversNoHub,
  assertGeoJsonPolygon,
  GeoJsonPolygon,
  temporaryExpiry,
  validUntil,
} from './geofences.rules';

/** Una geovalla temporal tal como la ven la consola y el socket. */
export type TemporaryGeofenceJson = {
  id: string;
  name: string;
  reason: string;
  polygon: GeoJsonPolygon;
  createdAt: string;
  expiresAt: string;
};

export type NewTemporaryGeofence = {
  name: string;
  reason: string;
  polygon: unknown;
  durationMin: number;
};

export type GeofenceFilter = { class?: GeofenceClass; active?: boolean };

export const TEMPORARY_GEOFENCE_NOT_FOUND =
  'Esa geovalla temporal no existe o ya venció.';

const RETURNING = GEOFENCE_COLUMNS;

/** Cada cuánto (en hora simulada) se borran las geovallas temporales vencidas. */
const EXPIRY_SWEEP_MS = 15_000;

@Injectable()
export class GeofencesService implements OnModuleInit, OnModuleDestroy {
  constructor(
    @InjectRepository(Geofence)
    private readonly geofences: Repository<Geofence>,
    @InjectRepository(Hub)
    private readonly hubs: Repository<Hub>,
    private readonly flights: FlightClockService,
    private readonly publisher: TelemetryPublisher,
  ) {}

  private readonly logger = new Logger(GeofencesService.name);
  private timer: NodeJS.Timeout | null = null;

  onModuleInit(): void {
    this.timer = simClock.every(EXPIRY_SWEEP_MS, () => {
      void this.sweepExpired().catch((error: unknown) => {
        const message = error instanceof Error ? error.message : 'geovallas';
        this.logger.warn(`No se pudieron vencer las geovallas: ${message}`);
      });
    });
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * RF-33 y CU-43: una geovalla nueva o editada cambia la ruta de los drones
   * en el aire que la tengan en el tramo que les falta. Si falla, la geovalla
   * queda guardada igual.
   */
  async recheckFlights(): Promise<void> {
    try {
      await this.flights.recheckRoutes();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'rutas';
      this.logger.warn(`No se pudieron revisar los vuelos: ${message}`);
    }
  }

  /** RF-21: una geovalla operativa, en círculo o en vértices. */
  async create(user: User, dto: CreateGeofenceDto) {
    const geometry = toGeofenceGeometry(dto);
    const expiresAt = validUntil(dto.expiresAt, simClock.now());
    await this.assertCoversNoHub(geometry.polygon);
    const rows: GeofenceRow[] = await this.geofences.query(
      `INSERT INTO geofences (
         id, class, shape, name, reason, category,
         "centerLatitude", "centerLongitude", "radiusM", polygon, "createdByUserId",
         "expiresAt"
       )
       VALUES (
         gen_random_uuid(), 'operational', $1, $2, $3, $4, $5, $6, $7,
         ST_SetSRID(ST_GeomFromGeoJSON($8), 4326), $9, $10
       )
       RETURNING ${RETURNING}`,
      [
        geometry.shape,
        dto.name.trim(),
        dto.reason.trim(),
        dto.category,
        ...geometryParams(geometry),
        user.id,
        expiresAt,
      ],
    );
    await this.recheckFlights();
    return toPublicGeofence(rows[0]);
  }

  /**
   * RU-19: lo que ven el operador y el admin. Todas las legales (también las
   * desactivadas, con `active`) y las operativas vigentes. Las temporales son
   * de la consola y no salen aquí.
   */
  async catalog(filter: GeofenceFilter = {}): Promise<PublicGeofence[]> {
    const rows: GeofenceRow[] = await this.geofences.query(
      `SELECT ${RETURNING}
       FROM geofences
       WHERE (
         class = ANY($1)
         OR (class = 'operational' AND ("expiresAt" IS NULL OR "expiresAt" > $2))
       )
         AND ($3::geofence_class IS NULL OR class = $3)
         AND ($4::boolean IS NULL OR active = $4)
       ORDER BY class ASC, name ASC`,
      [
        LEGAL_GEOFENCE_CLASSES,
        simClock.now(),
        filter.class ?? null,
        filter.active ?? null,
      ],
    );
    return rows.map((row) => toPublicGeofence(row));
  }

  /** La ficha completa de una geovalla del catálogo. */
  async findOne(id: string): Promise<PublicGeofence> {
    const rows: GeofenceRow[] = await this.geofences.query(
      `SELECT ${RETURNING} FROM geofences
       WHERE id = $1 AND class <> 'temporary'`,
      [id],
    );
    if (!rows.length) {
      throw new NotFoundException('La geovalla no existe.');
    }
    return toPublicGeofence(rows[0]);
  }

  /** Las operativas y temporales vigentes (RF-36): lo que dibuja el mapa de flota. */
  async list(): Promise<PublicGeofence[]> {
    const rows = (await this.geofences.query(
      `SELECT ${RETURNING}
       FROM geofences
       WHERE ${activeGeofenceSql('$1')}
       ORDER BY name ASC`,
      [simClock.now()],
    )) as GeofenceRow[];
    return rows.map((row) => toPublicGeofence(row));
  }

  /** RF-36: las geovallas temporales que rigen ahora, la que vence antes primero. */
  async listTemporary(): Promise<TemporaryGeofenceJson[]> {
    const rows = (await this.geofences.query(
      `SELECT ${RETURNING}
       FROM geofences
       WHERE class = 'temporary' AND "expiresAt" > $1
       ORDER BY "expiresAt" ASC`,
      [simClock.now()],
    )) as GeofenceRow[];
    return rows.map((row) => presentTemporary(toPublicGeofence(row)));
  }

  /**
   * RF-36 y CU-38: una geovalla que la consola lanza por un tiempo (por
   * ejemplo, un evento aéreo). Mientras dure cuenta como cualquier geovalla
   * y puede cambiar rutas en vuelo (RF-33).
   */
  async createTemporary(
    userId: string,
    input: NewTemporaryGeofence,
  ): Promise<TemporaryGeofenceJson> {
    const polygon = assertGeoJsonPolygon(input.polygon);
    await this.assertCoversNoHub(polygon);
    // Hora simulada (RF-31) en las dos fechas: la duración se cuenta con ellas.
    const now = simClock.now();
    const expiresAt = temporaryExpiry(now, input.durationMin);
    const rows = (await this.geofences.query(
      `INSERT INTO geofences (id, class, name, reason, polygon, "createdByUserId", "createdAt", "expiresAt")
       VALUES (
         gen_random_uuid(),
         'temporary',
         $1,
         $2,
         ST_SetSRID(ST_GeomFromGeoJSON($3), 4326),
         $4,
         $5,
         $6
       )
       RETURNING ${RETURNING}`,
      [
        input.name.trim(),
        input.reason.trim(),
        JSON.stringify(polygon),
        userId,
        now,
        expiresAt,
      ],
    )) as GeofenceRow[];
    const fence = presentTemporary(toPublicGeofence(rows[0]));
    await this.publisher.publish({
      type: 'geofence',
      action: 'created',
      geofence: fence,
    });
    await this.recheckFlights();
    return fence;
  }

  /** La consola levanta una geovalla temporal antes de que venza. */
  async endTemporary(id: string): Promise<TemporaryGeofenceJson> {
    const [rows] = (await this.geofences.query(
      `DELETE FROM geofences
       WHERE id = $1 AND class = 'temporary' AND "expiresAt" > $2
       RETURNING ${RETURNING}`,
      [id, simClock.now()],
    )) as [GeofenceRow[], number];
    if (!rows.length) {
      throw new NotFoundException(TEMPORARY_GEOFENCE_NOT_FOUND);
    }
    const fence = presentTemporary(toPublicGeofence(rows[0]));
    await this.announceEnded(fence);
    return fence;
  }

  /** RF-36: al vencer desaparece sola, y se cuenta una sola vez. */
  async sweepExpired(): Promise<number> {
    const [rows] = (await this.geofences.query(
      `DELETE FROM geofences
       WHERE "expiresAt" IS NOT NULL AND "expiresAt" <= $1
       RETURNING ${RETURNING}`,
      [simClock.now()],
    )) as [GeofenceRow[], number];
    // RF-36: la línea de tiempo cuenta las temporales; una operativa que
    // vence (RF-21) solo deja de regir.
    for (const row of rows.filter((r) => r.class === GeofenceClass.TEMPORARY)) {
      await this.announceEnded(presentTemporary(toPublicGeofence(row)));
    }
    return rows.length;
  }

  /**
   * RF-40: el reinicio borra las geovallas temporales sin contarlas (la línea
   * de tiempo también se vacía).
   */
  async clearTemporary(manager: EntityManager): Promise<number> {
    const [, count] = (await manager.query(
      `DELETE FROM geofences WHERE class = 'temporary'`,
    )) as [unknown[], number];
    return count;
  }

  async update(user: User, id: string, dto: UpdateGeofenceDto) {
    if (
      dto.name === undefined &&
      dto.reason === undefined &&
      dto.category === undefined &&
      dto.shape === undefined &&
      dto.expiresAt === undefined
    ) {
      throw new BadRequestException(
        'Debes enviar al menos un campo para actualizar.',
      );
    }
    await this.requireGeofence(id);
    const geometry = dto.shape
      ? toGeofenceGeometry({ ...dto, shape: dto.shape })
      : null;
    if (geometry) {
      await this.assertCoversNoHub(geometry.polygon);
    }
    // En UPDATE, TypeORM devuelve `[rows, rowCount]` (PostgresQueryRunner)
    // y no las filas: sin desestructurar, `rows[0]` es el arreglo completo
    // y `toPublicGeofence` recibiría `polygon: undefined` → 500 en JSON.parse.
    const [rows] = (await this.geofences.query(
      `UPDATE geofences
       SET
         name = COALESCE($2, name),
         reason = COALESCE($3, reason),
         category = COALESCE($4::operational_category, category),
         shape = CASE WHEN $5::text IS NULL THEN shape ELSE $5::geofence_shape END,
         "centerLatitude" = CASE WHEN $5::text IS NULL THEN "centerLatitude" ELSE $6 END,
         "centerLongitude" = CASE WHEN $5::text IS NULL THEN "centerLongitude" ELSE $7 END,
         "radiusM" = CASE WHEN $5::text IS NULL THEN "radiusM" ELSE $8 END,
         polygon = CASE
           WHEN $5::text IS NULL THEN polygon
           ELSE ST_SetSRID(ST_GeomFromGeoJSON($9), 4326)
         END,
         "updatedByUserId" = $10,
         "expiresAt" = CASE WHEN $11::boolean THEN $12::timestamptz ELSE "expiresAt" END,
         "updatedAt" = NOW()
       WHERE id = $1
       RETURNING ${RETURNING}`,
      [
        id,
        dto.name?.trim() ?? null,
        dto.reason?.trim() ?? null,
        dto.category ?? null,
        geometry?.shape ?? null,
        ...(geometry ? geometryParams(geometry) : [null, null, null, null]),
        user.id,
        dto.expiresAt !== undefined,
        validUntil(dto.expiresAt, simClock.now()),
      ],
    )) as [GeofenceRow[], number];
    if (geometry) {
      await this.recheckFlights();
    }
    return toPublicGeofence(rows[0]);
  }

  async remove(id: string) {
    await this.requireGeofence(id);
    const [rows] = (await this.geofences.query(
      `DELETE FROM geofences WHERE id = $1 RETURNING ${RETURNING}`,
      [id],
    )) as [GeofenceRow[], number];
    if (rows[0]?.expiresAt) {
      // Una temporal que quita el operador: el radar deja de dibujarla.
      await this.announceEnded(presentTemporary(toPublicGeofence(rows[0])));
    }
  }

  private async announceEnded(fence: TemporaryGeofenceJson): Promise<void> {
    await this.publisher.publish({
      type: 'geofence',
      action: 'ended',
      geofence: fence,
    });
  }

  /** Todas las centrales, también las suspendidas: pueden reactivarse. */
  async assertCoversNoHub(polygon: GeoJsonPolygon): Promise<void> {
    const hubs = await this.hubs.find({
      select: { id: true, name: true, latitude: true, longitude: true },
    });
    assertCoversNoHub(polygon, hubs);
  }

  /**
   * El operador solo edita operativas: las legales las mantiene el
   * administrador (RU-36) y las temporales, la consola (RF-36).
   */
  private async requireGeofence(id: string) {
    const row = await this.geofences.findOne({ where: { id } });
    if (!row || row.class !== GeofenceClass.OPERATIONAL) {
      throw new NotFoundException('La geovalla no existe.');
    }
    return row;
  }
}

/** Solo para geovallas con vencimiento. */
export function presentTemporary(fence: PublicGeofence): TemporaryGeofenceJson {
  return {
    id: fence.id,
    name: fence.name,
    reason: fence.reason ?? '',
    polygon: fence.polygon,
    createdAt: new Date(fence.createdAt).toISOString(),
    expiresAt: (fence.expiresAt ?? simClock.now()).toISOString(),
  };
}
