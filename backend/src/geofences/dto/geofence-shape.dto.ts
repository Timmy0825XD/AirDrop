import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { GeofenceShape } from '../../common/enums/geofence-shape.enum';
import {
  RADIUS_MAX_M,
  RADIUS_MIN_M,
  RADIUS_OUT_OF_RANGE,
  VERTICES_MAX,
  VERTICES_MIN,
  VERTICES_OUT_OF_RANGE,
} from '../geofence-shape.rules';

export class GeoPointDto {
  @IsNumber({}, { message: 'La latitud no es válida.' })
  @Min(-90, { message: 'La latitud no es válida.' })
  @Max(90, { message: 'La latitud no es válida.' })
  latitude: number;

  @IsNumber({}, { message: 'La longitud no es válida.' })
  @Min(-180, { message: 'La longitud no es válida.' })
  @Max(180, { message: 'La longitud no es válida.' })
  longitude: number;
}

const SHAPE_MESSAGE = { message: 'La forma debe ser círculo o polígono.' };

/**
 * RF-21: la geometría de una geovalla. Un círculo trae `center` y `radiusM`;
 * un polígono, `vertices` sin repetir el primero al final.
 */
abstract class GeometryFieldsDto {
  abstract shape?: GeofenceShape;

  @ValidateIf((dto: GeometryFieldsDto) => dto.shape === GeofenceShape.CIRCLE)
  @ValidateNested()
  @Type(() => GeoPointDto)
  center?: GeoPointDto;

  @ValidateIf((dto: GeometryFieldsDto) => dto.shape === GeofenceShape.CIRCLE)
  @IsInt({ message: 'El radio va en metros enteros.' })
  @Min(RADIUS_MIN_M, { message: RADIUS_OUT_OF_RANGE })
  @Max(RADIUS_MAX_M, { message: RADIUS_OUT_OF_RANGE })
  radiusM?: number;

  @ValidateIf((dto: GeometryFieldsDto) => dto.shape === GeofenceShape.POLYGON)
  @IsArray({ message: VERTICES_OUT_OF_RANGE })
  @ArrayMinSize(VERTICES_MIN, { message: VERTICES_OUT_OF_RANGE })
  @ArrayMaxSize(VERTICES_MAX, { message: VERTICES_OUT_OF_RANGE })
  @ValidateNested({ each: true })
  @Type(() => GeoPointDto)
  vertices?: GeoPointDto[];
}

export class GeofenceShapeDto extends GeometryFieldsDto {
  @IsEnum(GeofenceShape, SHAPE_MESSAGE)
  shape: GeofenceShape;
}

/** Al editar, la forma puede no venir: entonces se conserva. */
export class OptionalGeofenceShapeDto extends GeometryFieldsDto {
  @IsOptional()
  @IsEnum(GeofenceShape, SHAPE_MESSAGE)
  shape?: GeofenceShape;
}
