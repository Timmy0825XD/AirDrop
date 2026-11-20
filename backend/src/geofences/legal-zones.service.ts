import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { AirspaceService } from '../airspace/airspace.service';
import { LEGAL_GEOFENCE_CLASSES } from '../common/enums/geofence-class.enum';
import { simClock } from '../common/clock/sim-clock';
import { User } from '../users/user.entity';
import { CreateLegalZoneDto, UpdateLegalZoneDto } from './dto/legal-zone.dto';
import { Geofence } from './geofence.entity';
import { GeofenceChange, GeofenceChangeAction } from './geofence-change.entity';
import { diffGeofence } from './geofence-change.rules';
import {
  GEOFENCE_COLUMNS,
  GeofenceRow,
  PublicGeofence,
  geometryParams,
  toPublicGeofence,
} from './geofence.presenter';
import { toGeofenceGeometry } from './geofence-shape.rules';
import { GeofencesService } from './geofences.service';

export const LEGAL_ZONE_NOT_FOUND = 'La zona legal no existe.';
export const LEGAL_CODE_TAKEN = 'Ya existe una zona legal con ese código.';
export const LEGAL_ALREADY_ACTIVE = 'La zona legal ya está activa.';
export const LEGAL_ALREADY_INACTIVE = 'La zona legal ya está desactivada.';

/**
 * RU-36 y CU-52: el administrador mantiene la copia de las zonas legales.
 * Las crea, las corrige y las desactiva; nunca las borra. Cada cambio
 * recarga el espacio aéreo en memoria y revisa los vuelos en el aire.
 */
@Injectable()
export class LegalZonesService {
  constructor(
    @InjectRepository(Geofence)
    private readonly geofences: Repository<Geofence>,
    @InjectRepository(GeofenceChange)
    private readonly changes: Repository<GeofenceChange>,
    private readonly operational: GeofencesService,
    private readonly airspace: AirspaceService,
  ) {}

  async create(user: User, dto: CreateLegalZoneDto): Promise<PublicGeofence> {
    const geometry = toGeofenceGeometry(dto);
    await this.operational.assertCoversNoHub(geometry.polygon);
    await this.assertCodeFree(dto.code);
    const zone = await this.geofences.manager.transaction(async (manager) => {
      const rows: GeofenceRow[] = await manager.query(
        `INSERT INTO geofences (
         id, class, shape, code, name, "legalBasis", source,
         "centerLatitude", "centerLongitude", "radiusM", polygon,
         active, "createdByUserId"
       ) VALUES (
         gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9,
         ST_SetSRID(ST_GeomFromGeoJSON($10), 4326), true, $11
       )
       RETURNING ${GEOFENCE_COLUMNS}`,
        [
          dto.class,
          geometry.shape,
          dto.code,
          dto.name,
          dto.legalBasis,
          dto.source,
          ...geometryParams(geometry),
          user.id,
        ],
      );
      const created = toPublicGeofence(rows[0]);
      await record(manager, created.id, user, GeofenceChangeAction.CREATED);
      return created;
    });
    await this.afterChange();
    return zone;
  }

  async update(
    user: User,
    id: string,
    dto: UpdateLegalZoneDto,
  ): Promise<PublicGeofence> {
    if (
      dto.class === undefined &&
      dto.name === undefined &&
      dto.legalBasis === undefined &&
      dto.source === undefined &&
      dto.shape === undefined
    ) {
      throw new BadRequestException(
        'Debes enviar al menos un campo para actualizar.',
      );
    }
    const before = await this.require(id);
    const geometry = dto.shape
      ? toGeofenceGeometry({ ...dto, shape: dto.shape })
      : null;
    if (geometry && before.active) {
      await this.operational.assertCoversNoHub(geometry.polygon);
    }
    const zone = await this.geofences.manager.transaction(async (manager) => {
      const [rows]: [GeofenceRow[], number] = await manager.query(
        `UPDATE geofences
       SET
         class = COALESCE($2::geofence_class, class),
         name = COALESCE($3, name),
         "legalBasis" = COALESCE($4, "legalBasis"),
         source = COALESCE($5, source),
         shape = CASE WHEN $6::text IS NULL THEN shape ELSE $6::geofence_shape END,
         "centerLatitude" = CASE WHEN $6::text IS NULL THEN "centerLatitude" ELSE $7 END,
         "centerLongitude" = CASE WHEN $6::text IS NULL THEN "centerLongitude" ELSE $8 END,
         "radiusM" = CASE WHEN $6::text IS NULL THEN "radiusM" ELSE $9 END,
         polygon = CASE
           WHEN $6::text IS NULL THEN polygon
           ELSE ST_SetSRID(ST_GeomFromGeoJSON($10), 4326)
         END,
         "updatedByUserId" = $11,
         "updatedAt" = NOW()
       WHERE id = $1
       RETURNING ${GEOFENCE_COLUMNS}`,
        [
          id,
          dto.class ?? null,
          dto.name ?? null,
          dto.legalBasis ?? null,
          dto.source ?? null,
          geometry?.shape ?? null,
          ...(geometry ? geometryParams(geometry) : [null, null, null, null]),
          user.id,
        ],
      );
      const after = toPublicGeofence(rows[0]);
      await record(
        manager,
        id,
        user,
        GeofenceChangeAction.UPDATED,
        dto.reason,
        diffGeofence(before, after),
      );
      return after;
    });
    await this.afterChange();
    return zone;
  }

