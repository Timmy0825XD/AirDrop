import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { simClock } from '../common/clock/sim-clock';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { NotificationKind } from '../common/enums/notification-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { StartHubOutageDto } from '../control/dto/start-hub-outage.dto';
import { hubOutageDraft } from '../control/timeline.rules';
import { Hub } from '../hubs/hub.entity';
import { HubOutageService } from '../hubs/hub-outage.service';
import {
  HUB_ALREADY_WITHOUT_POWER,
  HUB_HAS_POWER,
  OUTAGE_DECLINE_REASON,
  SUSPENDED_HUB_OUTAGE,
  isPowered,
  outageEnd,
} from '../hubs/hub-power.rules';
import { DispatchOffer, Order } from '../orders/order.entity';
import { withdrawHub } from './dispatch.rules';
import { EmergencyDispatchService } from './emergency-dispatch.service';
import { HubOutageRelocationService } from './hub-outage-relocation.service';

const NOW = new Date('2026-11-06T15:00:00.000Z');
const MIN = 60_000;

function offer(hubId: string, overrides: Partial<DispatchOffer> = {}) {
  return {
    hubId,
    name: `Central ${hubId}`,
    etaMs: 6 * MIN,
    ready: true,
    offeredAt: null,
    declinedAt: null,
    declineReason: null,
    ...overrides,
  };
}

describe('Central sin energía: cuándo tiene energía (RF-36)', () => {
  it('sin fecha o con la fecha ya pasada tiene energía', () => {
    expect(isPowered({ powerOutageUntil: null }, NOW)).toBe(true);
    expect(isPowered({ powerOutageUntil: NOW }, NOW)).toBe(true);
    expect(
      isPowered({ powerOutageUntil: new Date(NOW.getTime() + 1) }, NOW),
    ).toBe(false);
  });

  it('el apagón dura lo pedido en hora simulada', () => {
    expect(outageEnd(NOW, 45).toISOString()).toBe('2026-11-06T15:45:00.000Z');
  });

  it('la duración va de 5 a 240 minutos', async () => {
    const errors = async (durationMin: number) =>
      (await validate(plainToInstance(StartHubOutageDto, { durationMin })))
        .length;
    await expect(errors(30)).resolves.toBe(0);
    await expect(errors(2)).resolves.toBe(1);
    await expect(errors(300)).resolves.toBe(1);
  });
});

describe('La central sin energía sale de la oferta escalonada (RU-10, RF-36)', () => {
  it('si la tenía abierta, se ofrece ya a la siguiente', () => {
    const offers = [
      offer('A', { offeredAt: NOW.toISOString() }),
      offer('B', { etaMs: 8 * MIN }),
    ];
    const result = withdrawHub(offers, 'A', OUTAGE_DECLINE_REASON, NOW)!;
    expect(result.offers[0]).toMatchObject({
      declinedAt: NOW.toISOString(),
      declineReason: OUTAGE_DECLINE_REASON,
    });
    expect(result.step?.openedHubId).toBe('B');
  });

  it('si todavía no le tocaba, queda fuera y la escalera ya no se la ofrece', () => {
    const offers = [
      offer('A', { offeredAt: NOW.toISOString() }),
      offer('B'),
      offer('C'),
    ];
    const result = withdrawHub(offers, 'B', OUTAGE_DECLINE_REASON, NOW)!;
    expect(result.step).toBeNull();
    const b = result.offers.find((item) => item.hubId === 'B')!;
    // Con `offeredAt` puesto, `openNextOffer` salta a C.
    expect(b.offeredAt).not.toBeNull();
    expect(b.declinedAt).not.toBeNull();
  });

  it('sin la central en la lista, o ya declinada, no cambia nada', () => {
    expect(withdrawHub([offer('A')], 'Z', 'x', NOW)).toBeNull();
    expect(
      withdrawHub(
        [offer('A', { declinedAt: NOW.toISOString() })],
        'A',
        'x',
        NOW,
      ),
    ).toBeNull();
  });

  it('el servicio la saca de cada urgencia abierta y avisa a la central nueva', async () => {
    const order = {
      id: 'order-1',
      missionType: MissionType.EMERGENCY,
      destinationKind: DestinationKind.PERSON,
      status: OrderStatus.RECEIVED,
      originHubId: null,
      dispatchOffers: [
        offer('A', { offeredAt: NOW.toISOString() }),
        offer('B', { etaMs: 8 * MIN }),
      ],
      nextEscalationAt: null,
    } as unknown as Order;
    const manager = {
      findOne: jest.fn().mockResolvedValue(order),
      save: jest.fn((value: Order) => Promise.resolve(value)),
    };
    const dataSource = {
      getRepository: () => ({ find: jest.fn().mockResolvedValue([order]) }),
      transaction: jest.fn((work: (m: typeof manager) => unknown) =>
        work(manager),
      ),
    };
    const notifications = {
      queueChanged: jest.fn().mockResolvedValue(undefined),
      statusChanged: jest.fn().mockResolvedValue(undefined),
    };
    const service = new EmergencyDispatchService(
      dataSource as never,
      {} as never,
      {} as never,
      {} as never,
      notifications as never,
    );
    await expect(service.withdrawHub('A', NOW)).resolves.toBe(1);
    expect(order.dispatchOffers![1].offeredAt).toBe(NOW.toISOString());
    expect(notifications.queueChanged).toHaveBeenCalledWith('A', 'order-1');
    expect(notifications.queueChanged).toHaveBeenCalledWith('B', 'order-1');
  });
});

