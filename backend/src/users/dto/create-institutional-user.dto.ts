import { Transform, Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  INSTITUTIONAL_ROLES,
  UserRole,
} from '../../common/enums/user-role.enum';
import { COLOMBIA_PHONE_REGEX, FIELD_LIMITS } from '../../common/field-limits';

export class CreateInstitutionalUserDto {
  @IsString({ message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.fullName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.fullName} caracteres.`,
  })
  fullName: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'El correo no es válido.' })
  @MaxLength(FIELD_LIMITS.email, {
    message: `El correo no puede superar ${FIELD_LIMITS.email} caracteres.`,
  })
  email: string;

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

  @IsIn(INSTITUTIONAL_ROLES, {
    message: 'El rol debe ser despachador u operador de flota.',
  })
  role: UserRole;

  @IsArray({ message: 'Debes indicar las centrales.' })
  @ArrayMinSize(1, { message: 'Debes asignar al menos una central.' })
  @IsUUID('4', { each: true, message: 'La central no es válida.' })
  @Type(() => String)
  hubIds: string[];
}
