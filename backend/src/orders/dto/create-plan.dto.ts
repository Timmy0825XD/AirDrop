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
  ArrayMaxSize,
  IsArray,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { PlanFrequency } from '../../common/enums/plan-frequency.enum';
import { SaleType } from '../../common/enums/sale-type.enum';
import {
  FIELD_LIMITS,
  PRESCRIPTION_MAX_IMAGES,
} from '../../common/field-limits';
import { PrescriptionFileDto } from './prescription-file.dto';
import { PatientDto } from './patient.dto';
import { PlanScheduleDto } from './plan-schedule.dto';

export class CreatePlanDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'El medicamento es obligatorio.' })
  @MinLength(1, { message: 'El medicamento es obligatorio.' })
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

  /** RU-02: la referencia para encontrar el punto; el destino es el punto. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'La referencia debe ser texto.' })
  @MaxLength(FIELD_LIMITS.address, {
    message: `La referencia no puede superar ${FIELD_LIMITS.address} caracteres.`,
  })
  address?: string;

  @Type(() => Number)
  @IsLatitude({ message: 'Marca en el mapa dónde debe llegar el dron.' })
  latitude: number;

  @Type(() => Number)
  @IsLongitude({ message: 'Marca en el mapa dónde debe llegar el dron.' })
  longitude: number;

  /** RF-42: sin este objeto, el paciente es el titular de la cuenta. */
  @IsOptional()
  @ValidateNested()
  @Type(() => PatientDto)
  patient?: PatientDto;

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

  /**
   * RU-25: la fórmula en un PDF o en 1 a 3 fotos. Reemplaza a
   * `prescriptionMime` y `prescriptionImageBase64`, que siguen sirviendo para
   * un solo archivo (la app anterior).
   */
  @IsOptional()
  @IsArray({ message: 'Los archivos de la fórmula van en una lista.' })
  @ArrayMaxSize(PRESCRIPTION_MAX_IMAGES, {
    message: 'La fórmula va en un solo PDF o en 1 a 3 fotos, sin mezclarlos.',
  })
  @ValidateNested({ each: true })
  @Type(() => PrescriptionFileDto)
  prescriptions?: PrescriptionFileDto[];
}
