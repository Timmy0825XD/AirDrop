import { Transform } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  GeofenceClass,
  LEGAL_GEOFENCE_CLASSES,
} from '../../common/enums/geofence-class.enum';
import { FIELD_LIMITS } from '../../common/field-limits';
import {
  GeofenceShapeDto,
  OptionalGeofenceShapeDto,
} from './geofence-shape.dto';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

const lower = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().toLowerCase() : value;

const CLASS_MESSAGE = {
  message: 'La clase debe ser aeródromo, prohibida o helipuerto.',
};

/** RU-36: el motivo de cada cambio a una zona legal. */
export class ChangeReasonDto {
  @Transform(trim)
  @IsString({ message: 'El motivo del cambio es obligatorio.' })
  @MinLength(1, { message: 'El motivo del cambio es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;
}

/** RU-36 y CU-52: una zona legal nueva, con su base legal y su fuente. */
export class CreateLegalZoneDto extends GeofenceShapeDto {
  @Transform(lower)
  @IsString({ message: 'El código es obligatorio.' })
  @Matches(/^[a-z0-9]+(-[a-z0-9]+)*$/, {
    message: 'El código va en minúsculas, números y guiones (cai-hurtado).',
  })
  @MaxLength(FIELD_LIMITS.geofenceCode, {
    message: `El código no puede superar ${FIELD_LIMITS.geofenceCode} caracteres.`,
  })
  code: string;

  @IsIn(LEGAL_GEOFENCE_CLASSES, CLASS_MESSAGE)
  class: GeofenceClass;

  @Transform(trim)
  @IsString({ message: 'El nombre es obligatorio.' })
  @MinLength(1, { message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name: string;

  @Transform(trim)
  @IsString({ message: 'La base legal es obligatoria.' })
  @MinLength(1, { message: 'La base legal es obligatoria.' })
  @MaxLength(FIELD_LIMITS.legalReference, {
    message: `La base legal no puede superar ${FIELD_LIMITS.legalReference} caracteres.`,
  })
  legalBasis: string;

  @Transform(trim)
  @IsString({ message: 'La fuente es obligatoria.' })
  @MinLength(1, { message: 'La fuente es obligatoria.' })
  @MaxLength(FIELD_LIMITS.legalReference, {
    message: `La fuente no puede superar ${FIELD_LIMITS.legalReference} caracteres.`,
  })
  source: string;
}

/**
 * Lo que no viene se conserva; el código no cambia. El motivo del cambio
 * siempre es obligatorio (RU-36).
 */
export class UpdateLegalZoneDto extends OptionalGeofenceShapeDto {
  @Transform(trim)
  @IsString({ message: 'El motivo del cambio es obligatorio.' })
  @MinLength(1, { message: 'El motivo del cambio es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;

  @IsOptional()
  @IsIn(LEGAL_GEOFENCE_CLASSES, CLASS_MESSAGE)
  class?: GeofenceClass;

  @IsOptional()
  @Transform(trim)
  @IsString({ message: 'El nombre no es válido.' })
  @MinLength(1, { message: 'El nombre no puede quedar vacío.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name?: string;

  @IsOptional()
  @Transform(trim)
  @IsString({ message: 'La base legal no es válida.' })
  @MinLength(1, { message: 'La base legal no puede quedar vacía.' })
  @MaxLength(FIELD_LIMITS.legalReference, {
    message: `La base legal no puede superar ${FIELD_LIMITS.legalReference} caracteres.`,
  })
  legalBasis?: string;

  @IsOptional()
  @Transform(trim)
  @IsString({ message: 'La fuente no es válida.' })
  @MinLength(1, { message: 'La fuente no puede quedar vacía.' })
  @MaxLength(FIELD_LIMITS.legalReference, {
    message: `La fuente no puede superar ${FIELD_LIMITS.legalReference} caracteres.`,
  })
  source?: string;
}
