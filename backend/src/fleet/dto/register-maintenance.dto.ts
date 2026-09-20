import { IsString, Matches, MaxLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class RegisterMaintenanceDto {
  @IsString({ message: 'El motivo es obligatorio.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason: string;

  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha estimada debe ser AAAA-MM-DD.',
  })
  estimatedEndDate: string;
}
