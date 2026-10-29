/**
 * Pruebas unitarias del CU-08 (Gestionar inventario), casos CP-08-01 a
 * CP-08-11 de la Segunda Parte. El nombre de cada `it` empieza con el ID del
 * caso para que la terminal lo muestre en la captura.
 */
import { ConflictException, ForbiddenException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { SaleType } from '../common/enums/sale-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { HubsService } from '../hubs/hubs.service';
import { User } from '../users/user.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { InventoryItem } from './inventory-item.entity';
import { InventoryService } from './inventory.service';

const central = { id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' } as Hub;

const valido: CreateInventoryItemDto = {
  name: 'Acetaminofén 500 mg',
  quantity: 120,
  lot: 'LOT-2026-A',
  expirationDate: '2027-06-30',
  requiresColdChain: false,
  saleType: SaleType.OVER_THE_COUNTER,
};

function usuario(overrides: Partial<User> = {}): User {
  return {
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    role: UserRole.DISPATCHER,
    status: UserStatus.ACTIVE,
    hubAssignments: [{ hubId: central.id }],
    ...overrides,
  } as User;
}

function build(opts: { item?: InventoryItem; committed?: boolean } = {}) {
  const items = {
    create: jest.fn((value: Partial<InventoryItem>) => value),
    save: jest.fn((value: InventoryItem) =>
      Promise.resolve({ ...value, id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee' }),
    ),
    findOne: jest.fn().mockResolvedValue(opts.item ?? null),
    remove: jest.fn().mockResolvedValue(undefined),
  };
  const orders = {
    exists: jest.fn().mockResolvedValue(opts.committed ?? false),
  };
  const hubsService = {
    requireActive: jest.fn((id: string) => Promise.resolve({ id } as Hub)),
  } as unknown as HubsService;
  const service = new InventoryService(
    items as never,
    orders as never,
    hubsService,
  );
  return { service, items, orders };
}

async function errores(data: object): Promise<string[]> {
  const fallos = await validate(plainToInstance(CreateInventoryItemDto, data));
  return fallos.flatMap((fallo) => Object.values(fallo.constraints ?? {}));
}

describe('CU-08 Gestionar inventario', () => {
  it('CP-08-01 agrega un ítem de venta libre sin cadena de frío', async () => {
    expect(await errores(valido)).toEqual([]);
    const { service, items } = build();

    const item = await service.create(usuario(), valido);

    expect(items.save).toHaveBeenCalledTimes(1);
    expect(item.hubId).toBe(central.id);
    expect(item.name).toBe('Acetaminofén 500 mg');
    expect(item.quantity).toBe(120);
    expect(item.lot).toBe('LOT-2026-A');
    expect(item.expirationDate).toBe('2027-06-30');
    expect(item.requiresColdChain).toBe(false);
    expect(item.saleType).toBe('over_the_counter');
  });

  it('CP-08-02 agrega un ítem con cadena de frío y venta bajo fórmula', async () => {
    const insulina = {
      name: 'Insulina glargina 100 UI',
      quantity: 40,
      lot: 'INS-0925',
      expirationDate: '2027-03-15',
      requiresColdChain: true,
      saleType: SaleType.PRESCRIPTION,
    };
    expect(await errores(insulina)).toEqual([]);
    const { service } = build();

    const item = await service.create(usuario(), insulina);

    expect(item.requiresColdChain).toBe(true);
    expect(item.saleType).toBe('prescription');
  });

  it('CP-08-03 rechaza la cantidad 0 (400)', async () => {
    expect(await errores({ ...valido, quantity: 0 })).toContain(
      'La cantidad debe ser mayor que cero.',
    );
  });

  it('CP-08-04 rechaza un vencimiento que ya pasó (400)', async () => {
    expect(
      await errores({ ...valido, expirationDate: '2025-12-31' }),
    ).toContain('La fecha de vencimiento debe ser posterior a hoy.');
  });

  it('CP-08-05 rechaza un lote con símbolos no permitidos (400)', async () => {
    expect(await errores({ ...valido, lot: 'LOT#2026' })).toContain(
      'El lote debe tener entre 3 y 20 letras, números o guiones.',
    );
  });

  it('CP-08-06 rechaza un tipo de venta fuera de la lista (400)', async () => {
    expect(await errores({ ...valido, saleType: 'restringido' })).toContain(
      'El tipo de venta debe ser libre, bajo fórmula o control especial.',
    );
  });

  it('CP-08-07 rechaza la creación por un usuario que no es despachador (403)', async () => {
    const { service, items } = build();

    const intento = service.create(
      usuario({ role: UserRole.REQUESTER, hubAssignments: [] }),
      valido,
    );

    await expect(intento).rejects.toBeInstanceOf(ForbiddenException);
    await expect(intento).rejects.toThrow(
      'Solo el despachador gestiona el inventario de su central.',
    );
    expect(items.save).not.toHaveBeenCalled();
  });

  it('CP-08-08 rechaza la creación por un despachador con la cuenta no activa (403)', async () => {
    const { service, items } = build();

    const intento = service.create(
      usuario({ status: UserStatus.SUSPENDED }),
      valido,
    );

    await expect(intento).rejects.toBeInstanceOf(ForbiddenException);
    await expect(intento).rejects.toThrow(
      'Tu cuenta debe estar activa para gestionar inventario.',
    );
    expect(items.save).not.toHaveBeenCalled();
  });

  it('CP-08-09 no da de baja un ítem comprometido en una misión (409)', async () => {
    const insulina = {
      id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      hubId: central.id,
      name: 'Insulina glargina 100 UI',
      lot: 'INS-0925',
      quantity: 40,
    } as InventoryItem;
    const { service, items, orders } = build({
      item: insulina,
      committed: true,
    });

    const intento = service.remove(usuario(), insulina.id);

    await expect(intento).rejects.toBeInstanceOf(ConflictException);
    await expect(intento).rejects.toThrow(
      'El ítem está comprometido en una misión.',
    );
    // Se buscó un pedido en curso (pendiente de carga, en vuelo...) con el lote.
    expect(orders.exists).toHaveBeenCalledWith({
      where: expect.objectContaining({
        inventoryItemId: insulina.id,
      }) as object,
    });
    expect(items.remove).not.toHaveBeenCalled();
    expect(insulina.quantity).toBe(40);
  });

  it('CP-08-10 rechaza al despachador activo sin una central asignada (403)', async () => {
    const { service, items } = build();

    for (const hubAssignments of [
      [],
      [
        { hubId: central.id },
        { hubId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' },
      ],
    ]) {
      const intento = service.create(
        usuario({ hubAssignments } as Partial<User>),
        valido,
      );
      await expect(intento).rejects.toBeInstanceOf(ForbiddenException);
      await expect(intento).rejects.toThrow(
        'Debes tener una central asignada para gestionar inventario.',
      );
    }
    expect(items.save).not.toHaveBeenCalled();
  });

  it('CP-08-11 rechaza el nombre vacío (nombre de 0 caracteres)', async () => {
    expect(await errores({ ...valido, name: '' })).toContain(
      'El nombre es obligatorio.',
    );
  });
});
