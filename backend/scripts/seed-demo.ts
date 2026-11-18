/**
 * Datos para la demostración del flujo completo, en la red regional del
 * Cesar (`context/negocio/cobertura.md`).
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
import { BALANCED_MODEL_CODE } from '../src/fleet/drone-model-seed.service';
import { addCalendarDays, todayInColombia } from '../src/orders/orders.rules';
import {
  createStaff,
  loginAdmin,
  registerRequester,
  TEST_PASSWORD,
} from '../test/e2e-helpers';
import { ScenarioNetworkService } from '../src/control/scenario-network.service';
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

    // RF-40: las centrales de otras versiones del escenario se van.
    await app.get(ScenarioNetworkService).removeStaleHubs();

    const operatorSession = await createStaff(
      app,
      adminToken,
      operator,
      UserRole.FLEET_OPERATOR,
      // RF-06: el operador cuida la flota de los nodos; una ESE no tiene drones.
      hubIds.filter((_, index) => hubPlans[index].droneCount > 0),
    );

    const models = await request(app.getHttpServer())
      .get('/fleet/models')
      .set('Authorization', `Bearer ${operatorSession.token}`)
      .expect(200);
    // RF-49: los tres tipos, por su código (rapid, balanced, cargo).
    const modelIdByKind = new Map(
      (models.body as Array<{ id: string; kind: string }>).map((model) => [
        model.kind,
        model.id,
      ]),
    );
    if (!modelIdByKind.get(BALANCED_MODEL_CODE)) {
      throw new Error('No existen los tipos de dron de la flota.');
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
          unitWeightG: item.unitWeightG,
        });
      }
      for (let number = 1; number <= plan.droneCount; number += 1) {
        const spec = plan.fleet[number - 1];
        const droneId = await createDrone(app, operatorSession.token, {
          identifier: `${plan.dronePrefix}-0${number}`,
          droneModelId: modelIdByKind.get(spec.kind),
          hubId,
          coldCompartment: spec.cold,
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

    const nodes = hubPlans.filter((plan) => plan.droneCount > 0).length;
    const drones = hubPlans.reduce((sum, plan) => sum + plan.droneCount, 0);
    const dispatchers = hubPlans.reduce(
      (sum, plan) => sum + plan.dispatchers.length,
      0,
    );
    console.log(
      `Demo lista: ${nodes} nodos, ${hubPlans.length - nodes} ESE, ${drones} drones, ${dispatchers} despachadores, 1 operador, ${requesters.length} solicitantes y ${geofences.length} geovallas, con los puntos de entrega de la red.`,
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
