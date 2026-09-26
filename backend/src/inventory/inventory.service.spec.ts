import { ForbiddenException } from '@nestjs/common';
import { HubStatus } from '../common/enums/hub-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { InventoryItem } from './inventory-item.entity';
import { InventoryService } from './inventory.service';

const dto: CreateInventoryItemDto = {
  name: 'Paracetamol 500 mg',
  quantity: 20,
  lot: 'L-2026-014',
  expirationDate: '2027-03-01',
  requiresColdChain: false,
  saleType: SaleType.PRESCRIPTION,
};

const hub = {
  id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  status: HubStatus.ACTIVE,
} as Hub;

function dispatcher(overrides: Partial<User> = {}): User {
  return {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: hub.id }],
    ...overrides,
  } as User;
}

describe('InventoryService', () => {
  it('creates an item with lot, cold chain and sale type', async () => {
    const saved = {
      id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      hubId: hub.id,
      ...dto,
      createdAt: new Date(),
    } as InventoryItem;
    const items = {
      create: jest.fn().mockReturnValue(saved),
      save: jest.fn().mockResolvedValue(saved),
    };
    const hubsService = {
      requireActive: jest.fn().mockResolvedValue(hub),
    } as unknown as HubsService;
    const service = new InventoryService(items as never, hubsService);
    const result = await service.create(dispatcher(), dto);
    expect(result.saleType).toBe(SaleType.PRESCRIPTION);
    expect(result.lot).toBe('L-2026-014');
    expect(result.requiresColdChain).toBe(false);
    expect(result.quantity).toBe(20);
  });

  it('rejects inventory when the hub is suspended', async () => {
    const items = {
      create: jest.fn(),
      save: jest.fn(),
    };
    const hubsService = {
      requireActive: jest
        .fn()
        .mockRejectedValue(new ForbiddenException('La central está suspendida.')),
    } as unknown as HubsService;
    const service = new InventoryService(items as never, hubsService);
    await expect(service.create(dispatcher(), dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
