import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { HubStatus } from '../../common/enums/hub-status.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

export const HUB_DECISION_STATUSES = [
  HubStatus.APPROVED,
  HubStatus.REJECTED,
] as const;

export class DecideHubDto {
  @IsIn(HUB_DECISION_STATUSES, {
    message: 'La decisión debe ser approved o rejected.',
  })
  status: (typeof HUB_DECISION_STATUSES)[number];

  @IsOptional()
  @IsString({ message: 'El motivo no es válido.' })
  @MaxLength(FIELD_LIMITS.reason, {
    message: `El motivo no puede superar ${FIELD_LIMITS.reason} caracteres.`,
  })
  reason?: string;
}
