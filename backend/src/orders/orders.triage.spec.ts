/**
 * Urgencia con tamizaje (RF-41) y paciente a cargo (RF-42). El almacenamiento
 * de la fórmula y las existencias se simulan, como en `orders.cu09.spec.ts`.
 */
import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DocumentType } from '../common/enums/document-type.enum';
import {
  PatientDocumentType,
  PatientRelation,
} from '../common/enums/patient.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import {
  PatientGroup,
  RedFlag,
  Symptom,
  SymptomOnset,
  SymptomSeverity,
} from '../common/enums/triage.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { presentOrder } from './order.presenter';
import { DOCUMENT_MISMATCH } from './orders.rules';
import { OrdersService } from './orders.service';
import { DEFAULT_REFERENCE, PATIENT_DOCUMENT_TWICE } from './triage.rules';

const holder = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  role: UserRole.REQUESTER,
  status: UserStatus.ACTIVE,
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1099000001',
  hubAssignments: [],
} as unknown as User;

const son = {
  fullName: 'Samuel Pérez Gómez',
  documentType: PatientDocumentType.IDENTITY_CARD,
  documentNumber: '1065123456',
  relation: PatientRelation.CHILD,
};

const fever = {
  redFlags: [],
  patientGroup: PatientGroup.CHILD,
  symptoms: [Symptom.FEVER, Symptom.PAIN],
  onset: SymptomOnset.HOURS,
  severity: SymptomSeverity.SEVERE,
};

function dto(overrides: Partial<CreateEmergencyDto> = {}): CreateEmergencyDto {
  return {
    medicationName: 'Acetaminofén jarabe',
    saleType: SaleType.OVER_THE_COUNTER,
    triage: fever,
    allergies: '',
    latitude: 10.4631,
    longitude: -73.2532,
    ...overrides,
  };
}

function build(saleType = SaleType.OVER_THE_COUNTER) {
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) =>
      Promise.resolve({
        ...value,
        id: '11111111-1111-4111-8111-111111111111',
        createdAt: new Date('2026-11-12T15:00:00.000Z'),
      }),
    ),
    delete: jest.fn(),
  };
  const images = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) => Promise.resolve(value)),
  };
  const storage = {
    upload: jest.fn((orderId: string) => Promise.resolve(`${orderId}.jpg`)),
  };
  const offers = {
    offer: jest.fn().mockResolvedValue({
      name: 'Acetaminofén jarabe',
      availableQuantity: 10,
      saleType,
      requiresColdChain: false,
    }),
  } as unknown as InventoryOfferQuery;
  const service = new OrdersService(
    orders as never,
    images as never,
    storage as never,
    {} as never,
    offers,
    {} as HubsService,
    {} as never,
    { assertDestinationAllowed: () => Promise.resolve() } as never,
    { statusChanged: jest.fn().mockResolvedValue(undefined) } as never,
  );
  const saved = () => orders.save.mock.calls[0][0];
  return { service, saved, storage };
}

async function errors(data: object): Promise<string[]> {
  const found = await validate(plainToInstance(CreateEmergencyDto, data));
  const all = (list: typeof found): string[] =>
    list.flatMap((e) => [
      ...Object.values(e.constraints ?? {}),
      ...all(e.children ?? []),
    ]);
  return all(found);
}

