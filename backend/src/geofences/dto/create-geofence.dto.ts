import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { OperationalCategory } from '../../common/enums/operational-category.enum';
import { FIELD_LIMITS } from '../../common/field-limits';
import { GeofenceShapeDto } from './geofence-shape.dto';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/** RF-21: una geovalla operativa, en círculo o en vértices. */
export class CreateGeofenceDto extends GeofenceShapeDto {
  @Transform(trim)
  @IsString({ message: 'El nombre es obligatorio.' })
  @MinLength(1, { message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name: string;

  @Transform(trim)
  @IsString({ message: 'El motivo es obligatorio.' })
  @MinLength(1, { message: 'El motivo es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;

  @IsEnum(OperationalCategory, { message: 'La categoría no es válida.' })
  category: OperationalCategory;

  /** RF-21: vigencia opcional (hora simulada); sin ella, no vence. */
  @IsOptional()
  @IsDateString(
    {},
    { message: 'La vigencia debe ser una fecha y hora válida.' },
  )
  expiresAt?: string | null;
}
