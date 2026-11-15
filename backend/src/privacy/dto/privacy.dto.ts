import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { PrescriptionAccessPurpose } from '../../common/enums/prescription-access-purpose.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

export class AcceptPolicyDto {
  @IsString({ message: 'Indica la versión de la política que aceptas.' })
  @MaxLength(FIELD_LIMITS.policyVersion)
  version: string;
}

/** CU-46: revocar o suprimir pide la contraseña. */
export class ConfirmWithPasswordDto {
  @IsString({ message: 'Escribe tu contraseña para confirmar.' })
  @MinLength(1, { message: 'Escribe tu contraseña para confirmar.' })
  @MaxLength(FIELD_LIMITS.passwordMax)
  password: string;
}

const DATE = /^\d{4}-\d{2}-\d{2}$/;

/** CU-47: filtros del registro de accesos. */
export class AccessLogQueryDto {
  @IsOptional()
  @IsUUID('4', { message: 'El pedido no es válido.' })
  orderId?: string;

  @IsOptional()
  @IsUUID('4', { message: 'La cuenta no es válida.' })
  userId?: string;

  @IsOptional()
  @Matches(DATE, { message: 'La fecha inicial debe ser AAAA-MM-DD.' })
  from?: string;

  @IsOptional()
  @Matches(DATE, { message: 'La fecha final debe ser AAAA-MM-DD.' })
  to?: string;
}

/** RF-51: para qué se abre la fórmula; sin él, lo deduce el estado del pedido. */
export class PrescriptionPurposeQueryDto {
  @IsOptional()
  @IsEnum(PrescriptionAccessPurpose, {
    message: 'El propósito debe ser autorizar, histórico o reclamo.',
  })
  purpose?: PrescriptionAccessPurpose;
}
