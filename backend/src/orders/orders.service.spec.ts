import { BadRequestException, ForbiddenException } from '@nestjs/common';
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
  NO_STOCK_MESSAGE,
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
  };
  const hubs = { find: jest.fn() };
  const offers = {
    offer: jest
      .fn()
      .mockResolvedValue(options && 'offer' in options ? options.offer : offer),
    catalog: jest.fn(),
    stockForHub: jest.fn(),
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
  return { service, orders, saved };
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
