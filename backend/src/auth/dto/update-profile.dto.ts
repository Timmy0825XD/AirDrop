import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { COLOMBIA_PHONE_REGEX, FIELD_LIMITS } from '../../common/field-limits';

export class UpdateProfileDto {
  @IsOptional()
  @IsString({ message: 'El nombre no es válido.' })
  @MaxLength(FIELD_LIMITS.fullName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.fullName} caracteres.`,
  })
  fullName?: string;

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

  @IsOptional()
  @IsEnum(DocumentType, {
    message:
      'El documento debe ser cédula de ciudadanía, cédula de extranjería o PPT.',
  })
  documentType?: DocumentType;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El número de documento no es válido.' })
  @MaxLength(FIELD_LIMITS.documentNumber, {
    message: `El número de documento no puede superar ${FIELD_LIMITS.documentNumber} caracteres.`,
  })
  documentNumber?: string;
}
