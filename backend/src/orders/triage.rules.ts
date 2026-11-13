import { BadRequestException } from '@nestjs/common';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  PatientDocumentType,
  PatientRelation,
} from '../common/enums/patient.enum';
import {
  PatientGroup,
  RedFlag,
  Symptom,
  SymptomOnset,
  SymptomSeverity,
} from '../common/enums/triage.enum';
import { User } from '../users/user.entity';
import { PatientDto } from './dto/patient.dto';
import { TriageDto } from './dto/triage.dto';

/** RU-02: la referencia cuando el solicitante no escribe ninguna. */
export const DEFAULT_REFERENCE = 'Punto marcado en el mapa';

export const PREGNANT_BABY = 'Un bebé no puede estar embarazado.';

export const PATIENT_DOCUMENT_INVALID =
  'El documento del paciente no es válido.';

export const PATIENT_IS_HOLDER =
  'Si el paciente eres tú, no lo agregues como persona a cargo.';

export const PATIENT_DOCUMENT_TWICE =
  'Con una persona a cargo, su documento va solo en los datos del paciente.';

/** Registro civil (NUIP) y tarjeta de identidad son numéricos; PPT admite letras. */
const PATIENT_DOCUMENT_PATTERNS: Record<PatientDocumentType, RegExp> = {
  [PatientDocumentType.CIVIL_REGISTRY]: /^\d{8,11}$/,
  [PatientDocumentType.IDENTITY_CARD]: /^\d{10,11}$/,
  [PatientDocumentType.CITIZENSHIP_ID]: /^\d{6,10}$/,
  [PatientDocumentType.FOREIGNER_ID]: /^\d{6,10}$/,
  [PatientDocumentType.PPT]: /^[A-Z0-9]{6,15}$/,
};

/** Las columnas del tamizaje en el pedido (RF-41). Sin tamizaje, todas nulas. */
export interface TriageColumns {
  redFlags: RedFlag[] | null;
  patientGroup: PatientGroup | null;
  pregnant: boolean | null;
  symptoms: Symptom[] | null;
  symptomOnset: SymptomOnset | null;
  symptomSeverity: SymptomSeverity | null;
}

/** Las columnas del paciente a cargo (RF-42). Nulas si el paciente es el titular. */
export interface PatientColumns {
  patientFullName: string | null;
  patientDocumentType: PatientDocumentType | null;
  patientDocumentNumber: string | null;
  patientRelation: PatientRelation | null;
}

export function triageColumns(triage: TriageDto | undefined): TriageColumns {
  if (!triage) {
    return {
      redFlags: null,
      patientGroup: null,
      pregnant: null,
      symptoms: null,
      symptomOnset: null,
      symptomSeverity: null,
    };
  }
  if (triage.pregnant && triage.patientGroup === PatientGroup.BABY) {
    throw new BadRequestException(PREGNANT_BABY);
  }
  return {
    redFlags: [...triage.redFlags],
    patientGroup: triage.patientGroup,
    pregnant: triage.pregnant ?? null,
    symptoms: [...triage.symptoms],
    symptomOnset: triage.onset,
    symptomSeverity: triage.severity,
  };
}

/** Normaliza el documento del paciente a cargo, o `null` si no es válido. */
export function normalizePatientDocument(
  type: PatientDocumentType,
  raw: string,
): string | null {
  const value = raw.trim().toUpperCase();
  return PATIENT_DOCUMENT_PATTERNS[type].test(value) ? value : null;
}

export function patientColumns(
  holder: User,
  patient: PatientDto | undefined,
): PatientColumns {
  if (!patient) {
    return {
      patientFullName: null,
      patientDocumentType: null,
      patientDocumentNumber: null,
      patientRelation: null,
    };
  }
  const number = normalizePatientDocument(
    patient.documentType,
    patient.documentNumber,
  );
  if (!number) {
    throw new BadRequestException(PATIENT_DOCUMENT_INVALID);
  }
  // Los tipos de una cuenta tienen el mismo valor en los dos enums.
  if (
    holder.documentNumber === number &&
    (holder.documentType as string | null) === patient.documentType
  ) {
    throw new BadRequestException(PATIENT_IS_HOLDER);
  }
  return {
    patientFullName: patient.fullName,
    patientDocumentType: patient.documentType,
    patientDocumentNumber: number,
    patientRelation: patient.relation,
  };
}

/** Lo que se guarda en el pedido: `null` es "ninguna" o "no se preguntó". */
export function orderAllergies(allergies: string | undefined): string | null {
  return allergies ? allergies : null;
}

/**
 * Las alergias que se recuerdan en la cuenta para la siguiente urgencia
 * (RF-41): solo si el paciente es el titular y la app las preguntó.
 * `undefined` deja la cuenta como está.
 */
export function allergiesToRemember(input: {
  allergies?: string;
  patient?: PatientDto;
}): string | null | undefined {
  if (input.patient || input.allergies === undefined) {
    return undefined;
  }
  return input.allergies || null;
}

export function hasRedFlag(order: { redFlags?: RedFlag[] | null }): boolean {
  return (order.redFlags?.length ?? 0) > 0;
}

/**
 * Orden de la cola de urgencias (RU-10): lo reasignado desde otra central ya
 * esperó una vez y va primero; después, las que traen un signo de alarma
 * (RF-41). Entre iguales queda el orden de llegada (el `sort` es estable).
 */
export function compareEmergencyQueue(
  left: { status: OrderStatus; redFlags?: RedFlag[] | null },
  right: { status: OrderStatus; redFlags?: RedFlag[] | null },
): number {
  const reassigned =
    Number(right.status === OrderStatus.REASSIGNED) -
    Number(left.status === OrderStatus.REASSIGNED);
  if (reassigned !== 0) {
    return reassigned;
  }
  return Number(hasRedFlag(right)) - Number(hasRedFlag(left));
}
