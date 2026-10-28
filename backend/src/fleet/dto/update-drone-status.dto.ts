import { IsIn, IsOptional, IsString, Matches, MaxLength } from 'class-validator';
import { DroneStatus } from '../../common/enums/drone-status.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

export const OPERATOR_DRONE_STATUSES = [
  DroneStatus.AVAILABLE,
  DroneStatus.MAINTENANCE,
  DroneStatus.OUT_OF_SERVICE,
] as const;

export class UpdateDroneStatusDto {
  @IsIn(OPERATOR_DRONE_STATUSES, {
    message:
      'El estado debe ser available, maintenance o out_of_service.',
  })
  status: (typeof OPERATOR_DRONE_STATUSES)[number];

  @IsOptional()
  @IsString({ message: 'El motivo no es válido.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;

  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha estimada debe ser AAAA-MM-DD.',
  })
  estimatedEndDate?: string;
}
