import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { CreateGeofenceDto } from './dto/create-geofence.dto';
import { UpdateGeofenceDto } from './dto/update-geofence.dto';
import { Geofence } from './geofence.entity';
import {
  assertGeoJsonPolygon,
  GeoJsonPolygon,
} from './geofences.rules';

type GeofenceRow = {
  id: string;
  name: string;
  reason: string;
  polygon: string;
  createdByUserId: string;
  createdAt: Date;
};

@Injectable()
export class GeofencesService {
  constructor(
    @InjectRepository(Geofence)
    private readonly geofences: Repository<Geofence>,
  ) {}

  async create(user: User, dto: CreateGeofenceDto) {
    this.assertActiveOperator(user);
    const polygon = assertGeoJsonPolygon(dto.polygon);
    const rows = (await this.geofences.query(
      `INSERT INTO geofences (id, name, reason, polygon, "createdByUserId")
       VALUES (
         gen_random_uuid(),
         $1,
         $2,
         ST_SetSRID(ST_GeomFromGeoJSON($3), 4326),
         $4
       )
       RETURNING id, name, reason, ST_AsGeoJSON(polygon) AS polygon, "createdByUserId", "createdAt"`,
      [dto.name.trim(), dto.reason.trim(), JSON.stringify(polygon), user.id],
    )) as GeofenceRow[];
    return this.toPublicGeofence(rows[0]);
  }

  async list(user: User) {
    this.assertActiveOperator(user);
    const rows = (await this.geofences.query(
      `SELECT id, name, reason, ST_AsGeoJSON(polygon) AS polygon, "createdByUserId", "createdAt"
       FROM geofences
       ORDER BY name ASC`,
    )) as GeofenceRow[];
    return rows.map((row) => this.toPublicGeofence(row));
  }

  async update(user: User, id: string, dto: UpdateGeofenceDto) {
    this.assertActiveOperator(user);
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
    const rows = (await this.geofences.query(
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
       RETURNING id, name, reason, ST_AsGeoJSON(polygon) AS polygon, "createdByUserId", "createdAt"`,
      [
        id,
        dto.name?.trim() ?? null,
        dto.reason?.trim() ?? null,
        polygon ? JSON.stringify(polygon) : null,
      ],
    )) as GeofenceRow[];
    return this.toPublicGeofence(rows[0]);
  }

  async remove(user: User, id: string) {
    this.assertActiveOperator(user);
    await this.requireGeofence(id);
    await this.geofences.delete(id);
  }

  private async requireGeofence(id: string) {
    const row = await this.geofences.findOne({ where: { id } });
    if (!row) {
      throw new NotFoundException('La geovalla no existe.');
    }
    return row;
  }

  private toPublicGeofence(row: GeofenceRow) {
    return {
      id: row.id,
      name: row.name,
      reason: row.reason,
      polygon: JSON.parse(row.polygon) as GeoJsonPolygon,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
    };
  }

  private assertActiveOperator(user: User): void {
    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        'Tu cuenta debe estar activa para gestionar geovallas.',
      );
    }
  }
}
