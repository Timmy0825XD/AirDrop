import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import {
  PRESCRIPTION_BUCKET,
  PRESCRIPTION_MAX_BYTES,
} from '../common/field-limits';

type PostgresOptions = TypeOrmModuleOptions & {
  type: 'postgres';
  url?: string;
  ssl?: boolean | object;
};

/**
 * Crea el bucket privado y retira el bytea de la fórmula.
 * No abre políticas: solo la service role (el backend) lee y escribe.
 */
export async function ensurePrescriptionBucket(
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
    const storage = await boot.query<unknown[]>(
      `SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage'`,
    );
    if (!storage.length) {
      return;
    }

    await boot.query(
      `INSERT INTO storage.buckets (
         id, name, public, file_size_limit, allowed_mime_types, type
       ) VALUES ($1, $1, false, $2, $3, 'STANDARD')
       ON CONFLICT (id) DO UPDATE SET
         public = false,
         file_size_limit = EXCLUDED.file_size_limit,
         allowed_mime_types = EXCLUDED.allowed_mime_types`,
      [
        PRESCRIPTION_BUCKET,
        PRESCRIPTION_MAX_BYTES,
        ['image/jpeg', 'image/png'],
      ],
    );
    await dropStoredBytes(boot);
    await ensureObjectKey(boot);
  } finally {
    if (boot.isInitialized) {
      await boot.destroy();
    }
  }
}

async function dropStoredBytes(boot: DataSource): Promise<void> {
  const table = await boot.query<Array<{ name: string | null }>>(
    `SELECT to_regclass('public.prescription_images') AS name`,
  );
  if (!table[0]?.name) {
    return;
  }
  const columns = await boot.query<Array<{ column_name: string }>>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = 'prescription_images'
       AND column_name = 'content'`,
  );
  if (!columns.length) {
    return;
  }
  const count = await boot.query<Array<{ n: number }>>(
    `SELECT count(*)::int AS n FROM prescription_images`,
  );
  if (count[0]?.n) {
    throw new Error(
      'prescription_images todavía guarda bytes. No se arranca para no perder fórmulas.',
    );
  }
  await boot.query(`ALTER TABLE prescription_images DROP COLUMN content`);
}

async function ensureObjectKey(boot: DataSource): Promise<void> {
  const table = await boot.query<Array<{ name: string | null }>>(
    `SELECT to_regclass('public.prescription_images') AS name`,
  );
  if (!table[0]?.name) {
    return;
  }
  const columns = await boot.query<Array<{ column_name: string }>>(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = 'prescription_images'
       AND column_name = 'objectKey'`,
  );
  if (columns.length) {
    return;
  }
  await boot.query(
    `ALTER TABLE prescription_images ADD COLUMN "objectKey" varchar(40)`,
  );
  const missing = await boot.query<Array<{ n: number }>>(
    `SELECT count(*)::int AS n FROM prescription_images WHERE "objectKey" IS NULL`,
  );
  if (!missing[0]?.n) {
    await boot.query(
      `ALTER TABLE prescription_images ALTER COLUMN "objectKey" SET NOT NULL`,
    );
  }
}
