import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { QuarantineReason } from '../common/enums/quarantine-reason.enum';
import { ReturnOutcome } from '../common/enums/return-outcome.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { InventoryItem } from './inventory-item.entity';
import { QuarantineRecord } from './quarantine-record.entity';
import {
  NOT_THE_RETURN_HUB,
  ONLY_RETURNED_IS_CHECKED,
  RETURN_ALREADY_CHECKED,
} from './restock.rules';
import { DISPATCHED_LOT_MISSING, RestockService } from './restock.service';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const DEST_HUB_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const ITEM_ID = '55555555-5555-4555-8555-555555555555';

function dispatcher(hubId = HUB_ID): User {
  return {
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    role: UserRole.DISPATCHER,
    hubAssignments: [{ hubId }],
  } as unknown as User;
}

function returned(overrides: Partial<Order> = {}): Order {
  return {
    id: ORDER_ID,
    status: OrderStatus.RETURNED,
    destinationKind: DestinationKind.PERSON,
    destinationHubId: null,
    originHubId: HUB_ID,
    medicationName: 'Insulina NPH',
    saleType: SaleType.PRESCRIPTION,
    requiresColdChain: true,
    quantity: 2,
    inventoryItemId: ITEM_ID,
    dispatchedLot: 'L-7',
    dispatchedLotExpiresOn: '2027-03-01',
    coldChainAlertAt: null,
    receiptSealIntact: null,
    returnCheckedAt: null,
    returnOutcome: null,
    ...overrides,
  } as Order;
}

function item(overrides: Partial<InventoryItem> = {}): InventoryItem {
  return {
    id: ITEM_ID,
    hubId: HUB_ID,
    name: 'Insulina NPH',
    quantity: 4,
    lot: 'L-7',
    expirationDate: '2027-03-01',
    requiresColdChain: true,
    saleType: SaleType.PRESCRIPTION,
    ...overrides,
  } as InventoryItem;
}

function build(state: {
  order: Order;
  source?: InventoryItem | null;
  matching?: InventoryItem | null;
}) {
  const saved: unknown[] = [];
  const created: Array<{ entity: unknown; data: object }> = [];
  const matchQuery = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    setLock: jest.fn().mockReturnThis(),
    getOne: jest.fn().mockResolvedValue(state.matching ?? null),
  };
  const manager = {
    findOne: jest.fn(
      (
        entity: unknown,
        options: { where: { id?: string; hubId?: string } },
      ) => {
        if (entity === Order) return Promise.resolve(state.order);
        if (entity === InventoryItem) {
          const source = state.source ?? null;
          const matches =
            source &&
            source.id === options.where.id &&
            (options.where.hubId === undefined ||
              source.hubId === options.where.hubId);
          return Promise.resolve(matches ? source : null);
        }
        return Promise.resolve(null);
      },
    ),
    createQueryBuilder: jest.fn(() => matchQuery),
    create: jest.fn((entity: unknown, data: object) => {
      created.push({ entity, data });
      return { ...data };
    }),
    save: jest.fn((entity: unknown) => {
      saved.push(entity);
      return Promise.resolve(entity);
    }),
  };
  const dataSource = {
    transaction: jest.fn((work: (unit: EntityManager) => Promise<unknown>) =>
      work(manager as unknown as EntityManager),
    ),
  };
  const hubsService = {
    requireActive: jest.fn((id: string) =>
      Promise.resolve({ id, status: HubStatus.ACTIVE } as Hub),
    ),
  };
  const service = new RestockService(
    dataSource as unknown as DataSource,
    hubsService as unknown as HubsService,
  );
  return { service, manager, saved, created, matchQuery };
}

