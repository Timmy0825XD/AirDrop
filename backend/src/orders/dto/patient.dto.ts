import { Transform } from 'class-transformer';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';
import {
  PatientDocumentType,
  PatientRelation,
} from '../../common/enums/patient.enum';
import { FIELD_LIMITS } from '../../common/field-limits';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/** RF-42: el paciente a cargo. Sin este objeto, el paciente es el titular. */
export class PatientDto {
  @Transform(trim)
  @IsString({ message: 'El nombre del paciente es obligatorio.' })
  @MinLength(3, { message: 'El nombre del paciente es obligatorio.' })
  @MaxLength(FIELD_LIMITS.patientFullName, {
    message: `El nombre del paciente no puede superar ${FIELD_LIMITS.patientFullName} caracteres.`,
  })
  fullName: string;

  @IsEnum(PatientDocumentType, {
    message: 'El tipo de documento del paciente no es válido.',
  })
  documentType: PatientDocumentType;

  @Transform(trim)
  @IsString({ message: 'El documento del paciente es obligatorio.' })
  @MaxLength(FIELD_LIMITS.documentNumber, {
    message: `El documento del paciente no puede superar ${FIELD_LIMITS.documentNumber} caracteres.`,
  })
  documentNumber: string;

  @IsEnum(PatientRelation, { message: 'Di quién es el paciente para ti.' })
  relation: PatientRelation;
}
