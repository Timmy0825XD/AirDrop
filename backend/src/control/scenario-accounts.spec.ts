import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { User } from '../users/user.entity';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { hubPlans, operator, requesters } from './demo-scenario';
import { isScenarioAccount, scenarioAccounts } from './scenario-accounts.rules';
import { ScenarioAccountsService } from './scenario-accounts.service';

const admin = { id: 'admin-1' } as User;

describe('Cuentas del escenario (RF-40)', () => {
  it('son 24 despachadores, el operador y 10 solicitantes', () => {
    const accounts = scenarioAccounts();
    const count = (role: UserRole) =>
      accounts.filter((account) => account.role === role).length;
    expect(count(UserRole.DISPATCHER)).toBe(24);
    expect(count(UserRole.FLEET_OPERATOR)).toBe(1);
    expect(count(UserRole.REQUESTER)).toBe(10);
    expect(new Set(accounts.map((a) => a.email)).size).toBe(accounts.length);
  });

  it('el despachador queda en su central, el operador en todas y el solicitante en ninguna', () => {
    const accounts = scenarioAccounts();
    const first = hubPlans[0];
    expect(
      accounts.find((a) => a.email === first.dispatchers[0].email)?.hubNames,
    ).toEqual([first.name]);
    expect(
      accounts.find((a) => a.email === operator.email)?.hubNames,
    ).toHaveLength(hubPlans.length);
    expect(
      accounts.find((a) => a.email === requesters[0].email)?.hubNames,
    ).toEqual([]);
  });

  it('se salvan las cuentas del escenario y los administradores; las demás no', () => {
    const emails = new Set(['natalia.araujo@airdrop.com']);
    expect(
      isScenarioAccount(
        { email: 'natalia.araujo@airdrop.com', role: UserRole.DISPATCHER },
        emails,
      ),
    ).toBe(true);
    expect(
      isScenarioAccount(
        { email: 'admin@airdrop.com', role: UserRole.ADMIN },
        emails,
      ),
    ).toBe(true);
    expect(
      isScenarioAccount(
        { email: 'nueva@gmail.com', role: UserRole.REQUESTER },
        emails,
      ),
    ).toBe(false);
    expect(
      isScenarioAccount({ email: null, role: UserRole.REQUESTER }, emails),
    ).toBe(false);
  });
});

describe('ScenarioAccountsService.restore (RF-40, CU-41)', () => {
  function build(users: Array<Partial<User>>) {
    const queries: Array<[string, unknown[]]> = [];
    const manager = {
      find: jest.fn((entity: unknown) =>
        Promise.resolve(
          entity === User
            ? users
            : entity === Hub
              ? hubPlans.map((plan, index) => ({
                  id: `hub-${index}`,
                  name: plan.name,
                }))
              : [],
        ),
      ),
      findOne: jest.fn(
        (_entity: unknown, { where }: { where: { email: string } }) =>
          Promise.resolve(
            users.find((user) => user.email === where.email) ?? null,
          ),
      ),
      query: jest.fn((sql: string, params: unknown[]) => {
        queries.push([sql, params]);
        return Promise.resolve([]);
      }),
      update: jest.fn().mockResolvedValue(undefined),
      delete: jest.fn().mockResolvedValue(undefined),
      create: jest.fn((_entity: unknown, row: object) => row),
      save: jest.fn((_entity: unknown, row: object) =>
        Promise.resolve({ id: 'new', ...row }),
      ),
    };
    return { manager, queries, service: new ScenarioAccountsService() };
  }

  it('borra la cuenta que no es del escenario y deja al admin', async () => {
    const { manager, queries, service } = build([
      { id: 'admin-1', email: 'admin@airdrop.com', role: UserRole.ADMIN },
      { id: 'x', email: 'nueva@gmail.com', role: UserRole.REQUESTER },
    ]);
    await service.restore(manager as never, admin);
    const deleted = queries.find(([sql]) =>
      sql.startsWith('DELETE FROM users'),
    );
    expect(deleted?.[1]).toEqual([['x']]);
    // La central que creó pasa al admin.
    expect(manager.update).toHaveBeenCalledWith(Hub, expect.anything(), {
      createdByUserId: 'admin-1',
    });
  });

  it('devuelve una cuenta cambiada a sus datos, activa y con Password123', async () => {
    const dispatcher = hubPlans[0].dispatchers[0];
    const { manager, service } = build([
      {
        id: 'd1',
        email: dispatcher.email,
        role: UserRole.DISPATCHER,
        fullName: 'Otro nombre',
      },
    ]);
    await service.restore(manager as never, admin);
    expect(manager.update).toHaveBeenCalledWith(
      User,
      { id: 'd1' },
      expect.objectContaining({
        fullName: dispatcher.fullName,
        status: UserStatus.ACTIVE,
        failedLoginCount: 0,
        passwordHash: expect.stringMatching(/^\$2[aby]\$/),
      }),
    );
    // Solo su central.
    expect(manager.delete).toHaveBeenCalledWith(UserHubAssignment, {
      userId: 'd1',
    });
    expect(manager.save).toHaveBeenCalledWith(UserHubAssignment, [
      { userId: 'd1', hubId: 'hub-0' },
    ]);
  });

  it('crea las cuentas del escenario que faltan', async () => {
    const { manager, service } = build([]);
    const count = await service.restore(manager as never, admin);
    expect(count).toBe(35);
    const created = (
      manager.save.mock.calls as Array<[unknown, object]>
    ).filter(([entity]) => entity === User);
    expect(created).toHaveLength(35);
  });
});
