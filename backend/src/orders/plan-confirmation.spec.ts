import { BadRequestException } from '@nestjs/common';
import { In, IsNull, Repository } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { InboxService } from '../notifications/inbox.service';
import { User } from '../users/user.entity';
import { DeliveryPlan } from './delivery-plan.entity';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  NOTHING_TO_CONFIRM,
  OCCURRENCE_LOCKED,
  SKIPPED_BY_RECIPIENT,
  SKIPPED_PAUSED,
  SKIPPED_UNCONFIRMED,
} from './plan-occurrence.rules';
import { PlanOccurrencesService } from './plan-occurrences.service';
import { PlanRemindersService } from './plan-reminders.service';

// Lunes 2 de noviembre de 2026, 08:00 en Colombia.
const NOW = new Date('2026-11-02T13:00:00.000Z');
const HOUR = 60 * 60 * 1000;
const REQUESTER_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const ORIGIN_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const DEST_ID = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

function occurrence(overrides: Partial<Order> = {}): Order {
  return {
    id: '11111111-1111-4111-8111-111111111111',
    planId: 'plan',
    status: OrderStatus.AWAITING_CONFIRMATION,
    droneId: null,
    fallbackKind: null,
    medicationName: 'Insulina NPH',
    saleType: SaleType.PRESCRIPTION,
    quantity: 2,
    destinationKind: DestinationKind.PERSON,
    requesterId: REQUESTER_ID,
    destinationHubId: null,
    originHubId: null,
    scheduledFor: '2026-11-03',
    scheduledAt: new Date('2026-11-03T15:00:00.000Z'),
    windowEndsAt: new Date('2026-11-03T16:00:00.000Z'),
    remindedAt: null,
    ...overrides,
  } as Order;
}

const requester = { id: REQUESTER_ID, role: UserRole.REQUESTER } as User;

describe('PlanOccurrencesService', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  function build(order: Order, affected = 1) {
    const orders = {
      findOne: jest.fn().mockResolvedValue(order),
      update: jest.fn().mockResolvedValue({ affected }),
    };
    const service = new PlanOccurrencesService(
      orders as unknown as Repository<Order>,
    );
    return { service, orders };
  }

  it('confirmar la deja en recibido, lista para el despachador', async () => {
    const { service, orders } = build(occurrence());
    await service.confirm(requester, occurrence().id);
    expect(orders.update).toHaveBeenCalledWith(
      {
        id: occurrence().id,
        status: In([OrderStatus.SCHEDULED, OrderStatus.AWAITING_CONFIRMATION]),
        droneId: IsNull(),
      },
      { status: OrderStatus.RECEIVED, confirmedAt: NOW },
    );
  });

  it('una entrega ya recibida no se vuelve a confirmar', async () => {
    const { service } = build(occurrence({ status: OrderStatus.RECEIVED }));
    await expect(service.confirm(requester, occurrence().id)).rejects.toThrow(
      new BadRequestException(NOTHING_TO_CONFIRM),
    );
  });

  it('omitir la deja omitida con su motivo', async () => {
    const { service, orders } = build(occurrence());
    await service.skip(requester, occurrence().id);
    expect(orders.update).toHaveBeenCalledWith(expect.anything(), {
      status: OrderStatus.SKIPPED,
      statusReason: SKIPPED_BY_RECIPIENT,
    });
  });

  it('moverla cambia la franja y cuenta como confirmarla', async () => {
    const { service, orders } = build(occurrence());
    await service.reschedule(requester, occurrence().id, {
      date: '2026-11-04',
      time: '16:00',
    });
    const [, changes] = orders.update.mock.calls[0] as [
      unknown,
      Partial<Order>,
    ];
    expect(changes).toMatchObject({
      status: OrderStatus.RECEIVED,
      scheduledFor: '2026-11-04',
      confirmedAt: NOW,
    });
    expect(changes.scheduledAt?.toISOString()).toBe('2026-11-04T21:00:00.000Z');
  });

  it('si el despachador la tomó al mismo tiempo, no la cambia', async () => {
    const { service } = build(occurrence(), 0);
    await expect(service.skip(requester, occurrence().id)).rejects.toThrow(
      new BadRequestException(OCCURRENCE_LOCKED),
    );
  });
});

