import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
  ValidateNested,
  ArrayMaxSize,
  IsArray,
} from 'class-validator';
import { DocumentType } from '../../common/enums/document-type.enum';
import { SaleType } from '../../common/enums/sale-type.enum';
import {
  FIELD_LIMITS,
  PRESCRIPTION_MAX_IMAGES,
} from '../../common/field-limits';
import { PrescriptionFileDto } from './prescription-file.dto';
import { PatientDto } from './patient.dto';
import { TriageDto } from './triage.dto';

export class CreateEmergencyDto {
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

  /** RF-41: el tamizaje. Sin él (la app anterior), la nota es obligatoria. */
  @IsOptional()
  @ValidateNested()
  @Type(() => TriageDto)
  triage?: TriageDto;

  /** La nota corta de la urgencia; obligatoria solo sin `triage`. */
  @ValidateIf(
    (dto: CreateEmergencyDto) => !dto.triage || dto.description != null,
  )
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'La descripción es obligatoria.' })
  @MinLength(1, { message: 'La descripción es obligatoria.' })
  @MaxLength(FIELD_LIMITS.orderDescription, {
    message: `La descripción no puede superar ${FIELD_LIMITS.orderDescription} caracteres.`,
  })
  description?: string;

  /**
   * RF-41: alergias a medicamentos. Vacío es "ninguna"; sin el campo, no se
   * preguntó (la app anterior).
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'Las alergias deben ser texto.' })
  @MaxLength(FIELD_LIMITS.allergies, {
    message: `Las alergias no pueden superar ${FIELD_LIMITS.allergies} caracteres.`,
  })
  allergies?: string;

  /**
   * RU-02: una referencia corta para encontrar el punto ("reja verde, patio
   * de atrás"). El destino es el punto; sin referencia queda
   * `DEFAULT_REFERENCE`.
   */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString({ message: 'La referencia debe ser texto.' })
  @MaxLength(FIELD_LIMITS.address, {
    message: `La referencia no puede superar ${FIELD_LIMITS.address} caracteres.`,
  })
  address?: string;

  /** RU-02: el punto donde baja el dron. */
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
