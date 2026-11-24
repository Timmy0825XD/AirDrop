/**
 * Pruebas unitarias del CU-09 (Crear pedido de emergencia), casos CP-09-01 a
 * CP-09-15 de la Segunda Parte. El nombre de cada `it` empieza con el ID del
 * caso para que la terminal lo muestre en la captura. El almacenamiento de la
 * fórmula y las existencias se simulan (mocks).
 */
import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate, ValidationError } from 'class-validator';
import { DocumentType } from '../common/enums/document-type.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  PatientDocumentType,
  PatientRelation,
} from '../common/enums/patient.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import {
  PatientGroup,
  Symptom,
  SymptomOnset,
  SymptomSeverity,
} from '../common/enums/triage.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  COORDINATES_PRECISION,
  DOCUMENT_MISMATCH,
  NO_STOCK_MESSAGE,
  ORIGIN_STOCK_MESSAGE,
  SPECIAL_CONTROL_MESSAGE,
} from './orders.rules';
import { OrdersService } from './orders.service';
import {
  PRESCRIPTION_CORRUPT,
  PRESCRIPTION_FILES_RULE,
  PRESCRIPTION_IMAGE_REQUIRED,
  PRESCRIPTION_SIZE,
} from './prescription.rules';

const KB = 1024;
const MB = 1024 * KB;

const solicitante = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  role: UserRole.REQUESTER,
  status: UserStatus.ACTIVE,
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1099000001',
  hubAssignments: [],
} as unknown as User;

const centralDestino = {
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  status: HubStatus.ACTIVE,
  address: 'Calle 16 No. 19-35, Valledupar',
  latitude: 10.4682,
  longitude: -73.2558,
} as Hub;

const centralOrigen = {
  id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  status: HubStatus.ACTIVE,
} as Hub;

const despachador = {
  id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  role: UserRole.DISPATCHER,
  status: UserStatus.ACTIVE,
  hubAssignments: [{ hubId: centralDestino.id }],
} as unknown as User;

function foto(bytes: number): string {
  // Empieza con la firma de un JPEG (FF D8 FF): el backend revisa el contenido.
  const content = Buffer.alloc(bytes, 1);
  content.set([0xff, 0xd8, 0xff]);
  return content.toString('base64');
}

function pdf(bytes: number): string {
  // Empieza con la firma de un PDF (%PDF-).
  const content = Buffer.alloc(bytes, 0x20);
  content.write('%PDF-1.7', 0, 'latin1');
  return content.toString('base64');
}

/** Paso 1 de la urgencia: el tamizaje en fichas (RF-41). */
const tamizaje = {
  redFlags: [],
  patientGroup: PatientGroup.ADULT,
  symptoms: [Symptom.BLOOD_SUGAR],
  onset: SymptomOnset.TODAY,
  severity: SymptomSeverity.MODERATE,
};

/** Urgencia bajo fórmula con los datos de CP-09-01: dos fotos de la fórmula. */
function conFormula(
  overrides: Partial<CreateEmergencyDto> = {},
): CreateEmergencyDto {
  return {
    medicationName: 'Insulina glargina 100 UI',
    saleType: SaleType.PRESCRIPTION,
    triage: tamizaje,
    allergies: '',
    address: 'Casa esquinera de reja verde',
    latitude: 10.4631,
    longitude: -73.2532,
    patientDocumentType: DocumentType.CITIZENSHIP_ID,
    patientDocumentNumber: '1099000001',
    prescriptions: [
      { mime: 'image/jpeg', base64: foto(300 * KB) },
      { mime: 'image/jpeg', base64: foto(280 * KB) },
    ],
    ...overrides,
  };
}

/** Urgencia de venta libre con los datos de CP-09-02. */
function libre(
  overrides: Partial<CreateEmergencyDto> = {},
): CreateEmergencyDto {
  return {
    medicationName: 'Acetaminofén 500 mg',
    saleType: SaleType.OVER_THE_COUNTER,
    triage: { ...tamizaje, symptoms: [Symptom.FEVER] },
    latitude: 10.4631,
    longitude: -73.2532,
    ...overrides,
  };
}

