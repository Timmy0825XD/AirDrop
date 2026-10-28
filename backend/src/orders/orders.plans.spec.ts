import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { In } from 'typeorm';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DocumentType } from '../common/enums/document-type.enum';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { DeliveryPlan } from './delivery-plan.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  PLAN_RESCHEDULED_REASON,
  OrdersService,
  RULE_PLAN_NOT_EXTENDED,
} from './orders.service';
import { PRESCRIPTION_VALIDITY_REQUIRED } from './plan-schedule.rules';

// Lunes 2 de noviembre de 2026, 08:00 en Colombia.
const NOW = new Date('2026-11-02T13:00:00.000Z');
const PLAN_ID = '44444444-4444-4444-8444-444444444444';

const thursdays = {
  kind: ScheduleKind.WEEKLY,
  startDate: '2026-11-02',
  endDate: '2026-11-30',
  daysOfWeek: [4],
  time: '10:00',
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
    hubAssignments: [{ hubId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' }],
  } as unknown as User;
}

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
} as Hub;

function build(state: { plan?: DeliveryPlan; occurrences?: Order[] } = {}) {
  const saved: Order[] = [];
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) => {
      saved.push(value);
      return Promise.resolve({ ...value, id: `order-${saved.length}` });
    }),
    find: jest.fn().mockResolvedValue(state.occurrences ?? []),
    findOne: jest.fn().mockResolvedValue(null),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
    delete: jest.fn(),
  };
  const plans = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: DeliveryPlan) => {
      value.id = value.id ?? PLAN_ID;
      value.createdAt = value.createdAt ?? NOW;
      return Promise.resolve(value);
    }),
    findOne: jest.fn().mockResolvedValue(state.plan ?? null),
  };
  const images = {
    create: jest.fn((value: object) => value),
    save: jest.fn(),
    findOne: jest.fn().mockResolvedValue(null),
  };
  const storage = {
    upload: jest.fn((orderId: string) => Promise.resolve(`${orderId}.jpg`)),
    download: jest.fn(),
  };
  const offers = {
    offer: jest.fn().mockResolvedValue({
      name: 'Insulina NPH',
      saleType: SaleType.OVER_THE_COUNTER,
      requiresColdChain: true,
      availableQuantity: 50,
    }),
  } as unknown as InventoryOfferQuery;
  const hubsService = {
    requireActive: jest.fn((id: string) =>
      Promise.resolve(id === origin.id ? origin : destination),
    ),
  } as unknown as HubsService;
  const service = new OrdersService(
    orders as never,
    images as never,
    storage as never,
    {} as never,
    offers,
    hubsService,
    plans as never,
  );
  return { service, orders, plans, saved, storage };
}

function planDto(overrides: object = {}) {
  return {
    medicationName: 'Insulina NPH',
    saleType: SaleType.OVER_THE_COUNTER,
    quantity: 2,
    address: 'Calle 20 # 8-15',
    latitude: 10.46,
    longitude: -73.25,
    schedule: thursdays,
    ...overrides,
  };
}

function existingPlan(overrides: Partial<DeliveryPlan> = {}): DeliveryPlan {
  return {
    id: PLAN_ID,
    status: PlanStatus.ACTIVE,
    frequency: null,
    scheduleKind: ScheduleKind.WEEKLY,
    daysOfWeek: [4],
    everyWeeks: 1,
    dayOfMonth: null,
    scheduleDates: [],
    occurrenceCount: null,
    deliveryTime: '10:00',
    prescriptionValidUntil: null,
    medicationName: 'Insulina NPH',
    saleType: SaleType.OVER_THE_COUNTER,
    requiresColdChain: true,
    quantity: 2,
    startDate: '2026-11-02',
    windowEndsOn: '2026-12-01',
    requesterId: requester().id,
    createdByUserId: requester().id,
    destinationKind: DestinationKind.PERSON,
    destinationHubId: null,
    originHubId: null,
    address: 'Calle 20 # 8-15',
    latitude: 10.46,
    longitude: -73.25,
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  };
}