function hub(overrides: Partial<Hub> = {}): Hub {
  return {
    id: 'hub-1',
    name: 'Clínica Valledupar',
    status: HubStatus.ACTIVE,
    latitude: 10.456,
    longitude: -73.264,
    powerOutageUntil: null,
    ...overrides,
  } as Hub;
}

function outageService(found: Hub | null, due: Hub[] = []) {
  const repo = {
    findOne: jest.fn().mockResolvedValue(found),
    find: jest.fn().mockResolvedValue(due),
    update: jest.fn().mockResolvedValue(undefined),
  };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const inbox = {
    notifyHubDispatchers: jest.fn().mockResolvedValue(undefined),
  };
  const service = new HubOutageService(
    repo as never,
    publisher as never,
    inbox as never,
  );
  const listener = jest.fn().mockResolvedValue(undefined);
  service.onOutageStarted(listener);
  return { service, repo, publisher, inbox, listener };
}

describe('HubOutageService (RF-36, CU-45)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('apaga la central, lo cuenta, avisa a sus despachadores y mueve sus pedidos', async () => {
    const { service, repo, publisher, inbox, listener } = outageService(hub());
    const outage = await service.start('hub-1', 30);
    expect(outage.until).toBe('2026-11-06T15:30:00.000Z');
    expect(repo.update).toHaveBeenCalledWith(
      { id: 'hub-1' },
      { powerOutageUntil: new Date('2026-11-06T15:30:00.000Z') },
    );
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'hub-outage', action: 'started' }),
    );
    expect(inbox.notifyHubDispatchers).toHaveBeenCalledWith(
      'hub-1',
      expect.objectContaining({ kind: NotificationKind.HUB_OUTAGE }),
    );
    expect(listener).toHaveBeenCalledWith('hub-1');
  });

  it('una central suspendida o ya sin energía no se apaga otra vez', async () => {
    await expect(
      outageService(hub({ status: HubStatus.SUSPENDED })).service.start(
        'hub-1',
        30,
      ),
    ).rejects.toThrow(new BadRequestException(SUSPENDED_HUB_OUTAGE));
    await expect(
      outageService(
        hub({ powerOutageUntil: new Date(NOW.getTime() + MIN) }),
      ).service.start('hub-1', 30),
    ).rejects.toThrow(new ConflictException(HUB_ALREADY_WITHOUT_POWER));
  });

  it('al vencer vuelve la energía sola, se cuenta y se avisa', async () => {
    const off = hub({ powerOutageUntil: NOW });
    const { service, repo, publisher, inbox } = outageService(null, [off]);
    await expect(service.restoreDue(NOW)).resolves.toBe(1);
    expect(repo.update).toHaveBeenCalledWith(
      { id: 'hub-1' },
      { powerOutageUntil: null },
    );
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'hub-outage', action: 'ended' }),
    );
    expect(inbox.notifyHubDispatchers).toHaveBeenCalledWith(
      'hub-1',
      expect.objectContaining({ kind: NotificationKind.HUB_POWER_RESTORED }),
    );
  });

  it('devolver la energía a una central que la tiene responde 404', async () => {
    await expect(outageService(hub()).service.end('hub-1')).rejects.toThrow(
      new NotFoundException(HUB_HAS_POWER),
    );
  });
});

describe('Reubicación al apagarse (CU-45)', () => {
  it('primero saca la central de las ofertas, luego vacía su cola y ofrece lo que soltó', async () => {
    const calls: string[] = [];
    let listener: ((id: string) => Promise<void>) | null = null;
    const outages = {
      onOutageStarted: (fn: (id: string) => Promise<void>) => {
        listener = fn;
      },
    };
    const decision = {
      evacuateHub: jest.fn(() => {
        calls.push('evacuate');
        return Promise.resolve(['order-2']);
      }),
    };
    const dispatch = {
      withdrawHub: jest.fn(() => {
        calls.push('withdraw');
        return Promise.resolve(1);
      }),
      start: jest.fn((id: string) => {
        calls.push(`start ${id}`);
        return Promise.resolve();
      }),
    };
    new HubOutageRelocationService(
      outages as never,
      decision as never,
      dispatch as never,
    ).onModuleInit();
    await listener!('hub-1');
    expect(calls).toEqual(['withdraw', 'evacuate', 'start order-2']);
  });
});

describe('El apagón en la línea de tiempo (RF-39)', () => {
  const outage = {
    hubId: 'hub-1',
    name: 'Clínica Valledupar',
    latitude: 10.456,
    longitude: -73.264,
  };

  it('al empezar dice cuánto dura y qué pasa con los pedidos', () => {
    expect(hubOutageDraft('started', outage, 30)).toMatchObject({
      severity: 'danger',
      hubId: 'hub-1',
      title: 'Clínica Valledupar sin energía por 30 min',
      source: 'console',
    });
  });

  it('al volver la energía avisa en verde', () => {
    expect(hubOutageDraft('ended', outage, null)).toMatchObject({
      severity: 'success',
      title: 'Volvió la energía a Clínica Valledupar',
    });
  });
});
