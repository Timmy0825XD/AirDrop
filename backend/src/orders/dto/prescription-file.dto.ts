import { IsIn, IsString, MinLength } from 'class-validator';
import { PRESCRIPTION_MIMES } from '../prescription.rules';

/** Un archivo de la fórmula (RU-25): un PDF o una foto, en base64. */
export class PrescriptionFileDto {
  @IsIn(PRESCRIPTION_MIMES, {
    message: 'La fórmula debe ser un PDF o una foto JPG o PNG.',
  })
  mime: string;

  @IsString({ message: 'Falta el archivo de la fórmula.' })
  @MinLength(1, { message: 'Falta el archivo de la fórmula.' })
  base64: string;
}
