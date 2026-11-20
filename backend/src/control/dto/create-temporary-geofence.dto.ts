import { Transform, Type } from 'class-transformer';
import {
  Equals,
  IsArray,
  IsInt,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class GeoJsonPolygonDto {
  @Equals('Polygon', {
    message: 'El polígono debe ser GeoJSON de tipo Polygon.',
  })
  type: 'Polygon';

  @IsArray({ message: 'El polígono debe incluir coordenadas.' })
  coordinates: number[][][];
}

/** RF-36, CU-38: una geovalla que vence sola, desde la consola. */
export class CreateTemporaryGeofenceDto {
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

  @ValidateNested()
  @Type(() => GeoJsonPolygonDto)
  polygon: GeoJsonPolygonDto;

  @IsInt({ message: 'La duración va en minutos enteros.' })
  @Min(5, { message: 'La duración va de 5 a 240 minutos.' })
  @Max(240, { message: 'La duración va de 5 a 240 minutos.' })
  durationMin: number;
}
