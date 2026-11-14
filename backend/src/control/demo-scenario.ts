import {
  ESES,
  DELIVERY_POINTS,
  NODES,
  NetworkSite,
} from '../airspace/regional-network';
import { DocumentType } from '../common/enums/document-type.enum';
import { HubNetworkRole } from '../common/enums/hub-network-role.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';

/**
 * El escenario de la demostración en la red regional (RF-40,
 * `context/negocio/cobertura.md`): lo crea `pnpm seed:demo` y el reinicio de
 * la consola lo devuelve a este estado. Las personas son ficticias y sus
 * correos de personal usan el dominio reservado `airdrop.example`.
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
  /** RF-06: solo un nodo tiene drones. */
  networkRole: HubNetworkRole;
  address: string;
  latitude: number;
  longitude: number;
  contactPhone: string;
  contactEmail: string;
  dispatchers: DemoPerson[];
  /** Prefijo del identificador de sus drones. */
  dronePrefix: string;
  /** Cuántos drones tiene: 0 en una ESE. */
  droneCount: number;
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

function staff(fullName: string, user: string, phone: string): DemoPerson {
  return { fullName, email: `${user}@airdrop.example`, phone };
}

function item(
  name: string,
  quantity: number,
  lot: string,
  expiresInDays: number,
  saleType: SaleType,
  cold = false,
): DemoStockItem {
  return { name, quantity, lot, expiresInDays, saleType, cold };
}

const OTC = SaleType.OVER_THE_COUNTER;
const RX = SaleType.PRESCRIPTION;

function node(
  site: NetworkSite,
  address: string,
  phone: string,
  dispatchers: DemoPerson[],
  dronePrefix: string,
  droneNotes: DemoHubPlan['droneNotes'],
  stock: DemoStockItem[],
): DemoHubPlan {
  return {
    name: site.name,
    type: HubType.PHARMACY,
    networkRole: HubNetworkRole.NODE,
    address,
    latitude: site.latitude,
    longitude: site.longitude,
    contactPhone: phone,
    contactEmail: `${site.code}@airdrop.example`,
    dispatchers,
    dronePrefix,
    droneCount: 5,
    droneNotes,
    stock,
  };
}

function ese(
  site: NetworkSite,
  address: string,
  phone: string,
  dispatcher: DemoPerson,
  stock: DemoStockItem[],
): DemoHubPlan {
  return {
    name: site.name,
    type: HubType.HOSPITAL,
    networkRole: HubNetworkRole.ESE,
    address,
    latitude: site.latitude,
    longitude: site.longitude,
    contactPhone: phone,
    contactEmail: `${site.code}@airdrop.example`,
    dispatchers: [dispatcher],
    dronePrefix: '',
    droneCount: 0,
    droneNotes: [],
    stock,
  };
}

