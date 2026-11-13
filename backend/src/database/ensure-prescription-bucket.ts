import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import {
  FIELD_LIMITS,
  PRESCRIPTION_BUCKET,
  PRESCRIPTION_MAX_BYTES,
} from '../common/field-limits';
import { PRESCRIPTION_MIMES } from '../orders/prescription.rules';

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
      [PRESCRIPTION_BUCKET, PRESCRIPTION_MAX_BYTES, PRESCRIPTION_MIMES],
    );
    await dropStoredBytes(boot);
    await ensureObjectKey(boot);
    await allowSeveralFiles(boot);
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

/**
 * RU-25: la fórmula pasa de una imagen a un PDF o hasta 3 fotos. Corre antes
 * de `synchronize` y también en producción, donde `synchronize` está apagado:
 * - alarga la clave antes de que TypeORM la vea distinta, porque al cambiar
 *   el largo TypeORM borra la columna y la vuelve a crear;
 * - agrega `position`;
 * - cambia el único por `orderId` por el único de `orderId` y `position`.
 */
async function allowSeveralFiles(boot: DataSource): Promise<void> {
  const table = await boot.query<Array<{ name: string | null }>>(
    `SELECT to_regclass('public.prescription_images') AS name`,
  );
  if (!table[0]?.name) {
    return;
  }
  await boot.query(
    `ALTER TABLE prescription_images ALTER COLUMN "objectKey" TYPE varchar(${FIELD_LIMITS.prescriptionObjectKey})`,
  );
  await boot.query(
    `ALTER TABLE prescription_images ADD COLUMN IF NOT EXISTS position smallint NOT NULL DEFAULT 0`,
  );
  const singles = await boot.query<Array<{ name: string }>>(
    `SELECT i.relname AS name
     FROM pg_index x
     JOIN pg_class i ON i.oid = x.indexrelid
     JOIN pg_class t ON t.oid = x.indrelid
     JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = x.indkey[0]
     WHERE t.relname = 'prescription_images'
       AND x.indisunique
       AND NOT x.indisprimary
       AND x.indnatts = 1
       AND a.attname = 'orderId'`,
  );
  for (const index of singles) {
    await boot.query(`DROP INDEX IF EXISTS "${index.name}"`);
  }
  await boot.query(
    `CREATE UNIQUE INDEX IF NOT EXISTS prescription_images_order_position
     ON prescription_images ("orderId", position)`,
  );
}
