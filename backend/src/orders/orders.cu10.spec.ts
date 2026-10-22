/**
 * Pruebas unitarias del CU-10 (Crear pedido programado), casos CP-10-01 a
 * CP-10-11 de la Segunda Parte del documento. El nombre de cada `it` empieza
 * con el ID del caso para que la terminal lo muestre en la captura.
 *
 * El reloj se fija en 2026-10-16 (fecha de referencia de los datos del
 * documento): así CP-10-02 (inicio 2026-10-16) sigue siendo "hoy" y los casos
 * no cambian de resultado según el día en que se corran.
 */
import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DocumentType } from '../common/enums/document-type.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreatePlanDto } from './dto/create-plan.dto';
import { InventoryOfferQuery } from './inventory-offer.query';
import { Order } from './order.entity';
import {
  SPECIAL_CONTROL_MESSAGE,
  START_DATE_IN_THE_PAST,
  addCalendarDays,
  occurrenceDates,
  windowEnd,
} from './orders.rules';
import { OrdersService } from './orders.service';

const FIXED_NOW = new Date('2026-10-16T15:00:00.000Z');

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

function planDto(overrides: Partial<CreatePlanDto> = {}): CreatePlanDto {
  return {
    medicationName: 'Insulina glargina',
    saleType: SaleType.OVER_THE_COUNTER,
    quantity: 4,
    frequency: PlanFrequency.WEEKLY,
    startDate: '2026-10-22',
    address: 'Calle 16 No. 19-35, Valledupar',
    ...overrides,
  };
}

function build(medicationName = 'Insulina glargina') {
  const orders = {
    create: jest.fn((value: Partial<Order>) => value),
    save: jest.fn((value: Order) => Promise.resolve(value)),
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
  );
  return { service, orders, plans };
}

function savedOccurrences(orders: { save: jest.Mock }): Order[] {
  return orders.save.mock.calls.map(([row]) => row as Order);
}

async function errors(data: object): Promise<string[]> {
  const failures = await validate(plainToInstance(CreatePlanDto, data));
  return failures.flatMap((failure) =>
    Object.values(failure.constraints ?? {}),
  );
}

describe('CU-10 Crear pedido programado', () => {
  beforeAll(() => {
    jest.useFakeTimers({ now: FIXED_NOW });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  it('CP-10-01 crea un plan semanal de venta libre con 8 entregas en recibido', async () => {
    expect(await errors(planDto())).toEqual([]);
    const { service, orders } = build();

    const plan = await service.createPlan(requester(), planDto());

    expect(plan.status).toBe(PlanStatus.ACTIVE);
    expect(plan.frequency).toBe(PlanFrequency.WEEKLY);
    const rows = savedOccurrences(orders);
    expect(rows).toHaveLength(8);
    rows.forEach((row, index) => {
      expect(row.status).toBe(OrderStatus.RECEIVED);
      expect(row.missionType).toBe(MissionType.SCHEDULED);
      expect(row.scheduledFor).toBe(addCalendarDays('2026-10-22', 7 * index));
    });
  });

  it('CP-10-02 crea un plan de frecuencia única con una sola entrega en la fecha de inicio', async () => {
    const body = planDto({
      frequency: PlanFrequency.ONCE,
      startDate: '2026-10-16',
    });
    expect(await errors(body)).toEqual([]);
    const { service, orders } = build();

    const plan = await service.createPlan(requester(), body);

    const rows = savedOccurrences(orders);
    expect(rows).toHaveLength(1);
    expect(rows[0].scheduledFor).toBe('2026-10-16');
    expect(rows[0].status).toBe(OrderStatus.RECEIVED);
    // La frecuencia única no se extiende: nunca entra en renovación.
    expect(plan.renewalDue).toBe(false);
  });

  it('CP-10-03 crea un plan quincenal y uno mensual dentro de las 8 semanas', async () => {
    const quincenal = build('Hierro polimaltosado');
    await quincenal.service.createPlan(
      requester(),
      planDto({
        medicationName: 'Hierro polimaltosado',
        quantity: 30,
        frequency: PlanFrequency.BIWEEKLY,
      }),
    );
    expect(
      savedOccurrences(quincenal.orders).map((r) => r.scheduledFor),
    ).toEqual(['2026-10-22', '2026-11-05', '2026-11-19', '2026-12-03']);

    const mensual = build('Hierro polimaltosado');
    await mensual.service.createPlan(
      requester(),
      planDto({
        medicationName: 'Hierro polimaltosado',
        quantity: 30,
        frequency: PlanFrequency.MONTHLY,
      }),
    );
    expect(savedOccurrences(mensual.orders).map((r) => r.scheduledFor)).toEqual(
      ['2026-10-22', '2026-11-22'],
    );
    // Todas las fechas caen antes del cierre de la ventana de 8 semanas.
    const end = windowEnd('2026-10-22');
    [...savedOccurrences(quincenal.orders), ...savedOccurrences(mensual.orders)]
      .map((row) => row.scheduledFor as string)
      .forEach((date) => expect(date < end).toBe(true));
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
    await expect(attempt).rejects.toThrow(
      'El control especial no se pide por este canal.',
    );
    expect(plans.save).not.toHaveBeenCalled();
    expect(orders.save).not.toHaveBeenCalled();
  });

  it('CP-10-05 rechaza un plan con la fecha de inicio anterior a hoy (400)', async () => {
    const { service, orders, plans } = build();

    const attempt = service.createPlan(
      requester(),
      planDto({ startDate: '2026-10-01' }),
    );

    await expect(attempt).rejects.toThrow(
      new BadRequestException(START_DATE_IN_THE_PAST),
    );
    await expect(attempt).rejects.toThrow(
      'La fecha de inicio no puede ser anterior a hoy.',
    );
    expect(plans.save).not.toHaveBeenCalled();
    expect(orders.save).not.toHaveBeenCalled();
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

  it('CP-10-08 rechaza una frecuencia fuera de la lista (400)', async () => {
    const found = await errors({ ...planDto(), frequency: 'diaria' });

    expect(found).toContain(
      'La frecuencia debe ser única, semanal, quincenal o mensual.',
    );
  });

  it('CP-10-09 corta el plan semanal en 24 fechas con una ventana muy larga', () => {
    const dates = occurrenceDates(
      '2026-10-22',
      '2030-01-01',
      PlanFrequency.WEEKLY,
    );

    expect(dates).toHaveLength(24);
    expect(dates[0]).toBe('2026-10-22');
    expect(dates[23]).toBe(addCalendarDays('2026-10-22', 7 * 23));
    expect(dates[23]).toBe('2027-04-01');
  });

  it('CP-10-10 devuelve una lista vacía si la ventana termina el mismo día de inicio', () => {
    expect(
      occurrenceDates('2026-10-22', '2026-10-22', PlanFrequency.WEEKLY),
    ).toEqual([]);
  });

  // Defecto (c) de la sección 8.1 de la guía: se deja a propósito para que
  // salga Fallido. Esperado: el medicamento vacío se rechaza en el formulario.
  it('CP-10-11 rechaza el medicamento vacío con «El medicamento es obligatorio.»', async () => {
    expect(await errors(planDto({ medicationName: '' }))).toContain(
      'El medicamento es obligatorio.',
    );
  });
});
