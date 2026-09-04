import { IsString, MaxLength, MinLength } from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';
import { ContactDto } from './contact.dto';

export class LoginDto extends ContactDto {
  @IsString({ message: 'La contraseña es obligatoria.' })
  @MinLength(1, { message: 'La contraseña es obligatoria.' })
  @MaxLength(FIELD_LIMITS.passwordMax, {
    message: `La contraseña no puede superar ${FIELD_LIMITS.passwordMax} caracteres.`,
  })
  password: string;
}
