import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { SaleType } from '../../common/enums/sale-type.enum';
import { addCalendarDays, todayInColombia } from '../../orders/orders.rules';
import { CreateInventoryItemDto } from './create-inventory-item.dto';
import { UpdateInventoryItemDto } from './update-inventory-item.dto';

const tomorrow = addCalendarDays(todayInColombia(), 1);

const validCreate = {
  name: 'Acetaminofén 500 mg',
  quantity: 10,
  lot: 'LOT-2026-A',
  expirationDate: tomorrow,
  requiresColdChain: false,
  saleType: SaleType.OVER_THE_COUNTER,
};

async function messages(
  type: new () => object,
  payload: Record<string, unknown>,
) {
  const errors = await validate(plainToInstance(type, payload));
  return errors.flatMap((error) => Object.values(error.constraints ?? {}));
}

describe('CreateInventoryItemDto', () => {
  it('acepta un ítem con cantidad positiva y vencimiento futuro', async () => {
    expect(await messages(CreateInventoryItemDto, validCreate)).toEqual([]);
  });

  it('CP-08-03 rechaza cantidad 0', async () => {
    expect(
      await messages(CreateInventoryItemDto, { ...validCreate, quantity: 0 }),
    ).toContain('La cantidad debe ser mayor que cero.');
  });

  it('CP-08-04 rechaza un vencimiento pasado', async () => {
    expect(
      await messages(CreateInventoryItemDto, {
        ...validCreate,
        expirationDate: addCalendarDays(todayInColombia(), -1),
      }),
    ).toContain('La fecha de vencimiento debe ser posterior a hoy.');
  });

  it('rechaza un vencimiento que vence hoy', async () => {
    expect(
      await messages(CreateInventoryItemDto, {
        ...validCreate,
        expirationDate: todayInColombia(),
      }),
    ).toContain('La fecha de vencimiento debe ser posterior a hoy.');
  });
});

describe('UpdateInventoryItemDto', () => {
  it('permite dejar la cantidad en 0 para agotar el ítem', async () => {
    expect(await messages(UpdateInventoryItemDto, { quantity: 0 })).toEqual([]);
  });

  it('rechaza una cantidad negativa', async () => {
    expect(await messages(UpdateInventoryItemDto, { quantity: -1 })).toContain(
      'La cantidad no puede ser negativa.',
    );
  });

  it('rechaza un vencimiento pasado', async () => {
    expect(
      await messages(UpdateInventoryItemDto, {
        expirationDate: addCalendarDays(todayInColombia(), -1),
      }),
    ).toContain('La fecha de vencimiento debe ser posterior a hoy.');
  });

  it('no exige fecha cuando no se edita', async () => {
    expect(await messages(UpdateInventoryItemDto, { name: 'Otro' })).toEqual(
      [],
    );
  });
});
