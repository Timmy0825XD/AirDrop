import { IsString, Length, Matches } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { ContactDto } from './contact.dto';

export class VerifyOtpDto extends ContactDto {
  @IsString({ message: 'El código es obligatorio.' })
  @Length(FIELD_LIMITS.otpDigits, FIELD_LIMITS.otpDigits, {
    message: 'El código debe tener 6 dígitos.',
  })
  @Matches(/^\d{6}$/, { message: 'El código debe tener 6 dígitos.' })
  code: string;
}
