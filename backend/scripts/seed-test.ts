/**
 * Datos de prueba comunes (GUIA_EJECUCION_PRUEBAS, sección 2.3).
 *
 *   pnpm seed:test    limpia y vuelve a crear los datos
 *   pnpm seed:clean   borra lo que tenga prefijo PRUEBA- o correo @prueba.co
 *
 * Usa DATABASE_URL del .env: apúntalo a una base solo para pruebas.
 *
 * Con AISLAR_DEMO=1 (lo usa Cypress) suspende además las centrales que no
 * son de prueba, para que las urgencias de prueba no se ofrezcan a la red de
 * la demo (RU-10). El reinicio del escenario (POST /control/reset) las deja
 * activas de nuevo.
 */
import { DocumentType } from '../src/common/enums/document-type.enum';
import { DroneStatus } from '../src/common/enums/drone-status.enum';
import { HubType } from '../src/common/enums/hub-type.enum';
import { SaleType } from '../src/common/enums/sale-type.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { BALANCED_MODEL_CODE } from '../src/fleet/drone-model-seed.service';
import {
  createStaff,
  loginAdmin,
  registerRequester,
  TEST_PASSWORD,
} from '../test/e2e-helpers';
import {
  cleanScope,
  createApp,
  createDrone,
  createHub,
  createInventoryItem,
} from './seed-shared';
import request from 'supertest';
import { DataSource } from 'typeorm';

const TEST_PREFIX = 'PRUEBA-';
/** Ya se crearon los datos (lo que falle después, al cerrar, no cuenta). */
let seedDone = false;
const TEST_EMAIL_DOMAIN = '@prueba.co';

export function cleanTestData(): Promise<void> {
  return cleanScope({
    hubsSql: `SELECT id FROM hubs WHERE name LIKE $1`,
    usersSql: `SELECT id FROM users WHERE email LIKE $2`,
    params: [`${TEST_PREFIX}%`, `%${TEST_EMAIL_DOMAIN}`],
  });
}

async function seedTestData(): Promise<void> {
  await cleanTestData();
  const app = await createApp();
  try {
    const adminToken = await loginAdmin(app);

    const hubA = await createHub(app, adminToken, {
      name: `${TEST_PREFIX}Hospital Rosario Pumarejo`,
      type: HubType.HOSPITAL,
      address: 'Vía a Río Seco, Valledupar',
      latitude: 10.6075,
      longitude: -73.2237,
      contactPhone: '3001234567',
    });
    const hubB = await createHub(app, adminToken, {
      name: `${TEST_PREFIX}Clínica del Norte`,
      type: HubType.CLINIC,
      address: 'Vía La Paz – San Diego, La Paz',
      latitude: 10.355,
      longitude: -73.14,
      contactPhone: '3109876543',
    });

    if (process.env.AISLAR_DEMO === '1') {
      const others = (await app
        .get(DataSource)
        .query(`SELECT id FROM hubs WHERE name NOT LIKE $1 AND status = 'active'`, [
          `${TEST_PREFIX}%`,
        ])) as Array<{ id: string }>;
      for (const hub of others) {
        await request(app.getHttpServer())
          .patch(`/hubs/${hub.id}/suspension`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({ suspended: true })
          .expect(200);
      }
      console.log(`Centrales de la demo suspendidas: ${others.length}`);
    }

    const dispatcherA = await createStaff(
      app,
      adminToken,
      {
        fullName: 'Despachador A Prueba',
        email: `despachador.a${TEST_EMAIL_DOMAIN}`,
        phone: '3201110001',
      },
      UserRole.DISPATCHER,
      [hubA],
    );
    const dispatcherB = await createStaff(
      app,
      adminToken,
      {
        fullName: 'Despachador B Prueba',
        email: `despachador.b${TEST_EMAIL_DOMAIN}`,
        phone: '3201110002',
      },
      UserRole.DISPATCHER,
      [hubB],
    );
    const operator = await createStaff(
      app,
      adminToken,
      {
        fullName: 'Operador de Flota Prueba',
        email: `operador${TEST_EMAIL_DOMAIN}`,
        phone: '3201110003',
      },
      UserRole.FLEET_OPERATOR,
      [hubA, hubB],
    );
    await registerRequester(app, {
      fullName: 'Solicitante Prueba',
      email: `solicitante${TEST_EMAIL_DOMAIN}`,
      phone: '3201110004',
      documentType: DocumentType.CITIZENSHIP_ID,
      documentNumber: '1099000001',
    });

    await createInventoryItem(app, dispatcherA.token, {
      name: 'Acetaminofén 500 mg',
      quantity: 120,
      lot: 'LOT-2026-A',
      expirationDate: '2027-06-30',
      requiresColdChain: false,
      saleType: SaleType.OVER_THE_COUNTER,
      unitWeightG: 30,
    });
    await createInventoryItem(app, dispatcherA.token, {
      name: 'Insulina glargina 100 UI',
      quantity: 40,
      lot: 'INS-0925',
      expirationDate: '2027-03-15',
      requiresColdChain: true,
      saleType: SaleType.PRESCRIPTION,
      unitWeightG: 30,
    });
    await createInventoryItem(app, dispatcherB.token, {
      name: 'Acetaminofén 500 mg',
      quantity: 50,
      lot: 'LOT-2026-B',
      expirationDate: '2027-06-30',
      requiresColdChain: false,
      saleType: SaleType.OVER_THE_COUNTER,
      unitWeightG: 30,
    });

    const models = await request(app.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(200);
    const garza = (models.body as Array<{ id: string; code: string }>).find(
      (model) => model.code === BALANCED_MODEL_CODE,
    );
    if (!garza) {
      throw new Error('No existe el tipo Garza.');
    }

    await createDrone(app, operator.token, {
      identifier: 'AD-RPL-07',
      droneModelId: garza.id,
      hubId: hubA,
    });
    const droneB = await createDrone(app, operator.token, {
      identifier: 'AD-RPL-08',
      droneModelId: garza.id,
      hubId: hubB,
    });
    await request(app.getHttpServer())
      .patch(`/fleet/drones/${droneB}/status`)
      .set('Authorization', `Bearer ${operator.token}`)
      .send({
        status: DroneStatus.MAINTENANCE,
        reason: 'Mantenimiento programado de prueba',
      })
      .expect(200);

    seedDone = true;
    console.log(
      `Datos de prueba creados. Contraseña de las cuentas ${TEST_EMAIL_DOMAIN}: ${TEST_PASSWORD}`,
    );
  } finally {
    await app.close().catch(() => undefined);
  }
}

async function main(): Promise<void> {
  const command = process.argv[2];
  if (command === 'clean') {
    await cleanTestData();
    console.log('Datos de prueba eliminados.');
  } else if (command === 'seed') {
    // Una consulta de fondo de la app (el reloj de vuelo) puede fallar
    // cuando la conexión se cierra. Si los datos ya quedaron, no cuenta.
    const lateError = (error: unknown) => {
      if (seedDone) process.exit(0);
      console.error(error instanceof Error ? error.message : error);
      process.exit(1);
    };
    process.on('uncaughtException', lateError);
    process.on('unhandledRejection', lateError);
    await seedTestData();
    process.exit(0);
  } else {
    throw new Error('Uso: seed-test.ts <seed|clean>');
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
