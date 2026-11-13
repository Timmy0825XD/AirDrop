/**
 * Fórmula con varias hojas (RU-25) y quién la puede leer (RF-27): la central
 * que decide y, después, la que autorizó desde su histórico.
 */
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DocumentType } from '../common/enums/document-type.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { OrdersService } from './orders.service';
import { PDF_MIME, PRESCRIPTION_FILES_RULE } from './prescription.rules';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const HUB_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const OTHER_HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

const holder = {
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  role: UserRole.REQUESTER,
  status: UserStatus.ACTIVE,
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1099000001',
  hubAssignments: [],
} as unknown as User;

const dispatcherOf = (hubId: string) =>
  ({
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId }],
  }) as unknown as User;

const jpeg = (tag: number) =>
  Buffer.from([0xff, 0xd8, 0xff, tag]).toString('base64');
const pdf = Buffer.from('%PDF-1.7 hoja').toString('base64');

function dto(overrides: Partial<CreateEmergencyDto> = {}): CreateEmergencyDto {
  return {
    medicationName: 'Amoxicilina 500 mg',
    saleType: SaleType.PRESCRIPTION,
    description: 'Infección de garganta',
    latitude: 10.4631,
    longitude: -73.2532,
    patientDocumentType: DocumentType.CITIZENSHIP_ID,
    patientDocumentNumber: '1099000001',
    ...overrides,
  };
}

function delivered(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    saleType: SaleType.PRESCRIPTION,
    status: OrderStatus.DELIVERED,
    originHubId: HUB_ID,
    medicationName: 'Amoxicilina 500 mg',
    ...overrides,
  } as Order;
}

function build(order: Order | null = null) {
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) =>
      Promise.resolve({ ...value, id: ORDER_ID, createdAt: new Date() }),
    ),
    findOne: jest.fn().mockResolvedValue(order),
    delete: jest.fn(),
  };
  const images = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) => Promise.resolve(value)),
    find: jest
      .fn()
      .mockResolvedValue([
        { position: 0, objectKey: `${ORDER_ID}.pdf`, mime: PDF_MIME },
      ]),
    delete: jest.fn(),
  };
  const storage = {
    upload: jest.fn(
      (orderId: string, _content: Buffer, _mime: string, position: number) =>
        Promise.resolve(`${orderId}-${position + 1}.jpg`),
    ),
    download: jest.fn().mockResolvedValue(Buffer.from('%PDF-1.7')),
  };
  const offers = {
    offer: jest.fn().mockResolvedValue({
      name: 'Amoxicilina 500 mg',
      availableQuantity: 10,
      saleType: SaleType.PRESCRIPTION,
      requiresColdChain: false,
    }),
    stockForHub: jest.fn().mockResolvedValue([]),
  } as unknown as InventoryOfferQuery;
  const hubsService = {
    requireActive: jest.fn((id: string) => Promise.resolve({ id })),
  } as unknown as HubsService;
  const service = new OrdersService(
    orders as never,
    images as never,
    storage as never,
    {} as never,
    offers,
    hubsService,
    {} as never,
    { assertDestinationAllowed: () => Promise.resolve() } as never,
    { statusChanged: jest.fn().mockResolvedValue(undefined) } as never,
  );
  return { service, orders, images, storage };
}

describe('Fórmula con varias hojas (RU-25)', () => {
  it('guarda 3 fotos en orden, cada una con su posición', async () => {
    const { service, images, storage } = build();
    await service.createEmergency(
      holder,
      dto({
        prescriptions: [1, 2, 3].map((tag) => ({
          mime: 'image/jpeg',
          base64: jpeg(tag),
        })),
      }),
    );
    expect(storage.upload.mock.calls.map((call) => call[3])).toEqual([0, 1, 2]);
    expect(images.save.mock.calls.map((call) => call[0])).toEqual([
      expect.objectContaining({ position: 0, mime: 'image/jpeg' }),
      expect.objectContaining({ position: 1, mime: 'image/jpeg' }),
      expect.objectContaining({ position: 2, mime: 'image/jpeg' }),
    ]);
  });

  it('guarda un PDF', async () => {
    const { service, images } = build();
    await service.createEmergency(
      holder,
      dto({ prescriptions: [{ mime: PDF_MIME, base64: pdf }] }),
    );
    expect(images.save).toHaveBeenCalledWith(
      expect.objectContaining({ position: 0, mime: PDF_MIME }),
    );
  });

  it('no guarda nada si mezclan un PDF con fotos', async () => {
    const { service, orders } = build();
    await expect(
      service.createEmergency(
        holder,
        dto({
          prescriptions: [
            { mime: PDF_MIME, base64: pdf },
            { mime: 'image/jpeg', base64: jpeg(1) },
          ],
        }),
      ),
    ).rejects.toThrow(new BadRequestException(PRESCRIPTION_FILES_RULE));
    expect(orders.save).not.toHaveBeenCalled();
  });

  it('si falla la segunda hoja, borra lo subido y el pedido', async () => {
    const { service, orders, images, storage } = build();
    storage.upload
      .mockResolvedValueOnce(`${ORDER_ID}.jpg`)
      .mockRejectedValueOnce(new Error('bucket caído'));
    await expect(
      service.createEmergency(
        holder,
        dto({
          prescriptions: [1, 2].map((tag) => ({
            mime: 'image/jpeg',
            base64: jpeg(tag),
          })),
        }),
      ),
    ).rejects.toThrow('bucket caído');
    expect(images.delete).toHaveBeenCalledWith({ orderId: ORDER_ID });
    expect(orders.delete).toHaveBeenCalledWith({ id: ORDER_ID });
  });
});

describe('Quién lee la fórmula (RF-27)', () => {
  it('la central que autorizó la sigue viendo en el histórico', async () => {
    const { service } = build(delivered());
    const list = await service.listPrescription(dispatcherOf(HUB_ID), ORDER_ID);
    expect(list.files).toEqual([
      { index: 0, mime: PDF_MIME, filename: 'formula-11111111-1.pdf' },
    ]);
    const file = await service.readPrescription(
      dispatcherOf(HUB_ID),
      ORDER_ID,
      0,
    );
    expect(file.filename).toBe('formula-11111111-1.pdf');
    expect(file.mime).toBe(PDF_MIME);
  });

  it('otra central no la ve después de entregado', async () => {
    const { service } = build(delivered());
    await expect(
      service.listPrescription(dispatcherOf(OTHER_HUB_ID), ORDER_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('una hoja que no existe responde 404', async () => {
    const { service } = build(delivered());
    await expect(
      service.readPrescription(dispatcherOf(HUB_ID), ORDER_ID, 2),
    ).rejects.toThrow(
      new NotFoundException('La fórmula no tiene ese archivo.'),
    );
  });

  it('un pedido de venta libre no tiene fórmula', async () => {
    const { service } = build(
      delivered({ saleType: SaleType.OVER_THE_COUNTER }),
    );
    await expect(
      service.listPrescription(dispatcherOf(HUB_ID), ORDER_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
