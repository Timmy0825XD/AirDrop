import { Type } from 'class-transformer';
import {
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { GeoJsonPolygonDto } from './create-geofence.dto';

export class UpdateGeofenceDto {
  @IsOptional()
  @IsString({ message: 'El nombre no es válido.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name?: string;

  @IsOptional()
  @IsString({ message: 'El motivo no es válido.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => GeoJsonPolygonDto)
  polygon?: GeoJsonPolygonDto;
}
