import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DocumentType } from '../common/enums/document-type.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateEmergencyDto } from './dto/create-emergency.dto';
import { CreateHubEmergencyDto } from './dto/create-hub-emergency.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  FORMULA_NOT_FOR_TRANSFER,
  NOT_THE_SUPPLYING_HUB,
  NO_STOCK_MESSAGE,
  ONLY_RECEIVED_IS_REJECTED,
  SAME_HUB_MESSAGE,
  SPECIAL_CONTROL_MESSAGE,
} from './orders.rules';
import { OrdersService } from './orders.service';

const destination = {
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  status: HubStatus.ACTIVE,
  address: 'Calle 15 # 4-20',
  latitude: 10.463,
  longitude: -73.253,
} as Hub;

const origin = {
  id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  status: HubStatus.ACTIVE,
  address: 'Carrera 7 # 10-10',
  latitude: 10.47,
  longitude: -73.26,
} as Hub;

const offer = {
  name: 'Acetaminofén 500 mg',
  saleType: SaleType.OVER_THE_COUNTER,
  requiresColdChain: false,
  availableQuantity: 20,
};

function requester(): User {
  return {
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    role: UserRole.REQUESTER,
    status: UserStatus.ACTIVE,
    documentType: DocumentType.CITIZENSHIP_ID,
    documentNumber: '1098765432',
    hubAssignments: [],
  } as unknown as User;
}

function dispatcher(): User {
  return {
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: destination.id }],
  } as unknown as User;
}

function originDispatcher(): User {
  return {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: origin.id }],
  } as unknown as User;
}

function receivedOrder(overrides: Partial<Order> = {}): Order {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    missionType: MissionType.EMERGENCY,
    status: OrderStatus.RECEIVED,
    medicationName: offer.name,
    saleType: SaleType.OVER_THE_COUNTER,
    quantity: 1,
    requesterId: requester().id,
    createdByUserId: requester().id,
    originHubId: null,
    destinationHubId: null,
    droneId: null,
    statusReason: null,
    ...overrides,
  } as Order;
}

function emergencyDto(
  overrides: Partial<CreateEmergencyDto> = {},
): CreateEmergencyDto {
  return {
    medicationName: 'Acetaminofén 500 mg',
    saleType: SaleType.OVER_THE_COUNTER,
    description: 'Dolor fuerte desde anoche',
    address: 'Calle 20 # 8-15',
    ...overrides,
  };
}

function build(options?: {
  offer?: typeof offer | null;
  requireActive?: (id: string) => Promise<Hub>;
}) {
  const saved: Order[] = [];
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    find: jest.fn(),
    findOne: jest.fn(),
    save: jest.fn((value: Order) => {
      value.id = '11111111-1111-4111-8111-111111111111';
      value.createdAt = new Date('2026-10-03T15:00:00.000Z');
      saved.push(value);
      return value;
    }),
  };
  const images = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: object) => value),
    findOne: jest.fn(),
  };
  const hubs = { find: jest.fn() };
  const stockForHub = jest.fn();
  const offers = {
    offer: jest
      .fn()
      .mockResolvedValue(options && 'offer' in options ? options.offer : offer),
    catalog: jest.fn(),
    stockForHub,
  } as unknown as InventoryOfferQuery;
  const hubsService = {
    requireActive:
      options?.requireActive ??
      jest.fn((id: string) =>
        Promise.resolve(id === origin.id ? origin : destination),
      ),
  } as unknown as HubsService;
  const service = new OrdersService(
    orders as never,
    images as never,
    hubs as never,
    offers,
    hubsService,
  );
  return { service, orders, images, stockForHub, saved };
}

