import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
} from 'class-validator';
import {
  PatientGroup,
  RedFlag,
  Symptom,
  SymptomOnset,
  SymptomSeverity,
} from '../../common/enums/triage.enum';

/** RF-41: el tamizaje de la urgencia, en fichas. La nota va en `description`. */
export class TriageDto {
  /** Vacío es "Ninguno". */
  @IsArray({ message: 'Los signos de alarma van en una lista.' })
  @ArrayUnique({ message: 'Un signo de alarma no se repite.' })
  @ArrayMaxSize(Object.values(RedFlag).length)
  @IsEnum(RedFlag, { each: true, message: 'Un signo de alarma no es válido.' })
  redFlags: RedFlag[];

  @IsEnum(PatientGroup, {
    message: 'Di si el paciente es bebé, niño, adulto o adulto mayor.',
  })
  patientGroup: PatientGroup;

  @IsOptional()
  @IsBoolean({ message: 'El embarazo debe ser sí o no.' })
  pregnant?: boolean;

  @IsArray({ message: 'Los síntomas van en una lista.' })
  @ArrayMinSize(1, { message: 'Elige al menos un síntoma.' })
  @ArrayUnique({ message: 'Un síntoma no se repite.' })
  @ArrayMaxSize(Object.values(Symptom).length)
  @IsEnum(Symptom, { each: true, message: 'Un síntoma no es válido.' })
  symptoms: Symptom[];

  @IsEnum(SymptomOnset, { message: 'Di desde cuándo: horas, hoy o días.' })
  onset: SymptomOnset;

  @IsEnum(SymptomSeverity, {
    message: 'Di qué tan fuerte: leve, moderado o fuerte.',
  })
  severity: SymptomSeverity;
}