function build(
  oferta: { name: string; availableQuantity: number } | null = {
    name: 'Insulina glargina 100 UI',
    availableQuantity: 40,
  },
) {
  const pedidos = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) =>
      Promise.resolve({
        ...value,
        id: '11111111-1111-4111-8111-111111111111',
        createdAt: new Date('2026-11-20T15:00:00.000Z'),
      }),
    ),
    delete: jest.fn(),
  };
  const imagenes = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) => Promise.resolve(value)),
  };
  const almacenamiento = {
    upload: jest.fn((orderId: string) => Promise.resolve(`${orderId}.jpg`)),
  };
  const buscarOferta = jest.fn().mockResolvedValue(
    oferta && {
      ...oferta,
      saleType: SaleType.PRESCRIPTION,
      requiresColdChain: true,
    },
  );
  const ofertas = { offer: buscarOferta } as unknown as InventoryOfferQuery;
  const hubsService = {
    requireActive: jest.fn((id: string) =>
      Promise.resolve(id === centralOrigen.id ? centralOrigen : centralDestino),
    ),
  } as unknown as HubsService;
  const service = new OrdersService(
    pedidos as never,
    imagenes as never,
    almacenamiento as never,
    {} as never,
    ofertas,
    hubsService,
    {} as never,
    { assertDestinationAllowed: () => Promise.resolve() } as never,
    { statusChanged: jest.fn().mockResolvedValue(undefined) } as never,
  );
  return { service, pedidos, imagenes, almacenamiento, buscarOferta };
}

function mensajes(fallo: ValidationError): string[] {
  return [
    ...Object.values(fallo.constraints ?? {}),
    ...(fallo.children ?? []).flatMap(mensajes),
  ];
}

async function errores(data: object): Promise<string[]> {
  const fallos = await validate(plainToInstance(CreateEmergencyDto, data));
  return fallos.flatMap(mensajes);
}

