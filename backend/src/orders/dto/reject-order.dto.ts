import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class RejectOrderDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El motivo del rechazo es obligatorio.' })
  @MinLength(1, { message: 'El motivo del rechazo es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;
}
