import {
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import { WeatherKind } from '../../common/enums/weather-kind.enum';

/** RF-32, CU-38: una celda de clima desde la consola. */
export class CreateWeatherDto {
  @IsEnum(WeatherKind, {
    message: 'El clima debe ser viento, lluvia o tormenta.',
  })
  kind: WeatherKind;

  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude: number;

  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude: number;

  @IsNumber({}, { message: 'El radio debe ser un número.' })
  @Min(0.3, { message: 'El radio va de 0,3 a 15 km.' })
  @Max(15, { message: 'El radio va de 0,3 a 15 km.' })
  radiusKm: number;

  @IsInt({ message: 'La duración va en minutos enteros.' })
  @Min(5, { message: 'La duración va de 5 a 240 minutos.' })
  @Max(240, { message: 'La duración va de 5 a 240 minutos.' })
  durationMin: number;

  @IsOptional()
  @IsNumber({}, { message: 'La velocidad del viento debe ser un número.' })
  @Min(1, { message: 'El viento va de 1 a 40 m/s.' })
  @Max(40, { message: 'El viento va de 1 a 40 m/s.' })
  windSpeedMs?: number;

  @IsOptional()
  @IsNumber({}, { message: 'Las ráfagas deben ser un número.' })
  @Min(1, { message: 'Las ráfagas van de 1 a 50 m/s.' })
  @Max(50, { message: 'Las ráfagas van de 1 a 50 m/s.' })
  windGustMs?: number;

  @IsOptional()
  @IsInt({ message: 'La dirección del viento va en grados enteros.' })
  @Min(0, { message: 'La dirección va de 0 a 359 grados.' })
  @Max(359, { message: 'La dirección va de 0 a 359 grados.' })
  windFromDeg?: number;
}