describe('RestockService.checkReturn', () => {
  it('sin alerta de frío y con el empaque íntegro, el lote vuelve al mismo ítem', async () => {
    const source = item();
    const { service, created } = build({ order: returned(), source });
    const result = await service.checkReturn(dispatcher(), ORDER_ID, true);
    expect(source.quantity).toBe(6);
    expect(result.returnOutcome).toBe(ReturnOutcome.RESTOCKED);
    expect(result.returnCheckedAt).toBeInstanceOf(Date);
    expect(created).toHaveLength(0);
  });

  it('si borraron el ítem, recrea el lote con el registro de salida', async () => {
    const { service, created } = build({ order: returned(), source: null });
    await service.checkReturn(dispatcher(), ORDER_ID, true);
    expect(created).toEqual([
      {
        entity: InventoryItem,
        data: {
          hubId: HUB_ID,
          name: 'Insulina NPH',
          quantity: 2,
          lot: 'L-7',
          expirationDate: '2027-03-01',
          requiresColdChain: true,
          saleType: SaleType.PRESCRIPTION,
        },
      },
    ]);
  });

  it('con alerta de frío queda en cuarentena y no toca el stock', async () => {
    const source = item();
    const { service, created } = build({
      order: returned({ coldChainAlertAt: new Date() }),
      source,
    });
    const result = await service.checkReturn(dispatcher(), ORDER_ID, true);
    expect(source.quantity).toBe(4);
    expect(result.returnOutcome).toBe(ReturnOutcome.QUARANTINED);
    expect(created).toEqual([
      {
        entity: QuarantineRecord,
        data: {
          orderId: ORDER_ID,
          hubId: HUB_ID,
          medicationName: 'Insulina NPH',
          saleType: SaleType.PRESCRIPTION,
          lot: 'L-7',
          expirationDate: '2027-03-01',
          quantity: 2,
          reason: QuarantineReason.COLD_CHAIN,
        },
      },
    ]);
  });

  it('con el empaque comprometido queda en cuarentena por empaque', async () => {
    const source = item();
    const { service, created } = build({ order: returned(), source });
    await service.checkReturn(dispatcher(), ORDER_ID, false);
    expect(source.quantity).toBe(4);
    expect(created[0].data).toMatchObject({
      reason: QuarantineReason.PACKAGING,
    });
  });

  it('solo la central de origen, una vez y con el pedido devuelto', async () => {
    await expect(
      build({ order: returned() }).service.checkReturn(
        dispatcher(DEST_HUB_ID),
        ORDER_ID,
        true,
      ),
    ).rejects.toThrow(new ForbiddenException(NOT_THE_RETURN_HUB));
    await expect(
      build({
        order: returned({ status: OrderStatus.DELIVERED }),
      }).service.checkReturn(dispatcher(), ORDER_ID, true),
    ).rejects.toThrow(new BadRequestException(ONLY_RETURNED_IS_CHECKED));
    await expect(
      build({
        order: returned({ returnCheckedAt: new Date() }),
      }).service.checkReturn(dispatcher(), ORDER_ID, true),
    ).rejects.toThrow(new BadRequestException(RETURN_ALREADY_CHECKED));
  });

  it('sin registro de salida ni ítem no puede reingresar', async () => {
    const { service } = build({
      order: returned({ dispatchedLot: null, dispatchedLotExpiresOn: null }),
      source: null,
    });
    await expect(
      service.checkReturn(dispatcher(), ORDER_ID, true),
    ).rejects.toThrow(new ConflictException(DISPATCHED_LOT_MISSING));
  });
});

describe('RestockService.receiveTransfer', () => {
  const transfer = () =>
    returned({
      status: OrderStatus.AWAITING_DELIVERY,
      destinationKind: DestinationKind.HUB,
      destinationHubId: DEST_HUB_ID,
    });

  it('suma al lote igual que ya existe en la central de destino', async () => {
    const shelf = item({ id: 'otro', hubId: DEST_HUB_ID, quantity: 10 });
    const { service, manager, matchQuery } = build({
      order: transfer(),
      matching: shelf,
    });
    await service.receiveTransfer(
      manager as unknown as EntityManager,
      transfer(),
    );
    expect(shelf.quantity).toBe(12);
    expect(matchQuery.where).toHaveBeenCalledWith('item.hubId = :hubId', {
      hubId: DEST_HUB_ID,
    });
  });

  it('si destino no tiene ese lote, lo crea allá', async () => {
    const { service, manager, created } = build({ order: transfer() });
    await service.receiveTransfer(
      manager as unknown as EntityManager,
      transfer(),
    );
    expect(created[0].data).toMatchObject({
      hubId: DEST_HUB_ID,
      lot: 'L-7',
      quantity: 2,
    });
  });
});
