import { IsString, Length, Matches } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

/** Código de 6 dígitos que llegó al correo nuevo. */
export class ConfirmEmailDto {
  @IsString({ message: 'El código es obligatorio.' })
  @Length(FIELD_LIMITS.otpDigits, FIELD_LIMITS.otpDigits, {
    message: 'El código debe tener 6 dígitos.',
  })
  @Matches(/^\d{6}$/, { message: 'El código debe tener 6 dígitos.' })
  code: string;
}
