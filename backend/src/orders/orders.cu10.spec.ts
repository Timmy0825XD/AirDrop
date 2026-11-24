/**
 * Pruebas unitarias del CU-10 (Crear pedido programado), casos CP-10-01 a
 * CP-10-15 de la Segunda Parte del documento. El nombre de cada `it` empieza
 * con el ID del caso para que la terminal lo muestre en la captura.
 *
 * El reloj se fija el lunes 2026-11-23 a las 07:00 de Colombia: así las
 * fechas de los datos de prueba no cambian de resultado según el día en que
 * se corran.
 */
import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate, ValidationError } from 'class-validator';
import { DocumentType } from '../common/enums/document-type.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { ScheduleKind } from '../common/enums/schedule-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { PlanScheduleDto } from './dto/plan-schedule.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import { SPECIAL_CONTROL_MESSAGE } from './orders.rules';
import { OrdersService } from './orders.service';
import {
  SCHEDULE_BAD_TIME,
  SCHEDULE_EMPTY,
  SCHEDULE_END_OR_COUNT,
  SCHEDULE_NEEDS_DAYS,
  SCHEDULE_PAST_PRESCRIPTION,
  SCHEDULE_START_IN_THE_PAST,
  SCHEDULE_TOO_LONG,
  buildSchedule,
} from './plan-schedule.rules';

/** Lunes 23 de noviembre de 2026, 07:00 en Colombia (UTC-5). */
const FIXED_NOW = new Date('2026-11-23T12:00:00.000Z');

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

/** Todos los jueves a las 10:00, 4 entregas, desde el 26 de noviembre. */
function semanal(overrides: Partial<PlanScheduleDto> = {}): PlanScheduleDto {
  return {
    kind: ScheduleKind.WEEKLY,
    daysOfWeek: [4],
    everyWeeks: 1,
    startDate: '2026-11-26',
    count: 4,
    time: '10:00',
    ...overrides,
  };
}

function planDto(overrides: Partial<CreatePlanDto> = {}): CreatePlanDto {
  return {
    medicationName: 'Losartán 50 mg',
    saleType: SaleType.OVER_THE_COUNTER,
    quantity: 30,
    schedule: semanal(),
    address: 'Casa esquinera de reja verde',
    latitude: 10.4631,
    longitude: -73.2532,
    ...overrides,
  };
}

function build(medicationName = 'Losartán 50 mg') {
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order | Order[]) => Promise.resolve(value)),
    find: jest.fn().mockResolvedValue([]),
  };
  const plans = {
    create: jest.fn((value: object) => value),
    save: jest.fn((value: { id?: string; createdAt?: Date }) => {
      value.id = '44444444-4444-4444-8444-444444444444';
      value.createdAt = FIXED_NOW;
      return Promise.resolve(value);
    }),
  };
  // Existencias simuladas: hay stock suficiente para llegar a las reglas del plan.
  const offers = {
    offer: jest.fn().mockResolvedValue({
      name: medicationName,
      saleType: SaleType.OVER_THE_COUNTER,
      requiresColdChain: false,
      availableQuantity: 120,
    }),
  } as unknown as InventoryOfferQuery;
  const service = new OrdersService(
    orders as never,
    {} as never,
    {} as never,
    {} as never,
    offers,
    {} as HubsService,
    plans as never,
    { assertDestinationAllowed: () => Promise.resolve() } as never,
    { statusChanged: jest.fn().mockResolvedValue(undefined) } as never,
  );
  return { service, orders, plans };
}

/** Las entregas que guardó el plan, una por fecha. */
function savedOccurrences(orders: { save: jest.Mock }): Order[] {
  return orders.save.mock.calls.flatMap(([row]) =>
    Array.isArray(row) ? (row as Order[]) : [row as Order],
  );
}

function dates(orders: { save: jest.Mock }): string[] {
  return savedOccurrences(orders).map((row) => row.scheduledFor as string);
}

function mensajes(fallo: ValidationError): string[] {
  return [
    ...Object.values(fallo.constraints ?? {}),
    ...(fallo.children ?? []).flatMap(mensajes),
  ];
}

async function errors(data: object): Promise<string[]> {
  const failures = await validate(plainToInstance(CreatePlanDto, data));
  return failures.flatMap(mensajes);
}

