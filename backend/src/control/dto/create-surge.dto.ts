import {
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  Max,
  Min,
} from 'class-validator';
import {
  SURGE_MAX,
  SURGE_MAX_RADIUS_KM,
  SURGE_MIN,
  SURGE_MIN_RADIUS_KM,
} from '../sim-actors.rules';

const COUNT_MESSAGE = `El pico va de ${SURGE_MIN} a ${SURGE_MAX} urgencias.`;
const RADIUS_MESSAGE = `El radio va de 0,3 a ${SURGE_MAX_RADIUS_KM} km.`;

/** RF-36: pico de urgencias dentro de un círculo del mapa. */
export class CreateSurgeDto {
  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude: number;

  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude: number;

  @IsNumber({}, { message: 'El radio debe ser un número.' })
  @Min(SURGE_MIN_RADIUS_KM, { message: RADIUS_MESSAGE })
  @Max(SURGE_MAX_RADIUS_KM, { message: RADIUS_MESSAGE })
  radiusKm: number;

  @IsInt({ message: COUNT_MESSAGE })
  @Min(SURGE_MIN, { message: COUNT_MESSAGE })
  @Max(SURGE_MAX, { message: COUNT_MESSAGE })
  count: number;
}
