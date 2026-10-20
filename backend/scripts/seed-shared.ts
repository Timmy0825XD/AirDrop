/**
 * Piezas comunes de los scripts de datos (`seed-test.ts` y `seed-demo.ts`).
 * Leen el DATABASE_URL del .env y se niegan a correr en producción.
 */
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';

const envFile = resolve(__dirname, '..', '.env');
if (existsSync(envFile)) {
  process.loadEnvFile(envFile);
}

export function assertNotProduction(): void {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Este script no se ejecuta con NODE_ENV=production.');
  }
  if (!process.env.DATABASE_URL) {
    throw new Error('Falta DATABASE_URL en backend/.env.');
  }
}

/** Qué se borra: las centrales y las cuentas que el script creó. */
export type SeedScope = {
  /** `SELECT id FROM hubs WHERE ...` con los parámetros de `params`. */
  hubsSql: string;
  /** `SELECT id FROM users WHERE ...` con los parámetros de `params`. */
  usersSql: string;
  params: unknown[];
};

/**
 * Postgres rechaza parámetros que la consulta no usa: se pasan solo los
 * `$n` que aparecen, renumerados desde 1.
 */
function usedParams(sql: string, params: unknown[]): [string, unknown[]] {
  const used = [...new Set([...sql.matchAll(/\$(\d+)/g)].map((m) => +m[1]))];
  used.sort((a, b) => a - b);
  const renumbered = sql.replace(
    /\$(\d+)/g,
    (_, n: string) => `$${used.indexOf(+n) + 1}`,
  );
  return [renumbered, used.map((n) => params[n - 1])];
}

/** Tablas que aún no existen (p. ej. delivery_codes) se omiten. */
async function deleteIfTableExists(
  db: DataSource,
  table: string,
  sql: string,
  params: unknown[],
): Promise<void> {
  const exists: Array<{ found: string | null }> = await db.query(
    `SELECT to_regclass($1) AS found`,
    [`public.${table}`],
  );
  if (exists[0].found) {
    await db.query(...usedParams(sql, params));
  }
}

/** Borra lo del alcance en el orden que respetan las llaves foráneas. */
export async function cleanScope(
  scope: SeedScope,
  extra?: (db: DataSource) => Promise<void>,
): Promise<void> {
  assertNotProduction();
  const db = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await db.initialize();
  try {
    const { params } = scope;
    const hubs = `(${scope.hubsSql})`;
    const users = `(${scope.usersSql})`;
    const orders = `(SELECT id FROM orders
       WHERE "originHubId" IN ${hubs} OR "destinationHubId" IN ${hubs}
          OR "requesterId" IN ${users} OR "createdByUserId" IN ${users})`;

    await deleteIfTableExists(
      db,
      'delivery_codes',
      `DELETE FROM delivery_codes WHERE "orderId" IN ${orders}`,
      params,
    );
    await db.query(
      ...usedParams(
        `DELETE FROM prescription_images WHERE "orderId" IN ${orders}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM mission_routes WHERE "orderId" IN ${orders}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM missions WHERE "orderId" IN ${orders}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(`DELETE FROM orders WHERE id IN ${orders}`, params),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM delivery_plans
       WHERE "originHubId" IN ${hubs} OR "destinationHubId" IN ${hubs}
          OR "requesterId" IN ${users} OR "createdByUserId" IN ${users}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM inventory_items WHERE "hubId" IN ${hubs}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(`DELETE FROM drones WHERE "hubId" IN ${hubs}`, params),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM user_hubs WHERE "hubId" IN ${hubs} OR "userId" IN ${users}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(
        `DELETE FROM one_time_codes WHERE "userId" IN ${users}`,
        params,
      ),
    );
    await db.query(
      ...usedParams(`DELETE FROM users WHERE id IN ${users}`, params),
    );
    await db.query(
      ...usedParams(`DELETE FROM hubs WHERE id IN ${hubs}`, params),
    );
    if (extra) {
      await extra(db);
    }
  } finally {
    await db.destroy();
  }
}

export async function createApp(): Promise<INestApplication<App>> {
  process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'seed-jwt-secret';
  // Sin Brevo no se envían correos a las cuentas de datos y el OTP vuelve en la respuesta.
  process.env.BREVO_API_KEY = '';
  // En `test` el registro devuelve el OTP; nunca se borra el esquema.
  process.env.NODE_ENV = 'test';
  process.env.E2E_DROP_SCHEMA = 'false';
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();
  const app = moduleRef.createNestApplication<INestApplication<App>>();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  await app.init();
  return app;
}

async function postId(
  app: INestApplication<App>,
  token: string,
  path: string,
  payload: Record<string, unknown>,
): Promise<string> {
  const response = await request(app.getHttpServer())
    .post(path)
    .set('Authorization', `Bearer ${token}`)
    .send(payload);
  if (response.status !== 201) {
    throw new Error(
      `POST ${path} respondió ${response.status}: ${JSON.stringify(response.body)}`,
    );
  }
  return (response.body as { id: string }).id;
}

export function createHub(
  app: INestApplication<App>,
  adminToken: string,
  payload: Record<string, unknown>,
): Promise<string> {
  return postId(app, adminToken, '/hubs', payload);
}

export async function createInventoryItem(
  app: INestApplication<App>,
  token: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await postId(app, token, '/inventory', payload);
}

export function createDrone(
  app: INestApplication<App>,
  token: string,
  payload: Record<string, unknown>,
): Promise<string> {
  return postId(app, token, '/fleet/drones', payload);
}

export function createGeofence(
  app: INestApplication<App>,
  token: string,
  payload: Record<string, unknown>,
): Promise<string> {
  return postId(app, token, '/geofences', payload);
}
