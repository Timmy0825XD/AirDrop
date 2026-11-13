import { BadRequestException } from '@nestjs/common';
import { DocumentType } from '../common/enums/document-type.enum';
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
import { TriageDto } from './dto/triage.dto';
import {
  allergiesToRemember,
  compareEmergencyQueue,
  normalizePatientDocument,
  orderAllergies,
  PATIENT_DOCUMENT_INVALID,
  PATIENT_IS_HOLDER,
  patientColumns,
  PREGNANT_BABY,
  triageColumns,
} from './triage.rules';

const holder = {
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1099000001',
} as User;

const triage = (overrides: Partial<TriageDto> = {}): TriageDto => ({
  redFlags: [],
  patientGroup: PatientGroup.CHILD,
  symptoms: [Symptom.FEVER],
  onset: SymptomOnset.HOURS,
  severity: SymptomSeverity.MODERATE,
  ...overrides,
});

const child = {
  fullName: 'Samuel Pérez Gómez',
  documentType: PatientDocumentType.IDENTITY_CARD,
  documentNumber: ' 1065123456 ',
  relation: PatientRelation.CHILD,
};

describe('triageColumns (RF-41)', () => {
  it('pasa las fichas a columnas del pedido', () => {
    expect(
      triageColumns(triage({ redFlags: [RedFlag.SEIZURE], pregnant: false })),
    ).toEqual({
      redFlags: [RedFlag.SEIZURE],
      patientGroup: PatientGroup.CHILD,
      pregnant: false,
      symptoms: [Symptom.FEVER],
      symptomOnset: SymptomOnset.HOURS,
      symptomSeverity: SymptomSeverity.MODERATE,
    });
  });

  it('sin tamizaje (la app anterior) deja todo nulo', () => {
    expect(Object.values(triageColumns(undefined))).toEqual(
      Array(6).fill(null),
    );
  });

  it('no acepta un bebé embarazado', () => {
    expect(() =>
      triageColumns(
        triage({ patientGroup: PatientGroup.BABY, pregnant: true }),
      ),
    ).toThrow(new BadRequestException(PREGNANT_BABY));
  });
});

describe('patientColumns (RF-42)', () => {
  it('sin persona a cargo, el paciente es el titular y todo queda nulo', () => {
    expect(Object.values(patientColumns(holder, undefined))).toEqual(
      Array(4).fill(null),
    );
  });

  it('guarda a la persona a cargo con el documento normalizado', () => {
    expect(patientColumns(holder, child)).toEqual({
      patientFullName: 'Samuel Pérez Gómez',
      patientDocumentType: PatientDocumentType.IDENTITY_CARD,
      patientDocumentNumber: '1065123456',
      patientRelation: PatientRelation.CHILD,
    });
  });

  it('rechaza un documento que no corresponde a su tipo', () => {
    expect(() =>
      patientColumns(holder, { ...child, documentNumber: '12A' }),
    ).toThrow(new BadRequestException(PATIENT_DOCUMENT_INVALID));
  });

  it('no deja poner al titular como persona a cargo', () => {
    expect(() =>
      patientColumns(holder, {
        ...child,
        documentType: PatientDocumentType.CITIZENSHIP_ID,
        documentNumber: '1099000001',
      }),
    ).toThrow(new BadRequestException(PATIENT_IS_HOLDER));
  });

  it('acepta registro civil de 10 dígitos y PPT con letras', () => {
    expect(
      normalizePatientDocument(
        PatientDocumentType.CIVIL_REGISTRY,
        '1065987654',
      ),
    ).toBe('1065987654');
    expect(normalizePatientDocument(PatientDocumentType.PPT, 'ab12345')).toBe(
      'AB12345',
    );
  });
});

describe('alergias (RF-41)', () => {
  it('en el pedido, vacío o sin preguntar queda nulo', () => {
    expect(orderAllergies('Penicilina')).toBe('Penicilina');
    expect(orderAllergies('')).toBeNull();
    expect(orderAllergies(undefined)).toBeNull();
  });

  it('se recuerdan en la cuenta solo si el paciente es el titular', () => {
    expect(allergiesToRemember({ allergies: 'Penicilina' })).toBe('Penicilina');
    expect(allergiesToRemember({ allergies: '' })).toBeNull();
    expect(allergiesToRemember({})).toBeUndefined();
    expect(
      allergiesToRemember({ allergies: 'Ibuprofeno', patient: child }),
    ).toBeUndefined();
  });
});

describe('compareEmergencyQueue (RU-10)', () => {
  const order = (
    id: string,
    status: OrderStatus,
    redFlags: RedFlag[] | null,
  ) => ({ id, status, redFlags });

  it('reasignado primero, luego con alarma, luego por llegada', () => {
    const queue = [
      order('vieja', OrderStatus.RECEIVED, null),
      order('alarma', OrderStatus.RECEIVED, [RedFlag.CHEST_PAIN]),
      order('sin-alarma', OrderStatus.RECEIVED, []),
      order('reasignada', OrderStatus.REASSIGNED, null),
      order('alarma-2', OrderStatus.RECEIVED, [RedFlag.FAINTING]),
    ];
    expect(queue.sort(compareEmergencyQueue).map((o) => o.id)).toEqual([
      'reasignada',
      'alarma',
      'alarma-2',
      'vieja',
      'sin-alarma',
    ]);
  });
});
