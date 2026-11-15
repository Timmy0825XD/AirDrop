import { ForbiddenException } from '@nestjs/common';
import { DroneKind } from '../common/enums/drone-kind.enum';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { Order } from '../orders/order.entity';
import { User } from '../users/user.entity';
import { CargoManifest } from './cargo-manifest.entity';
import { AUTO_DISPATCHER_NAME, MANIFEST_REPLACED } from './manifest.rules';
import { ManifestsService } from './manifests.service';

const order = {
  id: 'order-1',
  droneId: 'drone-1',
  originHubId: 'hub-north',
  destinationHubId: null,
  deliveryPointId: 'point-1',
  destinationKind: DestinationKind.PERSON,
  medicationName: 'Acetaminofén 500 mg',
  quantity: 1,
  dispatchedLot: 'L-01',
  dispatchedLotExpiresOn: '2027-01-01',
  payloadKg: 0.03,
  requiresColdChain: false,
  address: 'Puesto de salud de Badillo, Valledupar',
  patientFullName: 'No debe salir',
} as unknown as Order;

function manager(lastSequence: number | null) {
  const findOneOrFail = jest.fn((entity: { name: string }) =>
    Promise.resolve(
      entity.name === 'Drone'
        ? {
            id: 'drone-1',
            identifier: 'AD-NOR-01',
            coldCompartment: false,
            droneModel: { kind: DroneKind.BALANCED },
          }
        : { id: 'hub-north', name: 'Nodo Norte (Río Seco)' },
    ),
  );
  return {
    findOneOrFail,
    findOne: jest.fn().mockResolvedValue({ name: 'Puesto de salud de Badillo' }),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
    query: jest.fn((sql: string) =>
      Promise.resolve(sql.includes('MAX') ? [{ last: lastSequence }] : []),
    ),
    create: jest.fn((_entity: unknown, row: object) => row),
    save: jest.fn((row: object) => Promise.resolve(row)),
  };
}

function service(rows: Partial<CargoManifest>[] = []) {
  const repo = {
    find: jest.fn().mockResolvedValue(rows),
    findOne: jest.fn().mockResolvedValue(rows[0] ?? null),
    manager: { findOne: jest.fn().mockResolvedValue(order) },
  };
  return new ManifestsService(repo as never);
}

function user(role: UserRole, hubIds: string[] = []): User {
  return {
    id: 'u1',
    role,
    fullName: 'Despachadora Norte',
    hubAssignments: hubIds.map((hubId) => ({ hubId })),
  } as unknown as User;
}

describe('ManifestsService (RF-47)', () => {
  it('emite el siguiente consecutivo del año, anula el anterior y no lleva al paciente', async () => {
    const tx = manager(122);
    const issued = await service().issue(
      tx as never,
      order,
      user(UserRole.DISPATCHER),
    );
    expect(issued.number).toMatch(/^MAN-\d{4}-000123$/);
    expect(tx.update).toHaveBeenCalledWith(
      CargoManifest,
      expect.objectContaining({ orderId: 'order-1' }),
      expect.objectContaining({ voidReason: MANIFEST_REPLACED }),
    );
    expect(tx.query).toHaveBeenCalledWith(
      expect.stringContaining('pg_advisory_xact_lock'),
      expect.any(Array),
    );
    expect(issued).toMatchObject({
      droneIdentifier: 'AD-NOR-01',
      droneKind: DroneKind.BALANCED,
      originName: 'Nodo Norte (Río Seco)',
      destinationName: 'Puesto de salud de Badillo',
      authorizedByName: 'Despachadora Norte',
    });
    expect(JSON.stringify(issued)).not.toContain('No debe salir');
  });

  it('el primero del año es el 000001; el automático firma como tal', async () => {
    const issued = await service().issue(manager(null) as never, order, null);
    expect(issued.number).toMatch(/-000001$/);
    expect(issued.authorizedByName).toBe(AUTO_DISPATCHER_NAME);
    expect(issued.authorizedByUserId).toBeNull();
  });

  it('lo ven el despachador de origen, el operador de su nodo y el admin; el solicitante no', async () => {
    const rows = [{ number: 'MAN-2026-000002', issuedAt: new Date(), items: [] }];
    await expect(
      service(rows).forOrder(user(UserRole.DISPATCHER, ['hub-north']), 'order-1'),
    ).resolves.toMatchObject({ number: 'MAN-2026-000002', previous: [] });
    await expect(
      service(rows).forOrder(
        user(UserRole.FLEET_OPERATOR, ['hub-north']),
        'order-1',
      ),
    ).resolves.toBeDefined();
    await expect(
      service(rows).forOrder(user(UserRole.ADMIN), 'order-1'),
    ).resolves.toBeDefined();
    await expect(
      service(rows).forOrder(user(UserRole.DISPATCHER, ['otra']), 'order-1'),
    ).rejects.toThrow(ForbiddenException);
    await expect(
      service(rows).forOrder(user(UserRole.REQUESTER), 'order-1'),
    ).rejects.toThrow(ForbiddenException);
  });
});
