/**
 * Datos de prueba comunes (GUIA_EJECUCION_PRUEBAS, sección 2.3).
 *
 *   pnpm seed:test    limpia y vuelve a crear los datos
 *   pnpm seed:clean   borra lo que tenga prefijo PRUEBA- o correo @prueba.co
 *
 * Usa DATABASE_URL del .env: apúntalo a una base solo para pruebas.
 */
import { DocumentType } from '../src/common/enums/document-type.enum';
import { DroneStatus } from '../src/common/enums/drone-status.enum';
import { HubType } from '../src/common/enums/hub-type.enum';
import { SaleType } from '../src/common/enums/sale-type.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { WINGCOPTER_198_CODE } from '../src/fleet/drone-model-seed.service';
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

const TEST_PREFIX = 'PRUEBA-';
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
      address: 'Calle 16 No. 19-35, Valledupar',
      latitude: 10.4631,
      longitude: -73.2532,
      contactPhone: '3001234567',
    });
    const hubB = await createHub(app, adminToken, {
      name: `${TEST_PREFIX}Clínica del Norte`,
      type: HubType.CLINIC,
      address: 'Carrera 9 No. 15-20, Valledupar',
      latitude: 10.47,
      longitude: -73.25,
      contactPhone: '3109876543',
    });

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
    });
    await createInventoryItem(app, dispatcherA.token, {
      name: 'Insulina glargina 100 UI',
      quantity: 40,
      lot: 'INS-0925',
      expirationDate: '2027-03-15',
      requiresColdChain: true,
      saleType: SaleType.PRESCRIPTION,
    });
    await createInventoryItem(app, dispatcherB.token, {
      name: 'Acetaminofén 500 mg',
      quantity: 50,
      lot: 'LOT-2026-B',
      expirationDate: '2027-06-30',
      requiresColdChain: false,
      saleType: SaleType.OVER_THE_COUNTER,
    });

    const models = await request(app.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operator.token}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((model) => model.code === WINGCOPTER_198_CODE);
    if (!wingcopter) {
      throw new Error('No existe el modelo Wingcopter 198.');
    }

    await createDrone(app, operator.token, {
      identifier: 'WG-198-001',
      droneModelId: wingcopter.id,
      hubId: hubA,
    });
    const droneB = await createDrone(app, operator.token, {
      identifier: 'WG-198-002',
      droneModelId: wingcopter.id,
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

    console.log(
      `Datos de prueba creados. Contraseña de las cuentas ${TEST_EMAIL_DOMAIN}: ${TEST_PASSWORD}`,
    );
  } finally {
    await app.close();
  }
}

async function main(): Promise<void> {
  const command = process.argv[2];
  if (command === 'clean') {
    await cleanTestData();
    console.log('Datos de prueba eliminados.');
  } else if (command === 'seed') {
    await seedTestData();
  } else {
    throw new Error('Uso: seed-test.ts <seed|clean>');
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
