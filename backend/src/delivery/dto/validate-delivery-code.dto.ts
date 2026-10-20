import { IsString, Matches } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class ValidateDeliveryCodeDto {
  @IsString({ message: 'El código de entrega es obligatorio.' })
  @Matches(new RegExp(`^\\d{${FIELD_LIMITS.otpDigits}}$`), {
    message: `El código de entrega debe tener ${FIELD_LIMITS.otpDigits} dígitos.`,
  })
  code: string;
}
