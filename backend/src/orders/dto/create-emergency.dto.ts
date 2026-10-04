import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { SaleType } from '../../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

export class CreateEmergencyDto {
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

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'La descripción es obligatoria.' })
  @MinLength(1, { message: 'La descripción es obligatoria.' })
  @MaxLength(FIELD_LIMITS.orderDescription, {
    message: `La descripción no puede superar ${FIELD_LIMITS.orderDescription} caracteres.`,
  })
  description: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'La dirección es obligatoria.' })
  @MinLength(1, { message: 'La dirección es obligatoria.' })
  @MaxLength(FIELD_LIMITS.address, {
    message: `La dirección no puede superar ${FIELD_LIMITS.address} caracteres.`,
  })
  address: string;

  @IsOptional()
  @Type(() => Number)
  @IsLatitude({ message: 'La latitud no es válida.' })
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsLongitude({ message: 'La longitud no es válida.' })
  longitude?: number;

  @IsOptional()
  @IsEnum(DocumentType, { message: 'El tipo de documento no es válido.' })
  patientDocumentType?: DocumentType;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MaxLength(FIELD_LIMITS.documentNumber)
  patientDocumentNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(FIELD_LIMITS.prescriptionMime)
  prescriptionMime?: string;

  @IsOptional()
  @IsString()
  prescriptionImageBase64?: string;
}
