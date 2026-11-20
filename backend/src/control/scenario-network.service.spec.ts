import { UserRole } from '../common/enums/user-role.enum';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { hubPlans, operator } from './demo-scenario';
import { ScenarioNetworkService } from './scenario-network.service';

const admin = { id: 'admin-1' } as User;
const valledupar = hubPlans[0];

/** Una base con todas las centrales del plan menos las que se piden, y unas viejas. */
function build(options: { missing?: string[]; stale?: string[] } = {}) {
  const present = hubPlans
    .filter((plan) => !(options.missing ?? []).includes(plan.name))
    .map((plan, index) => ({ id: `hub-${index}`, name: plan.name }));
  const stale = (options.stale ?? []).map((name, index) => ({
    id: `old-${index}`,
    name,
  }));
  const saved: Array<{ entity: unknown; row: Record<string, unknown> }> = [];
  const repo = (entity: unknown) => ({
    find: jest.fn(() =>
      Promise.resolve(
        entity === Hub
          ? present
          : entity === DroneModel
            ? [
                { id: 'm-rapid', kind: 'rapid' },
                { id: 'm-balanced', kind: 'balanced' },
                { id: 'm-cargo', kind: 'cargo' },
              ]
            : [],
      ),
    ),
    findOne: jest.fn(({ where }: { where: { email?: string } }) =>
      Promise.resolve(
        entity === User && where.email === operator.email
          ? { id: 'operator-1' }
          : null,
      ),
    ),
    create: jest.fn((row: Record<string, unknown>) => row),
    save: jest.fn((row: Record<string, unknown>) => {
      saved.push({ entity, row });
      return Promise.resolve({ id: `new-${saved.length}`, ...row });
    }),
  });
  const manager = {
    find: jest.fn((entity: unknown) =>
      Promise.resolve(entity === Hub ? stale : []),
    ),
    query: jest.fn().mockResolvedValue([]),
  };
  const dataSource = {
    getRepository: jest.fn(repo),
    transaction: jest.fn((work: (m: typeof manager) => Promise<unknown>) =>
      work(manager),
    ),
  };
  const users = { createInstitutional: jest.fn().mockResolvedValue({}) };
  const service = new ScenarioNetworkService(
    dataSource as never,
    users as never,
  );
  return { service, manager, users, saved };
}

describe('La red del escenario queda igual a la del plan (RF-40)', () => {
  it('con la base al día no borra ni crea nada', async () => {
    const { service, manager } = build();
    expect(await service.sync(admin)).toEqual({ removed: 0, created: 0 });
    expect(manager.query).not.toHaveBeenCalled();
  });

  it('borra las centrales viejas con sus pedidos, drones e inventario', async () => {
    const { service, manager } = build({
      stale: ['Clínica Laura Daniela', 'Hospital Rosario Pumarejo'],
    });
    expect((await service.sync(admin)).removed).toBe(2);
    const sql = manager.query.mock.calls.map(([text]) => text as string);
    for (const table of [
      'orders',
      'drones',
      'inventory_items',
      'user_hubs',
      'hubs',
    ]) {
      expect(sql.some((text) => text.includes(`DELETE FROM ${table}`))).toBe(
        true,
      );
    }
    // Lo último es la central: nada queda apuntando a ella.
    expect(sql.at(-1)).toContain('DELETE FROM hubs');
  });

  it('crea la Central Valledupar que falta, con despachadores, drones y el operador', async () => {
    const { service, users, saved } = build({ missing: [valledupar.name] });
    expect((await service.sync(admin)).created).toBe(1);
    const hub = saved.find((entry) => entry.entity === Hub)!.row;
    expect(hub).toMatchObject({
      name: valledupar.name,
      createdByUserId: 'admin-1',
    });
    expect(users.createInstitutional).toHaveBeenCalledTimes(
      valledupar.dispatchers.length,
    );
    expect(users.createInstitutional).toHaveBeenCalledWith(
      expect.objectContaining({ role: UserRole.DISPATCHER }),
    );
    const drones = saved.filter((entry) => entry.entity === Drone);
    expect(drones.map((entry) => entry.row.identifier)).toEqual(
      valledupar.fleet.map(
        (_, index) => `${valledupar.dronePrefix}-0${index + 1}`,
      ),
    );
    expect(saved.some((entry) => entry.entity === UserHubAssignment)).toBe(
      true,
    );
  });

  it('toda central tiene dos drones de cada tipo', async () => {
    const last = hubPlans[hubPlans.length - 1];
    const { service, saved } = build({ missing: [last.name] });
    await service.sync(admin);
    expect(saved.filter((entry) => entry.entity === Drone).length).toBe(6);
    for (const plan of hubPlans) {
      expect(plan.dispatchers).toHaveLength(2);
    }
    expect(saved.some((entry) => entry.entity === UserHubAssignment)).toBe(
      true,
    );
  });
});