describe('Urgencia con tamizaje y paciente a cargo (RF-41, RF-42)', () => {
  it('guarda el tamizaje, la referencia por defecto y lo devuelve al despachador', async () => {
    const { service, saved } = build();
    const result = await service.createEmergency(holder, dto());
    expect(saved()).toMatchObject({
      redFlags: [],
      patientGroup: PatientGroup.CHILD,
      symptoms: [Symptom.FEVER, Symptom.PAIN],
      symptomOnset: SymptomOnset.HOURS,
      symptomSeverity: SymptomSeverity.SEVERE,
      description: null,
      allergies: null,
      address: DEFAULT_REFERENCE,
      patientFullName: null,
    });
    expect(result.triage).toEqual({
      redFlags: [],
      patientGroup: PatientGroup.CHILD,
      pregnant: null,
      symptoms: [Symptom.FEVER, Symptom.PAIN],
      onset: SymptomOnset.HOURS,
      severity: SymptomSeverity.SEVERE,
    });
    expect(result.patient).toBeNull();
  });

  it('una persona a cargo con fórmula: la fórmula es de ella, no de la cuenta', async () => {
    const { service, saved, storage } = build(SaleType.PRESCRIPTION);
    const result = await service.createEmergency(
      holder,
      dto({
        saleType: SaleType.PRESCRIPTION,
        patient: son,
        allergies: 'Penicilina',
        prescriptionMime: 'image/jpeg',
        prescriptionImageBase64: Buffer.from([0xff, 0xd8, 0xff, 1]).toString(
          'base64',
        ),
      }),
    );
    expect(storage.upload).toHaveBeenCalled();
    expect(saved()).toMatchObject({
      patientFullName: 'Samuel Pérez Gómez',
      patientDocumentType: PatientDocumentType.IDENTITY_CARD,
      patientDocumentNumber: '1065123456',
      patientRelation: PatientRelation.CHILD,
      allergies: 'Penicilina',
    });
    expect(result.patient).toEqual({
      fullName: 'Samuel Pérez Gómez',
      documentType: PatientDocumentType.IDENTITY_CARD,
      documentNumber: '1065123456',
      relation: PatientRelation.CHILD,
    });
  });

  it('con persona a cargo no se manda además el documento de la cuenta', async () => {
    const { service } = build(SaleType.PRESCRIPTION);
    await expect(
      service.createEmergency(
        holder,
        dto({
          saleType: SaleType.PRESCRIPTION,
          patient: son,
          patientDocumentType: DocumentType.CITIZENSHIP_ID,
          patientDocumentNumber: '1099000001',
          prescriptionMime: 'image/jpeg',
          prescriptionImageBase64: 'AQID',
        }),
      ),
    ).rejects.toThrow(new BadRequestException(PATIENT_DOCUMENT_TWICE));
  });

  it('sin persona a cargo, la fórmula sigue exigiendo el documento de la cuenta', async () => {
    const { service } = build(SaleType.PRESCRIPTION);
    await expect(
      service.createEmergency(
        holder,
        dto({
          saleType: SaleType.PRESCRIPTION,
          prescriptionMime: 'image/jpeg',
          prescriptionImageBase64: 'AQID',
        }),
      ),
    ).rejects.toThrow(new BadRequestException(DOCUMENT_MISMATCH));
  });

  it('el pedido de la app anterior (sin tamizaje) sigue funcionando', async () => {
    const { service, saved } = build();
    const result = await service.createEmergency(
      holder,
      dto({
        triage: undefined,
        allergies: undefined,
        description: 'Fiebre alta',
        address: 'Calle 16 # 9-40',
      }),
    );
    expect(saved()).toMatchObject({
      description: 'Fiebre alta',
      address: 'Calle 16 # 9-40',
      redFlags: null,
    });
    expect(result.triage).toBeNull();
  });

  it('el presentador no inventa tamizaje en un pedido sin él', () => {
    expect(presentOrder({} as Order).triage).toBeNull();
  });
});

describe('CreateEmergencyDto con tamizaje', () => {
  const base = {
    medicationName: 'Acetaminofén jarabe',
    saleType: SaleType.OVER_THE_COUNTER,
    latitude: 10.4631,
    longitude: -73.2532,
  };

  it('con tamizaje, la nota y la referencia son opcionales', async () => {
    expect(await errors({ ...base, triage: fever })).toEqual([]);
  });

  it('sin tamizaje, la descripción sigue siendo obligatoria', async () => {
    expect(await errors(base)).toContain('La descripción es obligatoria.');
  });

  it('pide al menos un síntoma y valores conocidos', async () => {
    const found = await errors({
      ...base,
      triage: { ...fever, symptoms: [], redFlags: ['dolor'] },
    });
    expect(found).toContain('Elige al menos un síntoma.');
    expect(found).toContain('Un signo de alarma no es válido.');
  });

  it('el punto en el mapa es obligatorio', async () => {
    const found = await errors({ ...base, latitude: undefined, triage: fever });
    expect(found).toContain('Marca en el mapa dónde debe llegar el dron.');
  });

  it('valida a la persona a cargo', async () => {
    const found = await errors({
      ...base,
      triage: fever,
      patient: { ...son, relation: 'vecino', fullName: '' },
    });
    expect(found).toContain('Di quién es el paciente para ti.');
    expect(found).toContain('El nombre del paciente es obligatorio.');
  });

  it('acepta un signo de alarma', async () => {
    expect(
      await errors({
        ...base,
        triage: { ...fever, redFlags: [RedFlag.BREATHING_DIFFICULTY] },
      }),
    ).toEqual([]);
  });
});
