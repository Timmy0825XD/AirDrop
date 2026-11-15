import { Transform, Type } from 'class-transformer';
import {
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

/** RU-02: el GPS del solicitante y, si ya lo eligió, el medicamento. */
export class CoverageQueryDto {
  @ValidateIf((dto: CoverageQueryDto) => dto.longitude != null)
  @Type(() => Number)
  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude?: number;

  @ValidateIf((dto: CoverageQueryDto) => dto.latitude != null)
  @Type(() => Number)
  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude?: number;

  /** Para la alternativa terrestre: las centrales que lo tienen. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(FIELD_LIMITS.medicationName)
  medicationName?: string;
}
