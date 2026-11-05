import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { IsTodayOrLater } from './is-today-or-later.validator';

export class RegisterMaintenanceDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El motivo es obligatorio.' })
  @MinLength(1, { message: 'El motivo es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;

  @IsDateString(
    { strict: true },
    { message: 'La fecha estimada no es una fecha válida.' },
  )
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha estimada debe ser AAAA-MM-DD.',
  })
  @IsTodayOrLater()
  estimatedEndDate: string;
}
