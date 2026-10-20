/**
 * Datos para la demostración del flujo completo, en Valledupar.
 *
 *   pnpm seed:demo         limpia lo de la demo y vuelve a crearlo
 *   pnpm seed:demo:clean   borra solo lo que creó este script
 *
 * Crea los recursos (cuentas, centrales, flota, inventario y geovallas). Los
 * pedidos los hace quien presenta, desde la app. Todas las cuentas usan la
 * contraseña de `TEST_PASSWORD`. Usa el DATABASE_URL del .env.
 */
import request from 'supertest';
import { DocumentType } from '../src/common/enums/document-type.enum';
import { HubType } from '../src/common/enums/hub-type.enum';
import { SaleType } from '../src/common/enums/sale-type.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
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

type Person = { fullName: string; email: string; phone: string };

type StockItem = {
  name: string;
  quantity: number;
  lot: string;
  expiresInDays: number;
  saleType: SaleType;
  cold?: boolean;
};

type HubPlan = {
  name: string;
  type: HubType;
  address: string;
  latitude: number;
  longitude: number;
  contactPhone: string;
  contactEmail: string;
  dispatchers: Person[];
  /** Prefijo del identificador de sus 5 drones. */
  dronePrefix: string;
  /** Estados de los drones con novedad: el resto queda disponible. */
  droneNotes: Array<{
    number: number;
    state: 'maintenance' | 'out_of_service';
    reason: string;
    inDays: number;
  }>;
  stock: StockItem[];
};

const requesters = [
  {
    fullName: 'Valentina Rodríguez Pardo',
    email: 'valentina.rodriguez@gmail.com',
    phone: '3015550101',
    documentType: DocumentType.CITIZENSHIP_ID,
    documentNumber: '1065432187',
  },
  {
    fullName: 'Carlos Andrés Mejía',
    email: 'carlos.mejia@outlook.com',
    phone: '3125550102',
    documentType: DocumentType.FOREIGNER_ID,
    documentNumber: '4521987',
  },
  {
    fullName: 'Luis Fernando Peña',
    email: 'luis.pena@hotmail.com',
    phone: '3205550103',
    documentType: DocumentType.PPT,
    documentNumber: 'PPT25B77310',
  },
];

const operator: Person = {
  fullName: 'Andrés Felipe Cuello',
  email: 'andres.cuello@gmail.com',
  phone: '3185550201',
};

