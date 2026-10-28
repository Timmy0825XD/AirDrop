import { Type } from 'class-transformer';
import {
  Equals,
  IsArray,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class GeoJsonPolygonDto {
  @Equals('Polygon', { message: 'El polígono debe ser GeoJSON de tipo Polygon.' })
  type: 'Polygon';

  @IsArray({ message: 'El polígono debe incluir coordenadas.' })
  coordinates: number[][][];
}

export class CreateGeofenceDto {
  @IsString({ message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.geofenceName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.geofenceName} caracteres.`,
  })
  name: string;

  @IsString({ message: 'El motivo es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;

  @ValidateNested()
  @Type(() => GeoJsonPolygonDto)
  polygon: GeoJsonPolygonDto;
}
