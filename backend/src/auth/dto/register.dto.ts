import { Transform } from 'class-transformer';
import {
  Equals,
  IsBoolean,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  PUBLIC_REGISTER_ROLES,
  UserRole,
} from '../../common/enums/user-role.enum';
import { COLOMBIA_PHONE_REGEX, FIELD_LIMITS } from '../../common/field-limits';
import { ContactCheckDto } from './contact-check.dto';

export class RegisterDto extends ContactCheckDto {
  @IsString({ message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.fullName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.fullName} caracteres.`,
  })
  fullName: string;

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

  @IsString({ message: 'La contraseña es obligatoria.' })
  @MinLength(FIELD_LIMITS.passwordMin, {
    message: `La contraseña debe tener al menos ${FIELD_LIMITS.passwordMin} caracteres.`,
  })
  @MaxLength(FIELD_LIMITS.passwordMax, {
    message: `La contraseña no puede superar ${FIELD_LIMITS.passwordMax} caracteres.`,
  })
  password: string;

  @IsIn(PUBLIC_REGISTER_ROLES, {
    message: 'El rol no es válido para el registro.',
  })
  role: UserRole;

  @IsBoolean({ message: 'Debes indicar si aceptas el tratamiento de datos.' })
  @Equals(true, {
    message: 'Debes aceptar el tratamiento de datos personales.',
  })
  consentAccepted: boolean;
}