function occurrence(overrides: Partial<Order>): Order {
  return {
    id: 'o',
    planId: PLAN_ID,
    status: OrderStatus.RECEIVED,
    droneId: null,
    fallbackKind: null,
    scheduledFor: '2026-11-05',
    scheduledAt: new Date('2026-11-05T15:00:00.000Z'),
    ...overrides,
  } as Order;
}

describe('OrdersService planes con calendario (RU-30)', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: NOW, doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  it('crea una entrega por jueves con su franja de 1 hora y guarda la regla', async () => {
    const { service, saved, plans } = build();
    const plan = await service.createPlan(requester(), planDto());

    expect(saved.map((order) => order.scheduledFor)).toEqual([
      '2026-11-05',
      '2026-11-12',
      '2026-11-19',
      '2026-11-26',
    ]);
    expect(saved[0].scheduledAt?.toISOString()).toBe(
      '2026-11-05T15:00:00.000Z',
    );
    expect(saved[0].windowEndsAt?.toISOString()).toBe(
      '2026-11-05T16:00:00.000Z',
    );
    expect(saved.every((order) => order.status === OrderStatus.RECEIVED)).toBe(
      true,
    );
    const [stored] = plans.save.mock.calls[0];
    expect(stored).toMatchObject({
      frequency: null,
      scheduleKind: ScheduleKind.WEEKLY,
      daysOfWeek: [4],
      deliveryTime: '10:00',
      windowEndsOn: '2026-12-01',
    });
    expect(plan.schedule).toMatchObject({ kind: 'weekly', time: '10:00' });
    expect(plan.windowMinutes).toBe(60);
    expect(plan.renewalDue).toBe(false);
  });

  it('bajo fórmula pide la vigencia y no la deja pasar', async () => {
    const formula = {
      saleType: SaleType.PRESCRIPTION,
      patientDocumentType: DocumentType.CITIZENSHIP_ID,
      patientDocumentNumber: '1098765432',
      prescriptionMime: 'image/jpeg',
      prescriptionImageBase64: Buffer.from('formula').toString('base64'),
    };
    const { service, storage } = build();
    await expect(
      service.createPlan(requester(), planDto(formula)),
    ).rejects.toThrow(new BadRequestException(PRESCRIPTION_VALIDITY_REQUIRED));
    await expect(
      service.createPlan(
        requester(),
        planDto({ ...formula, prescriptionValidUntil: '2026-11-20' }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    const plan = await service.createPlan(
      requester(),
      planDto({ ...formula, prescriptionValidUntil: '2026-11-30' }),
    );
    expect(plan.prescriptionValidUntil).toBe('2026-11-30');
    // Cada entrega lleva su copia de la fórmula.
    expect(storage.upload).toHaveBeenCalledTimes(4);
  });

  it('sin calendario, sigue el plan anterior de 8 semanas en todo el día', async () => {
    const { service, saved } = build();
    const plan = await service.createPlan(
      requester(),
      planDto({
        schedule: undefined,
        frequency: PlanFrequency.WEEKLY,
        startDate: '2026-11-05',
      }),
    );
    expect(saved).toHaveLength(8);
    expect(saved[0].scheduledAt?.toISOString()).toBe(
      '2026-11-05T12:00:00.000Z',
    );
    expect(saved[0].windowEndsAt?.toISOString()).toBe(
      '2026-11-05T23:00:00.000Z',
    );
    expect(plan.frequency).toBe(PlanFrequency.WEEKLY);
    expect(plan.schedule).toMatchObject({
      kind: 'weekly',
      daysOfWeek: [4],
      time: null,
    });
  });

  it('un plan entre centrales usa el mismo calendario y no pide vigencia', async () => {
    const { service, saved } = build();
    await service.createHubPlan(dispatcher(), {
      originHubId: origin.id,
      medicationName: 'Insulina NPH',
      saleType: SaleType.PRESCRIPTION,
      quantity: 10,
      schedule: { ...thursdays, endDate: undefined, count: 2 },
    });
    expect(saved).toHaveLength(2);
    expect(saved[0].destinationHubId).toBe(destination.id);
  });

  it('la vista previa muestra las franjas sin guardar nada', () => {
    const { service, saved, plans } = build();
    const preview = service.previewPlan(requester(), {
      schedule: {
        kind: ScheduleKind.DATES,
        dates: ['2026-11-02', '2026-11-04'],
        time: '09:00',
      },
    });
    expect(preview.occurrences.map((item) => item.date)).toEqual([
      '2026-11-04',
    ]);
    expect(preview.tooSoon).toEqual(['2026-11-02']);
    expect(preview.windowMinutes).toBe(60);
    expect(saved).toHaveLength(0);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('cambiar el calendario rehace solo las entregas sin dron, y no repite fechas', async () => {
    const free = occurrence({ id: 'free', scheduledFor: '2026-11-12' });
    const loaded = occurrence({
      id: 'loaded',
      status: OrderStatus.PENDING_LOAD,
      droneId: 'drone',
      scheduledFor: '2026-11-05',
    });
    const retrying = occurrence({
      id: 'retrying',
      fallbackKind: FallbackKind.RETRY,
      scheduledFor: '2026-11-03',
    });
    const { service, orders, saved } = build({
      plan: existingPlan(),
      occurrences: [free, loaded, retrying],
    });
    // Ahora martes y jueves a las 15:00.
    await service.updatePlanSchedule(requester(), PLAN_ID, {
      schedule: { ...thursdays, daysOfWeek: [2, 4], time: '15:00' },
    });
    expect(orders.update).toHaveBeenCalledWith(
      { id: In(['free']) },
      {
        status: OrderStatus.CANCELLED,
        statusReason: PLAN_RESCHEDULED_REASON,
      },
    );
    const dates = saved.map((order) => order.scheduledFor);
    // El 3 (reintento) y el 5 (ya cargado) no se repiten.
    expect(dates).not.toContain('2026-11-03');
    expect(dates).not.toContain('2026-11-05');
    expect(dates).toContain('2026-11-12');
    expect(saved[0].scheduledAt?.toISOString()).toMatch(/T20:00:00/);
  });

  it('un plan con calendario no se extiende: se cambia su calendario', async () => {
    const { service } = build({ plan: existingPlan() });
    await expect(service.extendPlan(requester(), PLAN_ID)).rejects.toThrow(
      new BadRequestException(RULE_PLAN_NOT_EXTENDED),
    );
  });

  it('un plan cancelado no cambia de calendario', async () => {
    const { service } = build({
      plan: existingPlan({ status: PlanStatus.CANCELLED }),
    });
    await expect(
      service.updatePlanSchedule(requester(), PLAN_ID, { schedule: thursdays }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});

describe('CreatePlanDto con calendario', () => {
  async function messages(data: object) {
    const failures = await validate(plainToInstance(CreatePlanDto, data));
    return failures.flatMap((failure) => [
      ...Object.values(failure.constraints ?? {}),
      ...(failure.children ?? []).flatMap((child) =>
        Object.values(child.constraints ?? {}),
      ),
    ]);
  }

  it('con calendario no pide la frecuencia anterior', async () => {
    expect(await messages(planDto())).toEqual([]);
  });

  it('sin calendario la frecuencia sigue siendo obligatoria', async () => {
    expect(await messages(planDto({ schedule: undefined }))).toContain(
      'La frecuencia debe ser única, semanal, quincenal o mensual.',
    );
  });

  it('valida el calendario anidado', async () => {
    expect(
      await messages(
        planDto({
          schedule: { kind: 'diario', daysOfWeek: [8], time: '10' },
        }),
      ),
    ).toEqual(
      expect.arrayContaining([
        'El calendario debe ser semanal, mensual o de fechas sueltas.',
        'Los días de la semana van de 1 a 7.',
        'La hora debe ser HH:MM.',
      ]),
    );
  });
});
