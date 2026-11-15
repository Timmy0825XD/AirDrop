import { Type } from 'class-transformer';
import {
  IsInt,
  IsLatitude,
  IsLongitude,
  IsOptional,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  UNIDENTIFIED_MAX_MINUTES,
  UNIDENTIFIED_MIN_MINUTES,
} from '../unidentified.rules';

const DURATION_MESSAGE = `Dura de ${UNIDENTIFIED_MIN_MINUTES} a ${UNIDENTIFIED_MAX_MINUTES} minutos.`;

class PointDto {
  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude: number;

  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude: number;
}

/** RF-36: un dron no identificado; sin `from` y `to`, cruza por un corredor. */
export class LaunchUnidentifiedDto {
  @IsInt({ message: DURATION_MESSAGE })
  @Min(UNIDENTIFIED_MIN_MINUTES, { message: DURATION_MESSAGE })
  @Max(UNIDENTIFIED_MAX_MINUTES, { message: DURATION_MESSAGE })
  durationMin: number;

  @ValidateIf((dto: LaunchUnidentifiedDto) => dto.to != null)
  @ValidateNested()
  @Type(() => PointDto)
  from?: PointDto;

  @ValidateIf((dto: LaunchUnidentifiedDto) => dto.from != null)
  @IsOptional()
  @ValidateNested()
  @Type(() => PointDto)
  to?: PointDto;
}
