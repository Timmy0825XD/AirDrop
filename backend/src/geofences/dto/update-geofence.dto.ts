import { Transform, Type } from 'class-transformer';
import {
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { GeoJsonPolygonDto } from './create-geofence.dto';

export class UpdateGeofenceDto {
  // Puede no venir (se conserva), pero si viene no va en blanco.
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El nombre no es válido.' })
  @MinLength(1, { message: 'El nombre no puede quedar vacío.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El motivo no es válido.' })
  @MinLength(1, { message: 'El motivo no puede quedar vacío.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => GeoJsonPolygonDto)
  polygon?: GeoJsonPolygonDto;
}