describe('CU-09 Crear pedido de emergencia', () => {
  it('CP-09-01 crea una urgencia bajo fórmula con tamizaje, dos fotos de la fórmula y el documento del paciente', async () => {
    expect(await errores(conFormula())).toEqual([]);
    const { service, almacenamiento } = build();

    const pedido = await service.createEmergency(solicitante, conFormula());

    expect(pedido.status).toBe(OrderStatus.RECEIVED);
    expect(pedido.priority).toBe(OrderPriority.HIGH);
    expect(pedido.droneId).toBeNull();
    // Cada foto se envía al almacenamiento privado (simulado).
    expect(almacenamiento.upload).toHaveBeenCalledTimes(2);
  });

  it('CP-09-02 crea una urgencia de venta libre sin fórmula', async () => {
    expect(await errores(libre())).toEqual([]);
    const { service, almacenamiento } = build({
      name: 'Acetaminofén 500 mg',
      availableQuantity: 120,
    });

    const pedido = await service.createEmergency(solicitante, libre());

    expect(pedido.status).toBe(OrderStatus.RECEIVED);
    expect(pedido.priority).toBe(OrderPriority.HIGH);
    expect(almacenamiento.upload).not.toHaveBeenCalled();
  });

  it('CP-09-03 rechaza una urgencia de control especial (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ saleType: SaleType.SPECIAL_CONTROL }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(SPECIAL_CONTROL_MESSAGE),
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-04 rechaza una urgencia bajo fórmula sin la fórmula (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ prescriptions: [] }),
    );

    await expect(intento).rejects.toThrow(PRESCRIPTION_IMAGE_REQUIRED);
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-05 rechaza un documento de paciente distinto al de la cuenta (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ patientDocumentNumber: '1065487321' }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(DOCUMENT_MISMATCH),
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-06 rechaza un archivo de la fórmula de 5 MB + 1 byte y acepta uno de 5 MB (400)', async () => {
    const grande = build();
    const intento = grande.service.createEmergency(
      solicitante,
      conFormula({
        prescriptions: [{ mime: 'image/jpeg', base64: foto(5 * MB + 1) }],
      }),
    );
    await expect(intento).rejects.toThrow(PRESCRIPTION_SIZE);
    expect(grande.pedidos.save).not.toHaveBeenCalled();

    const justo = build();
    const pedido = await justo.service.createEmergency(
      solicitante,
      conFormula({
        prescriptions: [{ mime: 'image/jpeg', base64: foto(5 * MB) }],
      }),
    );
    expect(pedido.status).toBe(OrderStatus.RECEIVED);
  });

  it('CP-09-07 rechaza una fórmula de 4 fotos y acepta una de 3 (400)', async () => {
    const cuatro = Array.from({ length: 4 }, () => ({
      mime: 'image/jpeg',
      base64: foto(100 * KB),
    }));
    expect(await errores(conFormula({ prescriptions: cuatro }))).toContain(
      PRESCRIPTION_FILES_RULE,
    );
    expect(
      await errores(conFormula({ prescriptions: cuatro.slice(0, 3) })),
    ).toEqual([]);
  });

  it('CP-09-08 rechaza coordenadas con más de 6 decimales (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ latitude: 10.4631159 }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(COORDINATES_PRECISION),
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-09 rechaza un medicamento sin existencias en ninguna central (400)', async () => {
    const { service, pedidos } = build(null);

    const intento = service.createEmergency(
      solicitante,
      libre({ medicationName: 'Medicamento sin existencias' }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(NO_STOCK_MESSAGE),
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-10 rechaza la urgencia entre centrales si la central de origen no tiene oferta (400)', async () => {
    const { service, pedidos, buscarOferta } = build(null);

    const intento = service.createHubEmergency(despachador, {
      originHubId: centralOrigen.id,
      medicationName: 'Acetaminofén 500 mg',
      saleType: SaleType.OVER_THE_COUNTER,
      quantity: 10,
    });

    await expect(intento).rejects.toThrow(
      new BadRequestException(ORIGIN_STOCK_MESSAGE),
    );
    expect(buscarOferta).toHaveBeenCalledWith(
      'Acetaminofén 500 mg',
      SaleType.OVER_THE_COUNTER,
      centralOrigen.id,
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-11 rechaza una oferta con menos unidades que las pedidas (400)', async () => {
    const { service, pedidos } = build({
      name: 'Acetaminofén 500 mg',
      availableQuantity: 0,
    });

    const intento = service.createEmergency(solicitante, libre());

    await expect(intento).rejects.toThrow(
      new BadRequestException(NO_STOCK_MESSAGE),
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-12 rechaza el medicamento vacío con «El medicamento es obligatorio.»', async () => {
    expect(await errores(libre({ medicationName: '' }))).toContain(
      'El medicamento es obligatorio.',
    );
  });

  it('CP-09-13 rechaza un tamizaje sin ningún síntoma (400)', async () => {
    expect(
      await errores(libre({ triage: { ...tamizaje, symptoms: [] } })),
    ).toContain('Elige al menos un síntoma.');
  });

  it('CP-09-14 crea una urgencia para un hijo a cargo con su registro civil', async () => {
    const paraHijo = conFormula({
      triage: { ...tamizaje, patientGroup: PatientGroup.CHILD },
      patient: {
        fullName: 'Tomás Martínez Ríos',
        documentType: PatientDocumentType.CIVIL_REGISTRY,
        documentNumber: '1065998877',
        relation: PatientRelation.CHILD,
      },
      patientDocumentType: undefined,
      patientDocumentNumber: undefined,
    });
    expect(await errores(paraHijo)).toEqual([]);
    const { service } = build();

    const pedido = await service.createEmergency(solicitante, paraHijo);

    expect(pedido.status).toBe(OrderStatus.RECEIVED);
  });

  it('CP-09-15 rechaza un archivo que dice ser PDF pero no lo es, y acepta un PDF real (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({
        prescriptions: [{ mime: 'application/pdf', base64: foto(100 * KB) }],
      }),
    );

    await expect(intento).rejects.toThrow(PRESCRIPTION_CORRUPT);
    expect(pedidos.save).not.toHaveBeenCalled();

    const bueno = build();
    const pedido = await bueno.service.createEmergency(
      solicitante,
      conFormula({
        prescriptions: [{ mime: 'application/pdf', base64: pdf(200 * KB) }],
      }),
    );
    expect(pedido.status).toBe(OrderStatus.RECEIVED);
  });
});
