import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsString,
  Matches,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { SaleType } from '../../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../../common/field-limits';
import { IsAfterToday } from './is-after-today.validator';

export class CreateInventoryItemDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El nombre es obligatorio.' })
  @MinLength(1, { message: 'El nombre es obligatorio.' })
  @MaxLength(FIELD_LIMITS.medicationName, {
    message: `El nombre no puede superar ${FIELD_LIMITS.medicationName} caracteres.`,
  })
  name: string;

  @Type(() => Number)
  @IsInt({ message: 'La cantidad debe ser un entero.' })
  @Min(1, { message: 'La cantidad debe ser mayor que cero.' })
  quantity: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString({ message: 'El lote es obligatorio.' })
  @Matches(/^[A-Z0-9-]{3,20}$/, {
    message: 'El lote debe tener entre 3 y 20 letras, números o guiones.',
  })
  @MaxLength(FIELD_LIMITS.lotCode, {
    message: `El lote no puede superar ${FIELD_LIMITS.lotCode} caracteres.`,
  })
  lot: string;

  @IsDateString(
    { strict: true },
    { message: 'La fecha de vencimiento no es válida.' },
  )
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha de vencimiento debe ser AAAA-MM-DD.',
  })
  @IsAfterToday()
  expirationDate: string;

  @IsBoolean({ message: 'Debes indicar si exige cadena de frío.' })
  requiresColdChain: boolean;

  @IsEnum(SaleType, {
    message:
      'El tipo de venta debe ser libre, bajo fórmula o control especial.',
  })
  saleType: SaleType;
}
