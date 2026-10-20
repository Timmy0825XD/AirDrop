import { ConflictException, ForbiddenException } from '@nestjs/common';
import { HubStatus } from '../common/enums/hub-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { InventoryItem } from './inventory-item.entity';
import {
  ITEM_COMMITTED_IN_MISSION,
  InventoryService,
} from './inventory.service';

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

const orders = { exists: jest.fn().mockResolvedValue(false) };

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
    const service = new InventoryService(
      items as never,
      orders as never,
      hubsService,
    );
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
        .mockRejectedValue(
          new ForbiddenException('La central está suspendida.'),
        ),
    } as unknown as HubsService;
    const service = new InventoryService(
      items as never,
      orders as never,
      hubsService,
    );
    await expect(service.create(dispatcher(), dto)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  describe('remove', () => {
    const item = { id: 'cccccccc-cccc-cccc-cccc-cccccccccccc', hubId: hub.id };

    function removalService(committed: boolean) {
      const items = {
        findOne: jest.fn().mockResolvedValue(item),
        remove: jest.fn().mockResolvedValue(undefined),
      };
      const orderRepo = { exists: jest.fn().mockResolvedValue(committed) };
      const hubsService = {
        requireActive: jest.fn().mockResolvedValue(hub),
      } as unknown as HubsService;
      return {
        items,
        orderRepo,
        service: new InventoryService(
          items as never,
          orderRepo as never,
          hubsService,
        ),
      };
    }

    it('CP-08-09 rechaza dar de baja un ítem comprometido en una misión', async () => {
      const { items, service } = removalService(true);
      await expect(service.remove(dispatcher(), item.id)).rejects.toThrow(
        new ConflictException(ITEM_COMMITTED_IN_MISSION),
      );
      expect(items.remove).not.toHaveBeenCalled();
    });

    it('da de baja un ítem libre', async () => {
      const { items, service } = removalService(false);
      await service.remove(dispatcher(), item.id);
      expect(items.remove).toHaveBeenCalledWith(item);
    });

    it('solo mira pedidos en preparación, vuelo, espera o retorno', async () => {
      const { orderRepo, service } = removalService(false);
      await service.remove(dispatcher(), item.id);
      const [{ where }] = orderRepo.exists.mock.calls[0] as [
        { where: { inventoryItemId: string; status: { value: string[] } } },
      ];
      expect(where.inventoryItemId).toBe(item.id);
      expect(where.status.value).toEqual([
        'pending_load',
        'in_flight',
        'awaiting_delivery',
        'returning',
      ]);
    });
  });
});