const hubPlans: HubPlan[] = [
  {
    name: 'Hospital Rosario Pumarejo de López',
    type: HubType.HOSPITAL,
    address: 'Carrera 15 No. 5-55, Valledupar',
    latitude: 10.476,
    longitude: -73.244,
    contactPhone: '6055550301',
    contactEmail: 'urgencias.rosario@gmail.com',
    dispatchers: [
      {
        fullName: 'María Camila Orozco',
        email: 'maria.orozco@gmail.com',
        phone: '3005550311',
      },
      {
        fullName: 'Jorge Iván Maestre',
        email: 'jorge.maestre@outlook.com',
        phone: '3005550312',
      },
    ],
    dronePrefix: 'WG198-ROS',
    droneNotes: [],
    stock: [
      {
        name: 'Acetaminofén 500 mg',
        quantity: 150,
        lot: 'ACE-A-2601',
        expiresInDays: 420,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Ibuprofeno 400 mg',
        quantity: 80,
        lot: 'IBU-A-2602',
        expiresInDays: 380,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Amoxicilina 500 mg',
        quantity: 60,
        lot: 'AMX-A-2603',
        expiresInDays: 300,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Insulina glargina 100 UI',
        quantity: 30,
        lot: 'INS-A-2604',
        expiresInDays: 150,
        saleType: SaleType.PRESCRIPTION,
        cold: true,
      },
      {
        name: 'Suero antiofídico polivalente',
        quantity: 10,
        lot: 'SAP-A-2605',
        expiresInDays: 200,
        saleType: SaleType.PRESCRIPTION,
        cold: true,
      },
      {
        name: 'Morfina 10 mg/mL',
        quantity: 20,
        lot: 'MOR-A-2606',
        expiresInDays: 260,
        saleType: SaleType.SPECIAL_CONTROL,
      },
    ],
  },
  {
    name: 'Clínica Valledupar',
    type: HubType.CLINIC,
    address: 'Calle 9 No. 19-40, Valledupar',
    latitude: 10.456,
    longitude: -73.264,
    contactPhone: '6055550302',
    contactEmail: 'despachos.clinicavalledupar@gmail.com',
    dispatchers: [
      {
        fullName: 'Paola Andrea Daza',
        email: 'paola.daza@hotmail.com',
        phone: '3105550321',
      },
      {
        fullName: 'Ricardo Arzuaga',
        email: 'ricardo.arzuaga@gmail.com',
        phone: '3105550322',
      },
    ],
    dronePrefix: 'WG198-CVA',
    droneNotes: [
      {
        number: 5,
        state: 'maintenance',
        reason: 'Cambio de hélice trasera',
        inDays: 3,
      },
    ],
    stock: [
      // Dos lotes del mismo producto: sale primero el que vence antes (FEFO).
      {
        name: 'Acetaminofén 500 mg',
        quantity: 40,
        lot: 'ACE-B-2512',
        expiresInDays: 70,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Acetaminofén 500 mg',
        quantity: 90,
        lot: 'ACE-B-2701',
        expiresInDays: 450,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Loratadina 10 mg',
        quantity: 100,
        lot: 'LOR-B-2607',
        expiresInDays: 400,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Amoxicilina 500 mg',
        quantity: 8,
        lot: 'AMX-B-2608',
        expiresInDays: 280,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Salbutamol inhalador 100 mcg',
        quantity: 45,
        lot: 'SAL-B-2609',
        expiresInDays: 330,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Insulina glargina 100 UI',
        quantity: 6,
        lot: 'INS-B-2610',
        expiresInDays: 120,
        saleType: SaleType.PRESCRIPTION,
        cold: true,
      },
      {
        name: 'Vacuna antitetánica',
        quantity: 25,
        lot: 'VAT-B-2611',
        expiresInDays: 180,
        saleType: SaleType.PRESCRIPTION,
        cold: true,
      },
    ],
  },
  {
    name: 'Droguería Central del Cesar',
    type: HubType.PHARMACY,
    address: 'Carrera 19 No. 14-20, Valledupar',
    latitude: 10.487,
    longitude: -73.265,
    contactPhone: '6055550303',
    contactEmail: 'pedidos.drogueriacesar@gmail.com',
    dispatchers: [
      {
        fullName: 'Liliana Mendoza Castro',
        email: 'liliana.mendoza@outlook.com',
        phone: '3155550331',
      },
      {
        fullName: 'Óscar David Pumarejo',
        email: 'oscar.pumarejo@gmail.com',
        phone: '3155550332',
      },
    ],
    dronePrefix: 'WG198-DCC',
    droneNotes: [
      {
        number: 4,
        state: 'maintenance',
        reason: 'Calibración de sensores',
        inDays: 2,
      },
      {
        number: 5,
        state: 'out_of_service',
        reason: 'Falla del módulo de batería',
        inDays: 14,
      },
    ],
    stock: [
      {
        name: 'Acetaminofén 500 mg',
        quantity: 200,
        lot: 'ACE-C-2612',
        expiresInDays: 500,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Suero oral',
        quantity: 120,
        lot: 'SOR-C-2613',
        expiresInDays: 360,
        saleType: SaleType.OVER_THE_COUNTER,
      },
      {
        name: 'Metformina 850 mg',
        quantity: 90,
        lot: 'MET-C-2614',
        expiresInDays: 420,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Losartán 50 mg',
        quantity: 70,
        lot: 'LOS-C-2615',
        expiresInDays: 410,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Epinefrina 1 mg/mL',
        quantity: 25,
        lot: 'EPI-C-2616',
        expiresInDays: 240,
        saleType: SaleType.PRESCRIPTION,
      },
      {
        name: 'Insulina glargina 100 UI',
        quantity: 50,
        lot: 'INS-C-2617',
        expiresInDays: 160,
        saleType: SaleType.PRESCRIPTION,
        cold: true,
      },
    ],
  },
];

/** Cuadrado de lado `2 * half` grados, como polígono GeoJSON cerrado. */
function square(lat: number, lng: number, half: number) {
  return {
    type: 'Polygon' as const,
    coordinates: [
      [
        [lng - half, lat - half],
        [lng + half, lat - half],
        [lng + half, lat + half],
        [lng - half, lat + half],
        [lng - half, lat - half],
      ],
    ],
  };
}

const geofences = [
  {
    name: 'Zona de eventos Parque de la Leyenda',
    reason:
      'Evento masivo: no sobrevolar. Obliga a rodear entre dos centrales.',
    polygon: square(10.466, -73.254, 0.003),
  },
  {
    name: 'Restricción aeroportuaria',
    reason: 'Aproximación del aeropuerto. Un destino aquí no tiene corredor.',
    polygon: square(10.435, -73.25, 0.006),
  },
  {
    name: 'Zona de seguridad militar',
    reason: 'Instalación restringida entre dos centrales.',
    polygon: square(10.483, -73.254, 0.003),
  },
];

const allEmails = [
  ...requesters.map((person) => person.email),
  operator.email,
  ...hubPlans.flatMap((plan) => plan.dispatchers.map((d) => d.email)),
];

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