describe('OrdersService emergencies', () => {
  it('creates a civil emergency as received without reserving a drone', async () => {
    const { service, saved } = build();
    const result = await service.createEmergency(requester(), emergencyDto());
    expect(result.status).toBe(OrderStatus.RECEIVED);
    expect(result.missionType).toBe(MissionType.EMERGENCY);
    expect(result.quantity).toBe(1);
    expect(result.droneId).toBeNull();
    expect(saved[0].priority).toBe('high');
  });

  it('rejects special control, a missing image and a different document', async () => {
    const { service, orders } = build();
    await expect(
      service.createEmergency(
        requester(),
        emergencyDto({ saleType: SaleType.SPECIAL_CONTROL }),
      ),
    ).rejects.toThrow(new BadRequestException(SPECIAL_CONTROL_MESSAGE));
    await expect(
      service.createEmergency(
        requester(),
        emergencyDto({
          saleType: SaleType.PRESCRIPTION,
          patientDocumentType: DocumentType.CITIZENSHIP_ID,
          patientDocumentNumber: '1098765432',
        }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.createEmergency(
        requester(),
        emergencyDto({
          saleType: SaleType.PRESCRIPTION,
          patientDocumentType: DocumentType.CITIZENSHIP_ID,
          patientDocumentNumber: '1000000000',
          prescriptionMime: 'image/jpeg',
          prescriptionImageBase64: Buffer.from('formula').toString('base64'),
        }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(orders.save).not.toHaveBeenCalled();
  });

  it('rejects a hub transfer with a formula, the same hub or a suspended origin', async () => {
    const { service } = build();
    const dto: CreateHubEmergencyDto = {
      originHubId: origin.id,
      medicationName: 'Acetaminofén 500 mg',
      saleType: SaleType.OVER_THE_COUNTER,
      quantity: 4,
      prescriptionImageBase64: Buffer.from('formula').toString('base64'),
    };
    await expect(service.createHubEmergency(dispatcher(), dto)).rejects.toThrow(
      new BadRequestException(FORMULA_NOT_FOR_TRANSFER),
    );

    await expect(
      service.createHubEmergency(dispatcher(), {
        ...dto,
        prescriptionImageBase64: undefined,
        originHubId: destination.id,
      }),
    ).rejects.toThrow(new BadRequestException(SAME_HUB_MESSAGE));

    const suspended = build({
      requireActive: () =>
        Promise.reject(new ForbiddenException('La central está suspendida.')),
    });
    await expect(
      suspended.service.createHubEmergency(dispatcher(), {
        originHubId: origin.id,
        medicationName: 'Acetaminofén 500 mg',
        saleType: SaleType.OVER_THE_COUNTER,
        quantity: 2,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('does not create an emergency when no active hub has the medication', async () => {
    const { service } = build({ offer: null });
    await expect(
      service.createEmergency(requester(), emergencyDto()),
    ).rejects.toThrow(new BadRequestException(NO_STOCK_MESSAGE));
  });
});

describe('OrdersService status', () => {
  it('shows the requester their status and a drone id that is still empty', async () => {
    const { service, orders } = build();
    orders.findOne.mockResolvedValue(receivedOrder());
    const result = await service.findOne(
      requester(),
      '11111111-1111-4111-8111-111111111111',
    );
    expect(result.status).toBe(OrderStatus.RECEIVED);
    expect(result.droneId).toBeNull();
    expect(result.statusReason).toBeNull();
  });

  it('hides an order that is not the requester’s', async () => {
    const { service, orders } = build();
    orders.findOne.mockResolvedValue(receivedOrder());
    const other = requester();
    other.id = '99999999-9999-4999-8999-999999999999';
    await expect(
      service.findOne(other, '11111111-1111-4111-8111-111111111111'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects a hub emergency from received without reserving a drone', async () => {
    const { service, orders } = build();
    const order = receivedOrder({
      requesterId: null,
      createdByUserId: dispatcher().id,
      originHubId: origin.id,
      destinationHubId: destination.id,
      quantity: 4,
    });
    orders.findOne.mockResolvedValue(order);
    const result = await service.reject(originDispatcher(), order.id, {
      reason: 'La fórmula no se lee',
    });
    expect(result.status).toBe(OrderStatus.REJECTED);
    expect(result.statusReason).toBe('La fórmula no se lee');
    expect(result.droneId).toBeNull();
  });

  it('does not let the destination hub or a later status reject the order', async () => {
    const { service, orders } = build();
    const order = receivedOrder({
      originHubId: origin.id,
      destinationHubId: destination.id,
    });
    orders.findOne.mockResolvedValue(order);
    await expect(
      service.reject(dispatcher(), order.id, { reason: 'No corresponde' }),
    ).rejects.toThrow(new ForbiddenException(NOT_THE_SUPPLYING_HUB));

    orders.findOne.mockResolvedValue(
      receivedOrder({
        status: OrderStatus.PENDING_LOAD,
        originHubId: origin.id,
      }),
    );
    await expect(
      service.reject(originDispatcher(), order.id, { reason: 'Tarde' }),
    ).rejects.toThrow(new BadRequestException(ONLY_RECEIVED_IS_REJECTED));
    expect(orders.save).not.toHaveBeenCalled();
  });

  it('rejects a civil emergency only when that hub still has the medication', async () => {
    const withoutStock = build({ offer: null });
    withoutStock.orders.findOne.mockResolvedValue(receivedOrder());
    await expect(
      withoutStock.service.reject(dispatcher(), receivedOrder().id, {
        reason: 'No hay unidades selladas',
      }),
    ).rejects.toThrow(new ForbiddenException(NOT_THE_SUPPLYING_HUB));
    expect(withoutStock.orders.save).not.toHaveBeenCalled();

    const { service, orders } = build();
    orders.findOne.mockResolvedValue(receivedOrder());
    const result = await service.reject(dispatcher(), receivedOrder().id, {
      reason: 'Fórmula vencida',
    });
    expect(result.status).toBe(OrderStatus.REJECTED);
    expect(result.droneId).toBeNull();
  });
});

describe('OrdersService queue', () => {
  const stock = [
    {
      name: offer.name,
      saleType: SaleType.OVER_THE_COUNTER,
      requiresColdChain: false,
      availableQuantity: 8,
    },
  ];

  it('lists emergencies directed to the hub that holds the stock', async () => {
    const { service, orders, stockForHub } = build();
    stockForHub.mockResolvedValue(stock);
    orders.find.mockResolvedValue([
      receivedOrder({
        id: '22222222-2222-4222-8222-222222222222',
        requesterId: null,
        createdByUserId: dispatcher().id,
        originHubId: origin.id,
        destinationHubId: destination.id,
        destinationKind: DestinationKind.HUB,
        quantity: 4,
      }),
      receivedOrder(),
      receivedOrder({
        id: '33333333-3333-4333-8333-333333333333',
        medicationName: 'Ibuprofeno 400 mg',
      }),
    ]);

    const rows = await service.listQueue(originDispatcher());

    expect(rows.map((row) => row.id)).toEqual([
      '22222222-2222-4222-8222-222222222222',
      '11111111-1111-4111-8111-111111111111',
    ]);
    expect(rows[0].availableQuantity).toBe(8);
    expect(rows[0]).not.toHaveProperty('content');
    expect(orders.find).toHaveBeenCalledWith({
      where: {
        missionType: MissionType.EMERGENCY,
        status: OrderStatus.RECEIVED,
      },
      order: { createdAt: 'ASC' },
    });
  });

  it('keeps a hub emergency in the origin queue even when stock is gone', async () => {
    const { service, orders, stockForHub } = build();
    stockForHub.mockResolvedValue([]);
    orders.find.mockResolvedValue([
      receivedOrder({
        requesterId: null,
        originHubId: origin.id,
        destinationHubId: destination.id,
        destinationKind: DestinationKind.HUB,
        quantity: 4,
      }),
    ]);
    const forOrigin = await service.listQueue(originDispatcher());
    const forDestination = await service.listQueue(dispatcher());
    expect(forOrigin).toHaveLength(1);
    expect(forOrigin[0].availableQuantity).toBe(0);
    expect(forDestination).toHaveLength(0);
  });

  it('returns the formula only to the hub that can attend a received person order', async () => {
    const { service, orders, images, stockForHub } = build();
    const formula = Buffer.from('formula');
    stockForHub.mockResolvedValue([
      {
        name: offer.name,
        saleType: SaleType.PRESCRIPTION,
        requiresColdChain: false,
        availableQuantity: 3,
      },
    ]);
    orders.findOne.mockResolvedValue(
      receivedOrder({
        saleType: SaleType.PRESCRIPTION,
        destinationKind: DestinationKind.PERSON,
      }),
    );
    images.findOne.mockResolvedValue({
      content: formula,
      mime: 'image/jpeg',
    });

    const image = await service.readPrescription(
      dispatcher(),
      receivedOrder().id,
    );
    expect(image.content).toBe(formula);
    expect(image.mime).toBe('image/jpeg');

    stockForHub.mockResolvedValue([]);
    await expect(
      service.readPrescription(originDispatcher(), receivedOrder().id),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(images.findOne).toHaveBeenCalledTimes(1);
  });
});
