import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

/** Motivo opcional de "No puedo atenderla" (sin dron, sin personal, sin lote). */
export class DeclineOrderDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' && value.trim() ? value.trim() : undefined,
  )
  @IsOptional()
  @IsString({ message: 'El motivo debe ser texto.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;
}
