import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

type PostgresOptions = TypeOrmModuleOptions & {
  type: 'postgres';
  url?: string;
  ssl?: boolean | object;
};

export async function enablePostgis(
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
    const installed = (await boot.query(
      `SELECT 1 FROM pg_extension WHERE extname = 'postgis'`,
    )) as unknown[];
    if (installed.length) {
      return;
    }
    await boot.query('CREATE EXTENSION IF NOT EXISTS postgis');
  } finally {
    if (boot.isInitialized) {
      await boot.destroy();
    }
  }
}