describe('CU-10 Crear pedido programado', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: FIXED_NOW });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  it('CP-10-01 crea un plan semanal de los jueves a las 10:00 con 4 entregas', async () => {
    expect(await errors(planDto())).toEqual([]);
    const { service, orders } = build();

    const plan = await service.createPlan(requester(), planDto());

    expect(plan.status).toBe(PlanStatus.ACTIVE);
    expect(dates(orders)).toEqual([
      '2026-11-26',
      '2026-12-03',
      '2026-12-10',
      '2026-12-17',
    ]);
    savedOccurrences(orders).forEach((row) =>
      expect(row.missionType).toBe(MissionType.SCHEDULED),
    );
  });

  it('CP-10-02 crea un plan mensual el día 15 con 3 entregas', async () => {
    const body = planDto({
      schedule: {
        kind: ScheduleKind.MONTHLY,
        dayOfMonth: 15,
        startDate: '2026-11-23',
        count: 3,
        time: '09:00',
      },
    });
    expect(await errors(body)).toEqual([]);
    const { service, orders } = build();

    await service.createPlan(requester(), body);

    expect(dates(orders)).toEqual(['2026-12-15', '2027-01-15', '2027-02-15']);
  });

  it('CP-10-03 crea un plan de fechas sueltas con una entrega por fecha', async () => {
    const body = planDto({
      schedule: {
        kind: ScheduleKind.DATES,
        dates: ['2026-12-04', '2026-11-27'],
        time: '16:00',
      },
    });
    expect(await errors(body)).toEqual([]);
    const { service, orders } = build();

    await service.createPlan(requester(), body);

    expect(dates(orders)).toEqual(['2026-11-27', '2026-12-04']);
  });

  it('CP-10-04 rechaza un plan de control especial (400)', async () => {
    const { service, orders, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({ saleType: SaleType.SPECIAL_CONTROL }),
    );

    await expect(attempt).rejects.toThrow(
      new BadRequestException(SPECIAL_CONTROL_MESSAGE),
    );
    expect(plans.save).not.toHaveBeenCalled();
    expect(orders.save).not.toHaveBeenCalled();
  });

  it('CP-10-05 rechaza un plan que empieza antes de hoy (400)', async () => {
    const { service, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({ schedule: semanal({ startDate: '2026-11-22' }) }),
    );

    await expect(attempt).rejects.toThrow(SCHEDULE_START_IN_THE_PAST);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('CP-10-06 rechaza un plan con cantidad 0 (400)', async () => {
    expect(await errors(planDto({ quantity: 0 }))).toContain(
      'La cantidad debe ser al menos 1.',
    );
  });

  it('CP-10-07 rechaza un plan con cantidad 100001 (400)', async () => {
    expect(await errors(planDto({ quantity: 100001 }))).toContain(
      'La cantidad es demasiado alta.',
    );
  });

  it('CP-10-08 rechaza la franja de las 17:00 y acepta la de las 16:00 (400)', async () => {
    const tarde = build();
    await expect(
      tarde.service.createPlan(
        requester(),
        planDto({ schedule: semanal({ time: '17:00' }) }),
      ),
    ).rejects.toThrow(SCHEDULE_BAD_TIME);

    const ultima = build();
    await ultima.service.createPlan(
      requester(),
      planDto({ schedule: semanal({ time: '16:00' }) }),
    );
    expect(dates(ultima.orders)).toHaveLength(4);
  });

  it('CP-10-09 rechaza un plan con fecha de fin y número de entregas a la vez (400)', async () => {
    const { service, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({ schedule: semanal({ endDate: '2026-12-31', count: 4 }) }),
    );

    await expect(attempt).rejects.toThrow(SCHEDULE_END_OR_COUNT);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('CP-10-10 rechaza un plan de más de 3 meses y acepta uno de 3 meses exactos (400)', async () => {
    const largo = build();
    await expect(
      largo.service.createPlan(
        requester(),
        planDto({
          schedule: semanal({ count: undefined, endDate: '2027-02-27' }),
        }),
      ),
    ).rejects.toThrow(SCHEDULE_TOO_LONG);

    const justo = build();
    await justo.service.createPlan(
      requester(),
      planDto({
        schedule: semanal({ count: undefined, endDate: '2027-02-26' }),
      }),
    );
    expect(dates(justo.orders).at(-1)).toBe('2027-02-25');
  });

  it('CP-10-11 rechaza el medicamento vacío con «El medicamento es obligatorio.»', async () => {
    expect(await errors(planDto({ medicationName: '' }))).toContain(
      'El medicamento es obligatorio.',
    );
  });

  it('CP-10-12 rechaza un plan semanal sin días de la semana (400)', async () => {
    const { service, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({ schedule: semanal({ daysOfWeek: [] }) }),
    );

    await expect(attempt).rejects.toThrow(SCHEDULE_NEEDS_DAYS);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('CP-10-13 no agenda una entrega que empezaría en menos de 2 horas (400)', async () => {
    // Hoy a las 08:00: falta 1 hora y no da tiempo de avisar ni de preparar.
    const { service, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({
        schedule: {
          kind: ScheduleKind.DATES,
          dates: ['2026-11-23'],
          time: '08:00',
        },
      }),
    );

    await expect(attempt).rejects.toThrow(SCHEDULE_EMPTY);
    expect(plans.save).not.toHaveBeenCalled();
  });

  it('CP-10-14 no deja que el plan dure más que la vigencia de la fórmula (400)', () => {
    const schedule = semanal();

    expect(() =>
      buildSchedule(schedule, {
        now: FIXED_NOW,
        prescriptionValidUntil: '2026-12-10',
      }),
    ).toThrow(SCHEDULE_PAST_PRESCRIPTION);
    expect(
      buildSchedule(schedule, {
        now: FIXED_NOW,
        prescriptionValidUntil: '2026-12-17',
      }).lastDate,
    ).toBe('2026-12-17');
  });

  it('CP-10-15 crea un plan de martes y jueves cada 2 semanas', () => {
    const result = buildSchedule(
      semanal({ daysOfWeek: [2, 4], everyWeeks: 2, startDate: '2026-11-24' }),
      { now: FIXED_NOW },
    );

    expect(result.occurrences.map((o) => o.date)).toEqual([
      '2026-11-24',
      '2026-11-26',
      '2026-12-08',
      '2026-12-10',
    ]);
  });
});
