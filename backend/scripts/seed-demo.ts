/**
 * Datos para la demostración del flujo completo, en Valledupar.
 *
 *   pnpm seed:demo         limpia lo de la demo y vuelve a crearlo
 *   pnpm seed:demo:clean   borra solo lo que creó este script
 *
 * Crea los recursos (cuentas, centrales, flota, inventario y geovallas). Los
 * pedidos los hace quien presenta, desde la app. Todas las cuentas usan la
 * contraseña de `TEST_PASSWORD`. Usa el DATABASE_URL del .env.
 *
 * Los datos están en `src/control/demo-scenario.ts`: el reinicio de la
 * consola (`POST /control/reset`) vuelve a ese mismo estado sin recrear
 * cuentas ni centrales.
 */
import request from 'supertest';
import { UserRole } from '../src/common/enums/user-role.enum';
import {
  allEmails,
  geofences,
  hubPlans,
  operator,
  requesters,
} from '../src/control/demo-scenario';
import { WINGCOPTER_198_CODE } from '../src/fleet/drone-model-seed.service';
import { addCalendarDays, todayInColombia } from '../src/orders/orders.rules';
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
  createGeofence,
  createHub,
  createInventoryItem,
} from './seed-shared';

export function cleanDemoData(): Promise<void> {
  return cleanScope(
    {
      hubsSql: `SELECT id FROM hubs WHERE name = ANY($1)`,
      usersSql: `SELECT id FROM users WHERE email = ANY($2)`,
      params: [hubPlans.map((plan) => plan.name), allEmails],
    },
    async (db) => {
      await db.query(`DELETE FROM geofences WHERE name = ANY($1)`, [
        geofences.map((fence) => fence.name),
      ]);
    },
  );
}

async function seedDemoData(): Promise<void> {
  await cleanDemoData();
  const app = await createApp();
  try {
    const adminToken = await loginAdmin(app);
    const today = todayInColombia();

    const hubIds: string[] = [];
    for (const plan of hubPlans) {
      hubIds.push(
        await createHub(app, adminToken, {
          name: plan.name,
          type: plan.type,
          address: plan.address,
          latitude: plan.latitude,
          longitude: plan.longitude,
          contactPhone: plan.contactPhone,
          contactEmail: plan.contactEmail,
        }),
      );
    }

    const operatorSession = await createStaff(
      app,
      adminToken,
      operator,
      UserRole.FLEET_OPERATOR,
      hubIds,
    );

    const models = await request(app.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operatorSession.token}`)
      .expect(200);
    const wingcopter = (
      models.body as Array<{ id: string; code: string }>
    ).find((model) => model.code === WINGCOPTER_198_CODE);
    if (!wingcopter) {
      throw new Error('No existe el modelo Wingcopter 198.');
    }

    for (const [index, plan] of hubPlans.entries()) {
      const hubId = hubIds[index];
      const sessions = [];
      for (const dispatcher of plan.dispatchers) {
        sessions.push(
          await createStaff(app, adminToken, dispatcher, UserRole.DISPATCHER, [
            hubId,
          ]),
        );
      }
      // El inventario es de la central: lo carga su primer despachador.
      for (const item of plan.stock) {
        await createInventoryItem(app, sessions[0].token, {
          name: item.name,
          quantity: item.quantity,
          lot: item.lot,
          expirationDate: addCalendarDays(today, item.expiresInDays),
          requiresColdChain: item.cold ?? false,
          saleType: item.saleType,
        });
      }
      for (let number = 1; number <= 5; number += 1) {
        const droneId = await createDrone(app, operatorSession.token, {
          identifier: `${plan.dronePrefix}-0${number}`,
          droneModelId: wingcopter.id,
          hubId,
        });
        const note = plan.droneNotes.find((entry) => entry.number === number);
        if (!note) {
          continue;
        }
        const body = {
          reason: note.reason,
          estimatedEndDate: addCalendarDays(today, note.inDays),
        };
        if (note.state === 'maintenance') {
          await request(app.getHttpServer())
            .patch(`/fleet/drones/${droneId}/status`)
            .set('Authorization', `Bearer ${operatorSession.token}`)
            .send({ status: 'maintenance', ...body })
            .expect(200);
        } else {
          await request(app.getHttpServer())
            .post(`/fleet/drones/${droneId}/maintenance`)
            .set('Authorization', `Bearer ${operatorSession.token}`)
            .send(body)
            .expect(201);
        }
      }
    }

    for (const fence of geofences) {
      await createGeofence(app, operatorSession.token, fence);
    }

    for (const person of requesters) {
      await registerRequester(app, person);
    }

    console.log(
      `Demo lista: 3 centrales, 15 drones, 6 despachadores, 1 operador, 3 solicitantes y ${geofences.length} geovallas.`,
    );
    console.log(`Contraseña de todas las cuentas: ${TEST_PASSWORD}`);
  } finally {
    await app.close();
  }
}

async function main(): Promise<void> {
  const command = process.argv[2];
  if (command === 'clean') {
    await cleanDemoData();
    console.log('Datos de la demo eliminados.');
  } else if (command === 'seed') {
    await seedDemoData();
  } else {
    throw new Error('Uso: seed-demo.ts <seed|clean>');
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
