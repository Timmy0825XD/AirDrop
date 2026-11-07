import { ConflictException } from '@nestjs/common';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Hub } from '../hubs/hub.entity';
import { Order } from '../orders/order.entity';
import { AutoDispatcherService } from './auto-dispatcher.service';
import {
  ACTOR_RETRY_MS,
  AUTHORIZE_DELAY_MS,
  LOAD_DELAY_MS,
} from './sim-actors.rules';

const NOW = new Date('2026-11-06T15:00:00.000Z');
const HUB = { id: 'hub-1', latitude: 10.47, longitude: -73.25 } as Hub;

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: 'order-1',
    missionType: MissionType.EMERGENCY,
    status: OrderStatus.RECEIVED,
    fallbackKind: null,
    droneId: null,
    originHubId: null,
    dispatchOffers: null,
    reassignedAt: null,
    reassignedFromHubId: null,
    scheduledAt: null,
    windowEndsAt: null,
    scheduledFor: null,
    latitude: 10.471,
    longitude: -73.251,
    authorizedAt: null,
    loadConfirmedAt: null,
    createdAt: new Date(NOW.getTime() - AUTHORIZE_DELAY_MS),
    ...overrides,
  } as Order;
}

function build(state: {
  on?: boolean;
  waiting?: Order[];
  ready?: Order[];
  awaiting?: string[];
}) {
  const actors = {
    view: () => ({ autoDispatcher: state.on ?? true, orderFlow: false }),
  };
  const decision = {
    autoAuthorize: jest.fn().mockResolvedValue({}),
    autoConfirmLoad: jest.fn().mockResolvedValue({}),
  };
  const ordersService = {
    hubsAwaiting: jest.fn().mockResolvedValue(state.awaiting ?? [HUB.id]),
  };
  const orders = {
    find: jest.fn((options: { where: { status: unknown } }) =>
      Promise.resolve(
        options.where.status === OrderStatus.PENDING_LOAD
          ? (state.ready ?? [])
          : (state.waiting ?? []),
      ),
    ),
  };
  const hubs = { find: jest.fn().mockResolvedValue([HUB]) };
  const service = new AutoDispatcherService(
    { get: () => 'true' } as never,
    actors as never,
    decision as never,
    ordersService as never,
    orders as never,
    hubs as never,
  );
  return { service, decision, ordersService, orders };
}

describe('AutoDispatcherService (RF-37)', () => {
  it('apagado no toca nada', async () => {
    const { service, decision, orders } = build({
      on: false,
      waiting: [order()],
    });
    await service.runDue(NOW);
    expect(orders.find).not.toHaveBeenCalled();
    expect(decision.autoAuthorize).not.toHaveBeenCalled();
  });

  it('a los 10 s simulados autoriza en la central que tiene el pedido en su cola', async () => {
    const { service, decision } = build({ waiting: [order()] });
    await service.runDue(NOW);
    expect(decision.autoAuthorize).toHaveBeenCalledWith(HUB.id, 'order-1');
  });

  it('antes de los 10 s espera', async () => {
    const fresh = order({ createdAt: new Date(NOW.getTime() - 9_000) });
    const { service, decision } = build({ waiting: [fresh] });
    await service.runDue(NOW);
    expect(decision.autoAuthorize).not.toHaveBeenCalled();
  });

  it('la urgencia escalonada la autoriza la central a la que se ofreció, sin ir al stock', async () => {
    const offered = order({
      dispatchOffers: [
        {
          hubId: HUB.id,
          name: 'Hospital',
          etaMs: 60_000,
          ready: true,
          offeredAt: new Date(NOW.getTime() - AUTHORIZE_DELAY_MS).toISOString(),
          declinedAt: null,
          declineReason: null,
        },
      ],
    });
    const { service, decision, ordersService } = build({ waiting: [offered] });
    await service.runDue(NOW);
    expect(ordersService.hubsAwaiting).not.toHaveBeenCalled();
    expect(decision.autoAuthorize).toHaveBeenCalledWith(HUB.id, 'order-1');
  });

  it('confirma la carga 20 s después de autorizar', async () => {
    const pending = order({
      status: OrderStatus.PENDING_LOAD,
      originHubId: HUB.id,
      droneId: 'drone-1',
      authorizedAt: new Date(NOW.getTime() - LOAD_DELAY_MS),
    });
    const { service, decision } = build({ ready: [pending] });
    await service.runDue(NOW);
    expect(decision.autoConfirmLoad).toHaveBeenCalledWith(HUB.id, 'order-1');
  });

  it('si el motor dice que no, no insiste hasta que pase la espera', async () => {
    const { service, decision } = build({ waiting: [order()] });
    decision.autoAuthorize.mockRejectedValue(
      new ConflictException('La central está sin energía.'),
    );
    await service.runDue(NOW);
    await service.runDue(new Date(NOW.getTime() + 5_000));
    expect(decision.autoAuthorize).toHaveBeenCalledTimes(1);
    await service.runDue(new Date(NOW.getTime() + ACTOR_RETRY_MS));
    expect(decision.autoAuthorize).toHaveBeenCalledTimes(2);
  });
});
