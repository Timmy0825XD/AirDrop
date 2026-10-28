import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
  MinLength,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { PlanFrequency } from '../../common/enums/plan-frequency.enum';
import { SaleType } from '../../common/enums/sale-type.enum';
import { FIELD_LIMITS } from '../../common/field-limits';
import { PlanScheduleDto } from './plan-schedule.dto';

export class CreatePlanDto {
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

  @ValidateIf((dto: { schedule?: unknown }) => dto.schedule === undefined)
  @IsEnum(PlanFrequency, {
    message: 'La frecuencia debe ser única, semanal, quincenal o mensual.',
  })
  frequency?: PlanFrequency;

  @ValidateIf((dto: { schedule?: unknown }) => dto.schedule === undefined)
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La fecha de inicio debe ser AAAA-MM-DD.',
  })
  startDate?: string;

  /**
   * RU-30: calendario, fin y hora de la franja. Sin él, el plan usa la
   * frecuencia y la fecha de inicio anteriores (8 semanas, todo el día).
   */
  @IsOptional()
  @ValidateNested()
  @Type(() => PlanScheduleDto)
  schedule?: PlanScheduleDto;

  /** Bajo fórmula, con `schedule`: el plan no pasa de esta fecha. */
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'La vigencia de la fórmula debe ser AAAA-MM-DD.',
  })
  prescriptionValidUntil?: string;

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
