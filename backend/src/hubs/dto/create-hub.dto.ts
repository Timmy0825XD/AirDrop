import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsEnum,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { HubType } from '../../common/enums/hub-type.enum';
import { COLOMBIA_PHONE_REGEX, FIELD_LIMITS } from '../../common/field-limits';

export class CreateHubDto {
  @IsString({ message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.hubName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.hubName} caracteres.`,
  })
  name: string;

  @IsEnum(HubType, { message: 'El tipo de central no es válido.' })
  type: HubType;

  @IsString({ message: 'La dirección es obligatoria.' })
  @MaxLength(FIELD_LIMITS.address, {
    message: `La dirección no puede superar ${FIELD_LIMITS.address} caracteres.`,
  })
  address: string;

  @IsNumber({}, { message: 'La latitud no es válida.' })
  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude: number;

  @IsNumber({}, { message: 'La longitud no es válida.' })
  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/\D/g, '') : value,
  )
  @Matches(COLOMBIA_PHONE_REGEX, {
    message: 'El celular debe tener exactamente 10 dígitos (Colombia).',
  })
  contactPhone: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'El correo de contacto no es válido.' })
  @MaxLength(FIELD_LIMITS.email, {
    message: `El correo no puede superar ${FIELD_LIMITS.email} caracteres.`,
  })
  contactEmail?: string;
}
