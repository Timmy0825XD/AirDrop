import { IsBoolean, IsOptional, IsString, Matches } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class ValidateDeliveryCodeDto {
  @IsString({ message: 'El código de entrega es obligatorio.' })
  @Matches(new RegExp(`^\\d{${FIELD_LIMITS.otpDigits}}$`), {
    message: `El código de entrega debe tener ${FIELD_LIMITS.otpDigits} dígitos.`,
  })
  code: string;

  /** Traslado entre centrales: la remisión coincide (cantidad, lote, vencimiento). */
  @IsOptional()
  @IsBoolean({ message: 'Indica si la remisión coincide.' })
  remissionMatches?: boolean;

  /** Traslado entre centrales: el sello llegó intacto. */
  @IsOptional()
  @IsBoolean({ message: 'Indica si el sello llegó intacto.' })
  sealIntact?: boolean;
}
