import { Injectable } from '@nestjs/common';
import { EntityManager, In } from 'typeorm';
import { hashPassword } from '../auth/auth.rules';
import { UserStatus } from '../common/enums/user-status.enum';
import { Hub } from '../hubs/hub.entity';
import { POLICY_VERSION } from '../privacy/privacy-policy';
import { User } from '../users/user.entity';
import { UserHubAssignment } from '../users/user-hub-assignment.entity';
import { DEMO_PASSWORD } from './scenario-network.service';
import { isScenarioAccount, scenarioAccounts } from './scenario-accounts.rules';

/**
 * RF-40: deja las cuentas exactamente como las crea `pnpm seed:demo`. Borra
 * toda cuenta que no sea del escenario (salvo los administradores), crea las
 * que faltan y devuelve las demás a sus datos, su contraseña y sus centrales.
 * Corre dentro de la transacción del reinicio, después de borrar los pedidos.
 */
@Injectable()
export class ScenarioAccountsService {
  async restore(manager: EntityManager, admin: User): Promise<number> {
    const accounts = scenarioAccounts();
    const emails = new Set(accounts.map((account) => account.email));
    await this.removeOthers(manager, emails, admin);

    const hubs = await manager.find(Hub);
    const hubIdByName = new Map(hubs.map((hub) => [hub.name, hub.id]));
    // Un solo hash para todas: el reinicio no tarda 36 veces bcrypt.
    const passwordHash = await hashPassword(DEMO_PASSWORD);
    const now = new Date();

    for (const account of accounts) {
      const existing = await manager.findOne(User, {
        where: { email: account.email },
      });
      const fields = {
        fullName: account.fullName,
        email: account.email,
        phone: account.phone,
        role: account.role,
        documentType: account.documentType,
        documentNumber: account.documentNumber,
        passwordHash,
        status: UserStatus.ACTIVE,
        failedLoginCount: 0,
        lockedUntil: null,
        pendingEmail: null,
        simulated: false,
        allergies: null,
        consentPolicyVersion: POLICY_VERSION,
        consentRevokedAt: null,
        suppressedAt: null,
      };
      const user = existing
        ? (await manager.update(User, { id: existing.id }, fields), existing)
        : await manager.save(
            User,
            manager.create(User, { ...fields, consentAcceptedAt: now }),
          );
      await manager.delete(UserHubAssignment, { userId: user.id });
      const hubIds = account.hubNames.flatMap(
        (name) => hubIdByName.get(name) ?? [],
      );
      if (hubIds.length) {
        await manager.save(
          UserHubAssignment,
          hubIds.map((hubId) =>
            manager.create(UserHubAssignment, { userId: user.id, hubId }),
          ),
        );
      }
    }
    return accounts.length;
  }

  /** Las cuentas que no son del escenario, con lo que solo era de ellas. */
  private async removeOthers(
    manager: EntityManager,
    emails: ReadonlySet<string>,
    admin: User,
  ): Promise<void> {
    const users = await manager.find(User, {
      select: { id: true, email: true, role: true },
    });
    const ids = users
      .filter((user) => !isScenarioAccount(user, emails))
      .map((user) => user.id);
    if (!ids.length) {
      return;
    }
    // La central sigue: quien la creó pasa a ser el administrador.
    await manager.update(
      Hub,
      { createdByUserId: In(ids) },
      { createdByUserId: admin.id },
    );
    for (const table of [
      'notifications',
      'one_time_codes',
      'prescription_access_logs',
      'user_hubs',
    ]) {
      await manager.query(
        `DELETE FROM ${table} WHERE "userId" = ANY($1::uuid[])`,
        [ids],
      );
    }
    await manager.query(`DELETE FROM users WHERE id = ANY($1::uuid[])`, [ids]);
  }
}
