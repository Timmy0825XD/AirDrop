/**
 * Pruebas unitarias del CU-09 (Crear pedido de emergencia), casos CP-09-01 a
 * CP-09-12 de la Segunda Parte. El nombre de cada `it` empieza con el ID del
 * caso para que la terminal lo muestre en la captura. El almacenamiento de la
 * fórmula y las existencias se simulan (mocks).
 */
import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DocumentType } from '../common/enums/document-type.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { OrderPriority } from '../common/enums/order-priority.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  COORDINATES_TOGETHER,
  DOCUMENT_MISMATCH,
  NO_STOCK_MESSAGE,
  ORIGIN_STOCK_MESSAGE,
  PRESCRIPTION_IMAGE_REQUIRED,
  SPECIAL_CONTROL_MESSAGE,
} from './orders.rules';
import { OrdersService } from './orders.service';

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
  latitude: 10.4631,
  longitude: -73.2532,
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

function imagen(bytes: number): string {
  return Buffer.alloc(bytes, 1).toString('base64');
}

/** Urgencia bajo fórmula con los datos de CP-09-01. */
function conFormula(
  overrides: Partial<CreateEmergencyDto> = {},
): CreateEmergencyDto {
  return {
    medicationName: 'Insulina glargina',
    saleType: SaleType.PRESCRIPTION,
    description: 'Paciente diabético sin insulina',
    address: 'Calle 16 No. 19-35, Valledupar',
    latitude: 10.4631,
    longitude: -73.2532,
    patientDocumentType: DocumentType.CITIZENSHIP_ID,
    patientDocumentNumber: '1099000001',
    prescriptionMime: 'image/jpeg',
    prescriptionImageBase64: imagen(300 * KB),
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
    description: 'Fiebre alta persistente',
    address: 'Calle 16 No. 19-35, Valledupar',
    latitude: 10.4631,
    longitude: -73.2532,
    ...overrides,
  };
}

function build(
  oferta: { name: string; availableQuantity: number } | null = {
    name: 'Insulina glargina',
    availableQuantity: 40,
  },
) {
  const pedidos = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) =>
      Promise.resolve({
        ...value,
        id: '11111111-1111-4111-8111-111111111111',
        createdAt: new Date('2026-10-26T15:00:00.000Z'),
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
  );
  return { service, pedidos, imagenes, almacenamiento, buscarOferta };
}

async function errores(data: object): Promise<string[]> {
  const fallos = await validate(plainToInstance(CreateEmergencyDto, data));
  return fallos.flatMap((fallo) => Object.values(fallo.constraints ?? {}));
}

describe('CU-09 Crear pedido de emergencia', () => {
  it('CP-09-01 crea una urgencia bajo fórmula con imagen y documento del paciente', async () => {
    expect(await errores(conFormula())).toEqual([]);
    const { service, almacenamiento, imagenes } = build();

    const pedido = await service.createEmergency(solicitante, conFormula());

    expect(pedido.status).toBe(OrderStatus.RECEIVED);
    expect(pedido.priority).toBe(OrderPriority.HIGH);
    expect(pedido.droneId).toBeNull();
    // La imagen se envía al almacenamiento (simulado) y se guarda su llave.
    expect(almacenamiento.upload).toHaveBeenCalledTimes(1);
    expect(imagenes.save).toHaveBeenCalledTimes(1);
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
    await expect(intento).rejects.toThrow(
      'El control especial no se pide por este canal.',
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-04 rechaza una urgencia bajo fórmula sin la imagen (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ prescriptionImageBase64: undefined }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED),
    );
    await expect(intento).rejects.toThrow(
      'La venta bajo fórmula exige la imagen de la fórmula.',
    );
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
    await expect(intento).rejects.toThrow(
      'El documento de la cuenta debe ser el del paciente de la fórmula.',
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-06 rechaza una imagen de 2 MB + 1 byte (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ prescriptionImageBase64: imagen(2 * MB + 1) }),
    );

    await expect(intento).rejects.toThrow(
      'La imagen de la fórmula debe pesar hasta 2 MB.',
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-07 rechaza la descripción vacía (400)', async () => {
    expect(await errores(conFormula({ description: '' }))).toContain(
      'La descripción es obligatoria.',
    );
  });

  it('CP-09-08 rechaza una ubicación con una sola coordenada (400)', async () => {
    const { service, pedidos } = build();

    const intento = service.createEmergency(
      solicitante,
      conFormula({ longitude: undefined }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(COORDINATES_TOGETHER),
    );
    await expect(intento).rejects.toThrow(
      'La ubicación lleva latitud y longitud juntas.',
    );
    expect(pedidos.save).not.toHaveBeenCalled();
  });

  it('CP-09-09 rechaza un medicamento sin existencias en ninguna central (400)', async () => {
    const { service, pedidos } = build(null);

    const intento = service.createEmergency(
      solicitante,
      libre({
        medicationName: 'Medicamento sin existencias',
        description: 'Paciente diabético sin insulina',
      }),
    );

    await expect(intento).rejects.toThrow(
      new BadRequestException(NO_STOCK_MESSAGE),
    );
    await expect(intento).rejects.toThrow(
      'Ninguna central activa tiene ese medicamento disponible.',
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
    await expect(intento).rejects.toThrow(
      'La central de origen no tiene esa cantidad disponible.',
    );
    // requireOffer se llamó con la central de origen.
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

  // Defecto (c) de la sección 8.1 de la guía: se deja a propósito para que
  // salga Fallido. Esperado: el medicamento vacío se rechaza en el formulario.
  it('CP-09-12 rechaza el medicamento vacío con «El medicamento es obligatorio.»', async () => {
    expect(await errores(libre({ medicationName: '' }))).toContain(
      'El medicamento es obligatorio.',
    );
  });
});
