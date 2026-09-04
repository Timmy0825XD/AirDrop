import { IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { ContactDto } from './contact.dto';

export class ResetPasswordDto extends ContactDto {
  @IsString({ message: 'El código es obligatorio.' })
  @Length(FIELD_LIMITS.otpDigits, FIELD_LIMITS.otpDigits, {
    message: 'El código debe tener 6 dígitos.',
  })
  @Matches(/^\d{6}$/, { message: 'El código debe tener 6 dígitos.' })
  code: string;

  @IsString({ message: 'La contraseña es obligatoria.' })
  @MinLength(FIELD_LIMITS.passwordMin, {
    message: `La contraseña debe tener al menos ${FIELD_LIMITS.passwordMin} caracteres.`,
  })
  @MaxLength(FIELD_LIMITS.passwordMax, {
    message: `La contraseña no puede superar ${FIELD_LIMITS.passwordMax} caracteres.`,
  })
  password: string;
}
