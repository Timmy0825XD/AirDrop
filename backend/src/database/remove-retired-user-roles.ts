import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

const RETIRED_ROLE = 'recipient';

type PostgresOptions = TypeOrmModuleOptions & {
  type: 'postgres';
  url?: string;
  ssl?: boolean | object;
};

function hasRegclass(rows: Array<{ name: string | null }>): boolean {
  return Boolean(rows[0]?.name);
}

export async function removeRetiredUserRoles(
  options: TypeOrmModuleOptions,
): Promise<void> {
  if (options.type !== 'postgres' || !('url' in options) || !options.url) {
    return;
  }
  const postgres = options as PostgresOptions;
  const boot = new DataSource({
    type: 'postgres',
    url: postgres.url,
    ssl: postgres.ssl ?? false,
    synchronize: false,
    logging: false,
  });

  try {
    await boot.initialize();
  } catch {
    return;
  }

  try {
    const usersTable = (await boot.query(
      `SELECT to_regclass('public.users') AS name`,
    )) as Array<{ name: string | null }>;
    if (!hasRegclass(usersTable)) {
      return;
    }

    const codesTable = (await boot.query(
      `SELECT to_regclass('public.one_time_codes') AS name`,
    )) as Array<{ name: string | null }>;
    if (hasRegclass(codesTable)) {
      await boot.query(
        `DELETE FROM one_time_codes WHERE "userId" IN (SELECT id FROM users WHERE role::text = $1)`,
        [RETIRED_ROLE],
      );
    }
    await boot.query(`DELETE FROM users WHERE role::text = $1`, [RETIRED_ROLE]);

    const labels = (await boot.query(
      `SELECT e.enumlabel
       FROM pg_enum e
       JOIN pg_type t ON e.enumtypid = t.oid
       WHERE t.typname = 'user_role'`,
    )) as Array<{ enumlabel: string }>;
    if (!labels.some((row) => row.enumlabel === RETIRED_ROLE)) {
      return;
    }

    await boot.transaction(async (manager) => {
      await manager.query(`ALTER TYPE user_role RENAME TO user_role_old`);
      await manager.query(
        `CREATE TYPE user_role AS ENUM ('requester', 'dispatcher', 'fleet_operator', 'admin')`,
      );
      await manager.query(
        `ALTER TABLE users ALTER COLUMN role TYPE user_role USING role::text::user_role`,
      );
      await manager.query(`DROP TYPE user_role_old`);
    });
  } finally {
    if (boot.isInitialized) {
      await boot.destroy();
    }
  }
}
