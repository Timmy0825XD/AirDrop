import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { OperationalCategory } from '../../common/enums/operational-category.enum';
import { FIELD_LIMITS } from '../../common/field-limits';
import { OptionalGeofenceShapeDto } from './geofence-shape.dto';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/**
 * Lo que no viene se conserva. Para cambiar la forma se envía `shape` con
 * su geometría completa (centro y radio, o los vértices).
 */
export class UpdateGeofenceDto extends OptionalGeofenceShapeDto {
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
  @IsString({ message: 'El motivo no es válido.' })
  @MinLength(1, { message: 'El motivo no puede quedar vacío.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;

  @IsOptional()
  @IsEnum(OperationalCategory, { message: 'La categoría no es válida.' })
  category?: OperationalCategory;
}