  /** Deja de bloquear rutas; sigue en el catálogo y se puede reactivar. */
  async deactivate(
    user: User,
    id: string,
    reason: string,
  ): Promise<PublicGeofence> {
    const zone = await this.require(id);
    if (!zone.active) {
      throw new ConflictException(LEGAL_ALREADY_INACTIVE);
    }
    return this.setActive(user, zone, false, reason);
  }

  /** Vuelve a regir. Como al crearla, no puede cubrir una central. */
  async reactivate(
    user: User,
    id: string,
    reason: string,
  ): Promise<PublicGeofence> {
    const zone = await this.require(id);
    if (zone.active) {
      throw new ConflictException(LEGAL_ALREADY_ACTIVE);
    }
    await this.operational.assertCoversNoHub(zone.polygon);
    return this.setActive(user, zone, true, reason);
  }

  /** RU-36: el historial de una zona legal, lo último primero. */
  async history(id: string) {
    await this.require(id);
    return this.changes.find({
      where: { geofenceId: id },
      order: { createdAt: 'DESC' },
      select: {
        id: true,
        userId: true,
        action: true,
        reason: true,
        changes: true,
        createdAt: true,
      },
    });
  }

  private async setActive(
    user: User,
    before: PublicGeofence,
    active: boolean,
    reason: string,
  ): Promise<PublicGeofence> {
    const zone = await this.geofences.manager.transaction(async (manager) => {
      const [rows]: [GeofenceRow[], number] = await manager.query(
        `UPDATE geofences
         SET active = $2, "updatedByUserId" = $3, "updatedAt" = NOW()
         WHERE id = $1
         RETURNING ${GEOFENCE_COLUMNS}`,
        [before.id, active, user.id],
      );
      const after = toPublicGeofence(rows[0]);
      await record(
        manager,
        before.id,
        user,
        active
          ? GeofenceChangeAction.REACTIVATED
          : GeofenceChangeAction.DEACTIVATED,
        reason,
        diffGeofence(before, after),
      );
      return after;
    });
    await this.afterChange();
    return zone;
  }

  private async afterChange(): Promise<void> {
    await this.airspace.reload();
    await this.operational.recheckFlights();
  }

  private async require(id: string): Promise<PublicGeofence> {
    const rows: GeofenceRow[] = await this.geofences.query(
      `SELECT ${GEOFENCE_COLUMNS} FROM geofences
       WHERE id = $1 AND class = ANY($2)`,
      [id, LEGAL_GEOFENCE_CLASSES],
    );
    if (!rows.length) {
      throw new NotFoundException(LEGAL_ZONE_NOT_FOUND);
    }
    return toPublicGeofence(rows[0]);
  }

  private async assertCodeFree(code: string): Promise<void> {
    const rows: unknown[] = await this.geofences.query(
      `SELECT 1 FROM geofences WHERE code = $1`,
      [code],
    );
    if (rows.length) {
      throw new ConflictException(LEGAL_CODE_TAKEN);
    }
  }
}

async function record(
  manager: EntityManager,
  geofenceId: string,
  user: User,
  action: GeofenceChangeAction,
  reason: string | null = null,
  changes: GeofenceChange['changes'] = {},
): Promise<void> {
  await manager.query(
    `INSERT INTO geofence_changes
       (id, "geofenceId", "userId", action, reason, changes, "createdAt")
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5::jsonb, $6)`,
    [
      geofenceId,
      user.id,
      action,
      reason,
      JSON.stringify(changes),
      simClock.now(),
    ],
  );
}
