import { DocumentType } from '../common/enums/document-type.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';

/**
 * El escenario de la demostración en Valledupar (RF-40): lo crea
 * `pnpm seed:demo` y el reinicio de la consola lo devuelve a este estado.
 * Las personas son ficticias.
 */

export type DemoPerson = { fullName: string; email: string; phone: string };

export type DemoStockItem = {
  name: string;
  quantity: number;
  lot: string;
  expiresInDays: number;
  saleType: SaleType;
  cold?: boolean;
};

export type DemoHubPlan = {
  name: string;
  type: HubType;
  address: string;
  latitude: number;
  longitude: number;
  contactPhone: string;
  contactEmail: string;
  dispatchers: DemoPerson[];
  /** Prefijo del identificador de sus 5 drones. */
  dronePrefix: string;
  /** Estados de los drones con novedad: el resto queda disponible. */
  droneNotes: Array<{
    number: number;
    state: 'maintenance' | 'out_of_service';
    reason: string;
    inDays: number;
  }>;
  stock: DemoStockItem[];
};

export const requesters = [
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

export const operator: DemoPerson = {
  fullName: 'Andrés Felipe Cuello',
  email: 'andres.cuello@gmail.com',
  phone: '3185550201',
};

export const hubPlans: DemoHubPlan[] = [
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

export const geofences = [
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

/**
 * RF-37: los solicitantes del generador de pedidos. No son personas: no
 * tienen documento ni celular, y su correo usa el dominio reservado
 * `.invalid`, que no existe.
 */
export const simulatedRequesters = [1, 2, 3, 4].map((number) => ({
  fullName: `Solicitante simulado ${number}`,
  email: `solicitante.simulado${number}@airdrop.invalid`,
}));

/**
 * RF-37: a dónde piden los solicitantes simulados. Barrios de Valledupar
 * dentro de la zona de las tres centrales y fuera de las geovallas.
 */
export const simulatedDestinations = [
  {
    address: 'Barrio Los Mayales, Valledupar',
    latitude: 10.488,
    longitude: -73.238,
  },
  {
    address: 'Barrio Novalito, Valledupar',
    latitude: 10.47,
    longitude: -73.24,
  },
  {
    address: 'Barrio Primero de Mayo, Valledupar',
    latitude: 10.452,
    longitude: -73.247,
  },
  {
    address: 'Barrio San Joaquín, Valledupar',
    latitude: 10.462,
    longitude: -73.272,
  },
  {
    address: 'Barrio Villa Castro, Valledupar',
    latitude: 10.447,
    longitude: -73.262,
  },
  {
    address: 'Barrio La Nevada, Valledupar',
    latitude: 10.497,
    longitude: -73.257,
  },
  {
    address: 'Barrio Los Cortijos, Valledupar',
    latitude: 10.478,
    longitude: -73.276,
  },
  {
    address: 'Barrio Garupal, Valledupar',
    latitude: 10.448,
    longitude: -73.233,
  },
  {
    address: 'Barrio El Prado, Valledupar',
    latitude: 10.472,
    longitude: -73.258,
  },
  {
    address: 'Barrio Villa Miriam, Valledupar',
    latitude: 10.493,
    longitude: -73.246,
  },
];

export const allEmails = [
  ...requesters.map((person) => person.email),
  ...simulatedRequesters.map((person) => person.email),
  operator.email,
  ...hubPlans.flatMap((plan) => plan.dispatchers.map((d) => d.email)),
];
