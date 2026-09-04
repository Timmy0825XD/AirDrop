import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  Matches,
  MaxLength,
} from 'class-validator';
import { COLOMBIA_PHONE_REGEX, FIELD_LIMITS } from '../../common/field-limits';
import { ContactCheckDto } from './contact-check.dto';

export class ContactDto extends ContactCheckDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'El correo no es válido.' })
  @MaxLength(FIELD_LIMITS.email, {
    message: `El correo no puede superar ${FIELD_LIMITS.email} caracteres.`,
  })
  email?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/\D/g, '') : value,
  )
  @Matches(COLOMBIA_PHONE_REGEX, {
    message: 'El celular debe tener exactamente 10 dígitos (Colombia).',
  })
  phone?: string;
}
