import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

type PostgresOptions = TypeOrmModuleOptions & {
  type: 'postgres';
  url?: string;
  ssl?: boolean | object;
};

async function tableExists(
  boot: DataSource,
  name: string,
): Promise<boolean> {
  const rows = (await boot.query(`SELECT to_regclass($1) AS name`, [
    `public.${name}`,
  ])) as Array<{ name: string | null }>;
  return Boolean(rows[0]?.name);
}

async function migrateHubStatus(boot: DataSource): Promise<void> {
  const labels = (await boot.query(
    `SELECT e.enumlabel
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
     WHERE t.typname = 'hub_status'`,
  )) as Array<{ enumlabel: string }>;
  if (!labels.some((row) => row.enumlabel === 'pending_approval')) {
    return;
  }
  await boot.transaction(async (manager) => {
    await manager.query(`ALTER TABLE hubs ALTER COLUMN status DROP DEFAULT`);
    await manager.query(`ALTER TYPE hub_status RENAME TO hub_status_old`);
    await manager.query(
      `CREATE TYPE hub_status AS ENUM ('active', 'suspended')`,
    );
    await manager.query(
      `ALTER TABLE hubs
       ALTER COLUMN status TYPE hub_status
       USING (
         CASE hubs.status::text
           WHEN 'approved' THEN 'active'
           ELSE 'suspended'
         END
       )::hub_status`,
    );
    await manager.query(`DROP TYPE hub_status_old`);
    await manager.query(
      `ALTER TABLE hubs ALTER COLUMN status SET DEFAULT 'active'`,
    );
  });
}

async function copyLegacyHubAssignments(boot: DataSource): Promise<void> {
  await boot.query(
    `DO $$
     BEGIN
       IF EXISTS (
         SELECT 1
         FROM pg_attribute a
         JOIN pg_class c ON a.attrelid = c.oid
         JOIN pg_namespace n ON c.relnamespace = n.oid
         WHERE n.nspname = 'public'
           AND c.relname = 'users'
           AND a.attname = 'hubId'
           AND NOT a.attisdropped
       ) THEN
         CREATE TABLE IF NOT EXISTS user_hubs (
           id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
           "userId" uuid NOT NULL,
           "hubId" uuid NOT NULL,
           UNIQUE ("userId", "hubId")
         );
         INSERT INTO user_hubs (id, "userId", "hubId")
         SELECT gen_random_uuid(), users.id, users."hubId"
         FROM users
         WHERE users."hubId" IS NOT NULL
           AND NOT EXISTS (
             SELECT 1 FROM user_hubs uh
             WHERE uh."userId" = users.id AND uh."hubId" = users."hubId"
           );
         ALTER TABLE users DROP COLUMN "hubId" CASCADE;
       END IF;
     END $$`,
  );
}

async function dropHubCreatorUnique(boot: DataSource): Promise<void> {
  const indexes = (await boot.query(
    `SELECT indexname, indexdef
     FROM pg_indexes
     WHERE schemaname = 'public' AND tablename = 'hubs'`,
  )) as Array<{ indexname: string; indexdef: string }>;
  for (const index of indexes) {
    const definition = index.indexdef.toLowerCase();
    if (
      definition.includes('unique') &&
      definition.includes('createdbyuserid')
    ) {
      await boot.query(`DROP INDEX IF EXISTS "${index.indexname}"`);
    }
  }
  if (await tableExists(boot, 'hubs')) {
    await boot.query(
      `ALTER TABLE hubs DROP COLUMN IF EXISTS "rejectionReason"`,
    );
  }
}

async function migrateInventorySaleType(boot: DataSource): Promise<void> {
  if (!(await tableExists(boot, 'inventory_items'))) {
    return;
  }
  const columns = (await boot.query(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'inventory_items'`,
  )) as Array<{ column_name: string }>;
  const names = new Set(columns.map((row) => row.column_name));
  if (names.has('requiresPrescription')) {
    await boot.query(
      `DO $$ BEGIN
         CREATE TYPE sale_type AS ENUM (
           'over_the_counter',
           'prescription',
           'special_control'
         );
       EXCEPTION
         WHEN duplicate_object THEN NULL;
       END $$`,
    );
    await boot.query(
      `ALTER TABLE inventory_items
       ADD COLUMN IF NOT EXISTS "saleType" sale_type`,
    );
    await boot.query(
      `UPDATE inventory_items
       SET "saleType" = CASE
         WHEN "requiresPrescription" THEN 'prescription'::sale_type
         ELSE 'over_the_counter'::sale_type
       END
       WHERE "saleType" IS NULL`,
    );
    await boot.query(
      `ALTER TABLE inventory_items ALTER COLUMN "saleType" SET NOT NULL`,
    );
    await boot.query(
      `ALTER TABLE inventory_items DROP COLUMN "requiresPrescription"`,
    );
  }
  if (!names.has('lot')) {
    await boot.query(
      `ALTER TABLE inventory_items ADD COLUMN lot varchar(20)`,
    );
    await boot.query(
      `UPDATE inventory_items SET lot = 'L-0001' WHERE lot IS NULL`,
    );
    await boot.query(
      `ALTER TABLE inventory_items ALTER COLUMN lot SET NOT NULL`,
    );
  }
}

export async function alignSprintSchema(
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
    if (!(await tableExists(boot, 'users'))) {
      return;
    }
    await migrateHubStatus(boot);
    await copyLegacyHubAssignments(boot);
    await dropHubCreatorUnique(boot);
    await migrateInventorySaleType(boot);
  } finally {
    if (boot.isInitialized) {
      await boot.destroy();
    }
  }
}
