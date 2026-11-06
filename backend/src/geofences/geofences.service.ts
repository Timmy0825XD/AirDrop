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
import { Hub } from '../hubs/hub.entity';
import { FlightClockService } from '../simulation/flight-clock.service';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { User } from '../users/user.entity';
import { CreateGeofenceDto } from './dto/create-geofence.dto';
import { UpdateGeofenceDto } from './dto/update-geofence.dto';
import { Geofence } from './geofence.entity';
import {
  activeGeofenceSql,
  assertCoversNoHub,
  assertGeoJsonPolygon,
  GeoJsonPolygon,
  temporaryExpiry,
} from './geofences.rules';

type GeofenceRow = {
  id: string;
  name: string;
  reason: string;
  polygon: string;
  createdByUserId: string;
  createdAt: Date;
  expiresAt: Date | null;
};

export type PublicGeofence = {
  id: string;
  name: string;
  reason: string;
  polygon: GeoJsonPolygon;
  createdByUserId: string;
  createdAt: Date;
  /** RF-36: con fecha es temporal; `null`, del operador. */
  expiresAt: Date | null;
};

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

export const TEMPORARY_GEOFENCE_NOT_FOUND =
  'Esa geovalla temporal no existe o ya venció.';

const RETURNING = `id, name, reason, ST_AsGeoJSON(polygon) AS polygon, "createdByUserId", "createdAt", "expiresAt"`;

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
  private async recheckFlights(): Promise<void> {
    try {
      await this.flights.recheckRoutes();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'rutas';
      this.logger.warn(`No se pudieron revisar los vuelos: ${message}`);
    }
  }

  async create(user: User, dto: CreateGeofenceDto) {
    const polygon = assertGeoJsonPolygon(dto.polygon);
    await this.assertCoversNoHub(polygon);
    const rows = (await this.geofences.query(
      `INSERT INTO geofences (id, name, reason, polygon, "createdByUserId")
       VALUES (
         gen_random_uuid(),
         $1,
         $2,
         ST_SetSRID(ST_GeomFromGeoJSON($3), 4326),
         $4
       )
       RETURNING ${RETURNING}`,
      [dto.name.trim(), dto.reason.trim(), JSON.stringify(polygon), user.id],
    )) as GeofenceRow[];
    await this.recheckFlights();
    return this.toPublicGeofence(rows[0]);
  }

  /** Las del operador y las temporales vigentes (RF-36), con `expiresAt`. */
  async list(): Promise<PublicGeofence[]> {
    const rows = (await this.geofences.query(
      `SELECT ${RETURNING}
       FROM geofences
       WHERE ${activeGeofenceSql('$1')}
       ORDER BY name ASC`,
      [simClock.now()],
    )) as GeofenceRow[];
    return rows.map((row) => this.toPublicGeofence(row));
  }

  /** RF-36: las geovallas temporales que rigen ahora, la que vence antes primero. */
  async listTemporary(): Promise<TemporaryGeofenceJson[]> {
    const rows = (await this.geofences.query(
      `SELECT ${RETURNING}
       FROM geofences
       WHERE "expiresAt" IS NOT NULL AND "expiresAt" > $1
       ORDER BY "expiresAt" ASC`,
      [simClock.now()],
    )) as GeofenceRow[];
    return rows.map((row) => presentTemporary(this.toPublicGeofence(row)));
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
      `INSERT INTO geofences (id, name, reason, polygon, "createdByUserId", "createdAt", "expiresAt")
       VALUES (
         gen_random_uuid(),
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
    const fence = presentTemporary(this.toPublicGeofence(rows[0]));
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
       WHERE id = $1 AND "expiresAt" IS NOT NULL AND "expiresAt" > $2
       RETURNING ${RETURNING}`,
      [id, simClock.now()],
    )) as [GeofenceRow[], number];
    if (!rows.length) {
      throw new NotFoundException(TEMPORARY_GEOFENCE_NOT_FOUND);
    }
    const fence = presentTemporary(this.toPublicGeofence(rows[0]));
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
    for (const row of rows) {
      await this.announceEnded(presentTemporary(this.toPublicGeofence(row)));
    }
    return rows.length;
  }

  /**
   * RF-40: el reinicio borra las geovallas temporales sin contarlas (la línea
   * de tiempo también se vacía).
   */
  async clearTemporary(manager: EntityManager): Promise<number> {
    const [, count] = (await manager.query(
      `DELETE FROM geofences WHERE "expiresAt" IS NOT NULL`,
    )) as [unknown[], number];
    return count;
  }

  async update(id: string, dto: UpdateGeofenceDto) {
    if (
      dto.name === undefined &&
      dto.reason === undefined &&
      dto.polygon === undefined
    ) {
      throw new BadRequestException(
        'Debes enviar al menos un campo para actualizar.',
      );
    }
    await this.requireGeofence(id);
    const polygon = dto.polygon
      ? assertGeoJsonPolygon(dto.polygon)
      : undefined;
    if (polygon) {
      await this.assertCoversNoHub(polygon);
    }
    // En UPDATE, TypeORM devuelve `[rows, rowCount]` (PostgresQueryRunner)
    // y no las filas: sin desestructurar, `rows[0]` es el arreglo completo
    // y `toPublicGeofence` recibiría `polygon: undefined` → 500 en JSON.parse.
    const [rows] = (await this.geofences.query(
      `UPDATE geofences
       SET
         name = COALESCE($2, name),
         reason = COALESCE($3, reason),
         polygon = CASE
           WHEN $4::text IS NULL THEN polygon
           ELSE ST_SetSRID(ST_GeomFromGeoJSON($4), 4326)
         END,
         "updatedAt" = NOW()
       WHERE id = $1
       RETURNING ${RETURNING}`,
      [
        id,
        dto.name?.trim() ?? null,
        dto.reason?.trim() ?? null,
        polygon ? JSON.stringify(polygon) : null,
      ],
    )) as [GeofenceRow[], number];
    if (polygon) {
      await this.recheckFlights();
    }
    return this.toPublicGeofence(rows[0]);
  }

  async remove(id: string) {
    await this.requireGeofence(id);
    const [rows] = (await this.geofences.query(
      `DELETE FROM geofences WHERE id = $1 RETURNING ${RETURNING}`,
      [id],
    )) as [GeofenceRow[], number];
    if (rows[0]?.expiresAt) {
      // Una temporal que quita el operador: el radar deja de dibujarla.
      await this.announceEnded(
        presentTemporary(this.toPublicGeofence(rows[0])),
      );
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
  private async assertCoversNoHub(polygon: GeoJsonPolygon): Promise<void> {
    const hubs = await this.hubs.find({
      select: { id: true, name: true, latitude: true, longitude: true },
    });
    assertCoversNoHub(polygon, hubs);
  }

  private async requireGeofence(id: string) {
    const row = await this.geofences.findOne({ where: { id } });
    if (!row) {
      throw new NotFoundException('La geovalla no existe.');
    }
    return row;
  }

  private toPublicGeofence(row: GeofenceRow): PublicGeofence {
    return {
      id: row.id,
      name: row.name,
      reason: row.reason,
      polygon: JSON.parse(row.polygon) as GeoJsonPolygon,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
      expiresAt: row.expiresAt ? new Date(row.expiresAt) : null,
    };
  }
}

/** Solo para geovallas con vencimiento. */
export function presentTemporary(fence: PublicGeofence): TemporaryGeofenceJson {
  return {
    id: fence.id,
    name: fence.name,
    reason: fence.reason,
    polygon: fence.polygon,
    createdAt: new Date(fence.createdAt).toISOString(),
    expiresAt: (fence.expiresAt ?? simClock.now()).toISOString(),
  };
}
