import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { SaleType } from '../../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

export class CreateHubEmergencyDto {
  @IsUUID('4', { message: 'La central de origen no es válida.' })
  originHubId: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El medicamento es obligatorio.' })
  @MaxLength(FIELD_LIMITS.medicationName, {
    message: `El medicamento no puede superar ${FIELD_LIMITS.medicationName} caracteres.`,
  })
  medicationName: string;

  @IsEnum(SaleType, {
    message:
      'El tipo de venta debe ser libre, bajo fórmula o control especial.',
  })
  saleType: SaleType;

  @Type(() => Number)
  @IsInt({ message: 'La cantidad debe ser un entero.' })
  @Min(1, { message: 'La cantidad debe ser al menos 1.' })
  @Max(100000, { message: 'La cantidad es demasiado alta.' })
  quantity: number;

  @IsOptional()
  @IsEnum(DocumentType)
  patientDocumentType?: DocumentType;

  @IsOptional()
  @IsString()
  patientDocumentNumber?: string;

  @IsOptional()
  @IsString()
  prescriptionMime?: string;

  @IsOptional()
  @IsString()
  prescriptionImageBase64?: string;
}