export const hubPlans: DemoHubPlan[] = [
  node(
    NODES.north,
    'Vía a Río Seco, corregimiento de Río Seco, Valledupar',
    '6055550301',
    [
      staff('María Camila Orozco', 'maria.orozco', '3005550311'),
      staff('Jorge Iván Maestre', 'jorge.maestre', '3005550312'),
    ],
    'AD-NOR',
    [],
    [
      item('Acetaminofén 500 mg', 150, 'ACE-N-2601', 420, OTC),
      item('Ibuprofeno 400 mg', 80, 'IBU-N-2602', 380, OTC),
      item('Amoxicilina 500 mg', 60, 'AMX-N-2603', 300, RX),
      item('Insulina glargina 100 UI', 30, 'INS-N-2604', 150, RX, true),
      item('Suero antiofídico polivalente', 10, 'SAP-N-2605', 200, RX, true),
      item('Morfina 10 mg/mL', 20, 'MOR-N-2606', 260, SaleType.SPECIAL_CONTROL),
    ],
  ),
  node(
    NODES.south,
    'Vía La Paz – San Diego, La Paz',
    '6055550302',
    [
      staff('Paola Andrea Daza', 'paola.daza', '3105550321'),
      staff('Ricardo Arzuaga', 'ricardo.arzuaga', '3105550322'),
    ],
    'AD-SUR',
    [
      {
        number: 5,
        state: 'maintenance',
        reason: 'Cambio de hélice trasera',
        inDays: 3,
      },
    ],
    [
      // Dos lotes del mismo producto: sale primero el que vence antes (FEFO).
      item('Acetaminofén 500 mg', 40, 'ACE-S-2512', 70, OTC),
      item('Acetaminofén 500 mg', 90, 'ACE-S-2701', 450, OTC),
      item('Loratadina 10 mg', 100, 'LOR-S-2607', 400, OTC),
      item('Amoxicilina 500 mg', 40, 'AMX-S-2608', 280, RX),
      item('Salbutamol inhalador 100 mcg', 45, 'SAL-S-2609', 330, RX),
      item('Insulina glargina 100 UI', 20, 'INS-S-2610', 120, RX, true),
      item('Vacuna antitetánica', 25, 'VAT-S-2611', 180, RX, true),
    ],
  ),
  node(
    NODES.west,
    'Entrada a Valencia de Jesús, Valledupar',
    '6055550303',
    [
      staff('Liliana Mendoza Castro', 'liliana.mendoza', '3155550331'),
      staff('Óscar David Pumarejo', 'oscar.pumarejo', '3155550332'),
    ],
    'AD-OCC',
    [
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
    [
      item('Acetaminofén 500 mg', 200, 'ACE-O-2612', 500, OTC),
      item('Suero oral', 120, 'SOR-O-2613', 360, OTC),
      item('Metformina 850 mg', 90, 'MET-O-2614', 420, RX),
      item('Losartán 50 mg', 70, 'LOS-O-2615', 410, RX),
      item('Epinefrina 1 mg/mL', 25, 'EPI-O-2616', 240, RX),
      item('Insulina glargina 100 UI', 50, 'INS-O-2617', 160, RX, true),
      item('Suero antiofídico polivalente', 8, 'SAP-O-2618', 210, RX, true),
    ],
  ),
  node(
    NODES.codazzi,
    'Salida a Becerril, Agustín Codazzi',
    '6055550304',
    [
      staff('Daniela Fragozo', 'daniela.fragozo', '3165550341'),
      staff('Hernán Quintero', 'hernan.quintero', '3165550342'),
    ],
    'AD-COD',
    [],
    [
      item('Acetaminofén 500 mg', 120, 'ACE-C-2619', 380, OTC),
      item('Suero oral', 80, 'SOR-C-2620', 300, OTC),
      item('Amoxicilina 500 mg', 50, 'AMX-C-2621', 260, RX),
      item('Enalapril 20 mg', 60, 'ENA-C-2622', 400, RX),
      item('Insulina glargina 100 UI', 15, 'INS-C-2623', 140, RX, true),
    ],
  ),
  ese(
    ESES.laPaz,
    'Calle 4 No. 5-20, La Paz',
    '6055550311',
    staff('Yolanda Ariza', 'yolanda.ariza', '3175550351'),
    [
      item('Acetaminofén 500 mg', 20, 'ACE-LP-2624', 200, OTC),
      item('Suero oral', 10, 'SOR-LP-2625', 180, OTC),
    ],
  ),
  ese(
    ESES.sanDiego,
    'Carrera 6 No. 3-15, San Diego',
    '6055550312',
    staff('Ramiro Daza', 'ramiro.daza', '3175550352'),
    [item('Acetaminofén 500 mg', 15, 'ACE-SD-2626', 190, OTC)],
  ),
  ese(
    ESES.manaure,
    'Calle Principal, Manaure Balcón del Cesar',
    '6055550313',
    staff('Kelly Montero', 'kelly.montero', '3175550353'),
    [item('Acetaminofén 500 mg', 10, 'ACE-MA-2627', 210, OTC)],
  ),
  ese(
    ESES.puebloBello,
    'Calle 3 No. 4-10, Pueblo Bello',
    '6055550314',
    staff('Alba Torres Izquierdo', 'alba.torres', '3175550354'),
    [
      item('Acetaminofén 500 mg', 12, 'ACE-PB-2628', 220, OTC),
      item('Suero oral', 6, 'SOR-PB-2629', 160, OTC),
    ],
  ),
  ese(
    ESES.codazzi,
    'Carrera 17 No. 9-30, Agustín Codazzi',
    '6055550315',
    staff('Jesús Ovalle', 'jesus.ovalle', '3175550355'),
    [item('Acetaminofén 500 mg', 25, 'ACE-AC-2630', 230, OTC)],
  ),
];

/**
 * Las geovallas del operador de la demo. Las zonas legales (aeropuerto,
 * bases, policía, resguardos) no van aquí: vienen con `airspace/` (RF-43).
 */
export const geofences = [
  {
    name: 'Fumigación aérea de cultivos',
    reason:
      'Avioneta fumigando entre Valencia de Jesús y Mariangola: obliga a rodear.',
    polygon: {
      type: 'Polygon' as const,
      coordinates: [
        [
          [-73.49, 10.244],
          [-73.47, 10.244],
          [-73.468, 10.262],
          [-73.49, 10.262],
          [-73.49, 10.244],
        ],
      ],
    },
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
 * RF-37: a dónde piden los solicitantes simulados: los puntos de entrega de
 * la red (RF-45).
 */
export const simulatedDestinations = DELIVERY_POINTS.map((point) => ({
  address: point.name,
  latitude: point.latitude,
  longitude: point.longitude,
}));

export const allEmails = [
  ...requesters.map((person) => person.email),
  ...simulatedRequesters.map((person) => person.email),
  operator.email,
  ...hubPlans.flatMap((plan) => plan.dispatchers.map((d) => d.email)),
];
