import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { SaleType } from '../../common/enums/sale-type.enum';
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
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString({ message: 'El lote no es válido.' })
  @Matches(/^[A-Z0-9-]{3,20}$/, {
    message: 'El lote debe tener entre 3 y 20 letras, números o guiones.',
  })
  @MaxLength(FIELD_LIMITS.lotCode, {
    message: `El lote no puede superar ${FIELD_LIMITS.lotCode} caracteres.`,
  })
  lot?: string;

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
  @IsEnum(SaleType, {
    message: 'El tipo de venta debe ser libre, bajo fórmula o control especial.',
  })
  saleType?: SaleType;
}
