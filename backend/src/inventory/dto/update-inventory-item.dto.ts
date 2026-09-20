import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { FIELD_LIMITS } from '../../common/field-limits';

export class UpdateInventoryItemDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El nombre no es válido.' })
  @MaxLength(FIELD_LIMITS.medicationName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.medicationName} caracteres.`,
  })
  name?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'La cantidad debe ser un entero.' })
  @Min(0, { message: 'La cantidad no puede ser negativa.' })
  quantity?: number;

  @IsOptional()
  @IsDateString(
    { strict: true },
    { message: 'La fecha de vencimiento no es válida.' },
  )
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha de vencimiento debe ser AAAA-MM-DD.',
  })
  expirationDate?: string;

  @IsOptional()
  @IsBoolean({ message: 'Debes indicar si exige cadena de frío.' })
  requiresColdChain?: boolean;

  @IsOptional()
  @IsBoolean({ message: 'Debes indicar si exige receta.' })
  requiresPrescription?: boolean;
}
