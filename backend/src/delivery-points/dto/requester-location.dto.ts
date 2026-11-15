import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';

/**
 * RU-02: dónde está el solicitante al pedir. Solo sirve para revisar que no
 * esté en la ciudad; no se guarda (el destino es el punto).
 */
export class RequesterLocationDto {
  @Type(() => Number)
  @IsLatitude({ message: 'Tu ubicación no es válida.' })
  latitude: number;

  @Type(() => Number)
  @IsLongitude({ message: 'Tu ubicación no es válida.' })
  longitude: number;
}