describe('PlanRemindersService', () => {
  function build(state: {
    due?: Order[];
    unconfirmed?: Order[];
    pausedReceived?: Order[];
    plans?: Array<Partial<DeliveryPlan>>;
    stock?: number;
    affected?: number;
  }) {
    const orders = {
      find: jest.fn((options: { where: { status: unknown } }) => {
        const status = options.where.status;
        if (status === OrderStatus.SCHEDULED) {
          return Promise.resolve(state.due ?? []);
        }
        if (status === OrderStatus.RECEIVED) {
          return Promise.resolve(state.pausedReceived ?? []);
        }
        return Promise.resolve(state.unconfirmed ?? []);
      }),
      update: jest.fn().mockResolvedValue({ affected: state.affected ?? 1 }),
    };
    const plans = {
      find: jest.fn((options: { where: { paused?: boolean } }) =>
        Promise.resolve(
          options.where.paused
            ? (state.plans ?? []).filter((plan) => plan.paused)
            : (state.plans ?? []),
        ),
      ),
    };
    const inbox = {
      notifyUser: jest.fn().mockResolvedValue(undefined),
      notifyHubDispatchers: jest.fn().mockResolvedValue(undefined),
    };
    const offers = {
      offer: jest
        .fn()
        .mockResolvedValue({ availableQuantity: state.stock ?? 10 }),
    };
    const service = new PlanRemindersService(
      orders as unknown as Repository<Order>,
      plans as unknown as Repository<DeliveryPlan>,
      inbox as unknown as InboxService,
      offers as unknown as InventoryOfferQuery,
    );
    return { service, orders, inbox, offers };
  }

  const scheduled = (overrides: Partial<Order> = {}) =>
    occurrence({ status: OrderStatus.SCHEDULED, ...overrides });

  it('a T-24 h le pide confirmar a la persona, sin decir el medicamento', async () => {
    const { service, orders, inbox } = build({ due: [scheduled()] });
    await service.runDue(NOW);
    expect(orders.update).toHaveBeenCalledWith(
      {
        id: scheduled().id,
        status: OrderStatus.SCHEDULED,
        remindedAt: IsNull(),
      },
      { status: OrderStatus.AWAITING_CONFIRMATION, remindedAt: NOW },
    );
    const [userId, notice] = inbox.notifyUser.mock.calls[0] as [
      string,
      { kind: NotificationKind; body: string },
    ];
    expect(userId).toBe(REQUESTER_ID);
    expect(notice.kind).toBe(NotificationKind.CONFIRM_DELIVERY);
    expect(notice.body).toContain('martes, 3 de noviembre, de 10:00 a 11:00');
    expect(notice.body).toContain('antes de las 08:00');
    expect(notice.body).not.toContain('Insulina');
  });

  it('un abastecimiento se confirma solo y avisa a destino y a origen', async () => {
    const toHub = scheduled({
      destinationKind: DestinationKind.HUB,
      requesterId: null,
      destinationHubId: DEST_ID,
      originHubId: ORIGIN_ID,
    });
    const { service, orders, inbox } = build({ due: [toHub] });
    await service.runDue(NOW);
    expect(orders.update).toHaveBeenCalledWith(expect.anything(), {
      status: OrderStatus.RECEIVED,
      confirmedAt: NOW,
      remindedAt: NOW,
    });
    const calls = inbox.notifyHubDispatchers.mock.calls as Array<
      [string, { kind: NotificationKind }]
    >;
    const kinds = calls.map(([hubId, notice]) => [hubId, notice.kind]);
    expect(kinds).toEqual([
      [DEST_ID, NotificationKind.INCOMING_SUPPLY],
      [ORIGIN_ID, NotificationKind.DISPATCH_SOON],
    ]);
  });

  it('avisa si hoy no alcanza el stock, sin bloquear la entrega', async () => {
    const { service, inbox } = build({ due: [scheduled()], stock: 1 });
    await service.runDue(NOW);
    const kinds = inbox.notifyUser.mock.calls.map(
      ([, notice]) => (notice as { kind: string }).kind,
    );
    expect(kinds).toEqual([
      NotificationKind.CONFIRM_DELIVERY,
      NotificationKind.STOCK_WARNING,
    ]);
  });

  it('un plan en pausa no avisa', async () => {
    const { service, inbox } = build({
      due: [scheduled()],
      plans: [{ id: 'plan', paused: true }],
    });
    await service.runDue(NOW);
    expect(inbox.notifyUser).not.toHaveBeenCalled();
  });

  it('a T-2 h omite lo que no se confirmó y avisa', async () => {
    const late = occurrence({ scheduledAt: new Date(NOW.getTime() + HOUR) });
    const { service, orders, inbox } = build({ unconfirmed: [late] });
    await service.runDue(NOW);
    expect(orders.update).toHaveBeenCalledWith(
      {
        id: late.id,
        status: OrderStatus.AWAITING_CONFIRMATION,
        droneId: IsNull(),
      },
      { status: OrderStatus.SKIPPED, statusReason: SKIPPED_UNCONFIRMED },
    );
    expect(inbox.notifyUser).toHaveBeenCalledWith(
      REQUESTER_ID,
      expect.objectContaining({ kind: NotificationKind.DELIVERY_SKIPPED }),
    );
  });

  it('con el plan en pausa también omite lo ya confirmado sin dron', async () => {
    const confirmed = occurrence({
      status: OrderStatus.RECEIVED,
      scheduledAt: new Date(NOW.getTime() + HOUR),
    });
    const { service, orders } = build({
      pausedReceived: [confirmed],
      plans: [{ id: 'plan', paused: true }],
    });
    await service.runDue(NOW);
    expect(orders.update).toHaveBeenCalledWith(
      { id: confirmed.id, status: OrderStatus.RECEIVED, droneId: IsNull() },
      { status: OrderStatus.SKIPPED, statusReason: SKIPPED_PAUSED },
    );
  });

  it('si otra pasada ya la tomó, no repite el aviso', async () => {
    const { service, inbox } = build({ due: [scheduled()], affected: 0 });
    await service.runDue(NOW);
    expect(inbox.notifyUser).not.toHaveBeenCalled();
  });
});
