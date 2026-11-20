import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { OperationalCategory } from '../common/enums/operational-category.enum';
import {
  DEMO_PLACES,
  HUB_SITES,
  NetworkSite,
} from '../airspace/regional-network';
import { DocumentType } from '../common/enums/document-type.enum';
import { DroneKind } from '../common/enums/drone-kind.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';

/**
 * El escenario de la demostración en la red regional (RF-40,
 * `context/negocio/cobertura.md`): lo crea `pnpm seed:demo` y el reinicio de
 * la consola lo devuelve a este estado. Las personas son ficticias; las
 * cuentas usan el dominio `airdrop.com`.
 */

export type DemoPerson = { fullName: string; email: string; phone: string };

export type DemoStockItem = {
  name: string;
  quantity: number;
  lot: string;
  expiresInDays: number;
  saleType: SaleType;
  cold?: boolean;
  /** Peso de una unidad tal como viaja, en gramos (RF-11). */
  unitWeightG: number;
};

/** RF-49: un dron de la semilla, con su tipo y si lleva compartimento de frío. */
export type DemoDrone = { kind: DroneKind; cold: boolean };

export type DemoHubPlan = {
  name: string;
  type: HubType;
  address: string;
  latitude: number;
  longitude: number;
  contactPhone: string;
  contactEmail: string;
  dispatchers: DemoPerson[];
  /** Prefijo del identificador de sus drones. */
  dronePrefix: string;
  /** La flota de la central, en el orden de su identificador (-01, -02…). */
  fleet: DemoDrone[];
  /** Estados de los drones con novedad: el resto queda disponible. */
  droneNotes: Array<{
    number: number;
    state: 'maintenance' | 'out_of_service';
    reason: string;
    inDays: number;
  }>;
  stock: DemoStockItem[];
};

/** Dominio de todas las cuentas y centrales de la demo. */
const DOMAIN = 'airdrop.com';

const CC = DocumentType.CITIZENSHIP_ID;

function requester(
  fullName: string,
  user: string,
  phone: string,
  documentType: DocumentType,
  documentNumber: string,
) {
  return {
    fullName,
    email: `${user}@${DOMAIN}`,
    phone,
    documentType,
    documentNumber,
  };
}

/** Los 10 solicitantes comunes, registrados y listos para pedir. */
export const requesters = [
  requester(
    'Valentina Rodríguez Pardo',
    'valentina.rodriguez',
    '3015550101',
    CC,
    '1065432187',
  ),
  requester(
    'Carlos Andrés Mejía',
    'carlos.mejia',
    '3125550102',
    DocumentType.FOREIGNER_ID,
    '4521987',
  ),
  requester(
    'Luis Fernando Peña',
    'luis.pena',
    '3205550103',
    DocumentType.PPT,
    'PPT25B77310',
  ),
  requester(
    'Mariana Castro Vega',
    'mariana.castro',
    '3015550104',
    CC,
    '1065812044',
  ),
  requester('Ana Lucía Pérez', 'ana.perez', '3001112233', CC, '1065487321'),
  requester('José Gregorio Brito', 'jose.brito', '3145550106', CC, '77181920'),
  requester(
    'Sandra Milena Ospino',
    'sandra.ospino',
    '3175550107',
    CC,
    '49795310',
  ),
  requester(
    'Eduardo Antonio Cuadrado',
    'eduardo.cuadrado',
    '3215550108',
    CC,
    '1065601992',
  ),
  requester(
    'Yeimy Paola Montero',
    'yeimy.montero',
    '3045550109',
    CC,
    '1067945120',
  ),
  requester(
    'Rafael Enrique Sierra',
    'rafael.sierra',
    '3115550110',
    CC,
    '12435877',
  ),
];

function staff(fullName: string, user: string, phone: string): DemoPerson {
  return { fullName, email: `${user}@${DOMAIN}`, phone };
}

export const operator: DemoPerson = staff(
  'Andrés Felipe Cuello',
  'andres.cuello',
  '3185550201',
);

type CatalogEntry = { g: number; sale: SaleType; cold?: boolean };

const OTC = SaleType.OVER_THE_COUNTER;
const RX = SaleType.PRESCRIPTION;
const CONTROL = SaleType.SPECIAL_CONTROL;

/**
 * Lo que puede haber en una central: peso por unidad tal como viaja (caja,
 * frasco, vial, bolsa), en gramos, tipo de venta y si va en frío. Cifras de
 * referencia de la demo.
 */
const CATALOG: Record<string, CatalogEntry> = {
  'Acetaminofén 500 mg': { g: 30, sale: OTC },
  'Ibuprofeno 400 mg': { g: 30, sale: OTC },
  'Naproxeno 250 mg': { g: 30, sale: OTC },
  'Loratadina 10 mg': { g: 20, sale: OTC },
  'Omeprazol 20 mg': { g: 30, sale: OTC },
  'Suero oral': { g: 30, sale: OTC },
  'Amoxicilina 500 mg': { g: 40, sale: RX },
  'Azitromicina 500 mg': { g: 20, sale: RX },
  'Cefalexina 500 mg': { g: 40, sale: RX },
  'Ceftriaxona 1 g': { g: 25, sale: RX },
  'Losartán 50 mg': { g: 40, sale: RX },
  'Enalapril 20 mg': { g: 40, sale: RX },
  'Metformina 850 mg': { g: 50, sale: RX },
  'Atorvastatina 20 mg': { g: 30, sale: RX },
  'Salbutamol inhalador 100 mcg': { g: 60, sale: RX },
  'Prednisolona 5 mg': { g: 30, sale: RX },
  'Dexametasona 4 mg/mL': { g: 20, sale: RX },
  'Diclofenaco 75 mg/3 mL': { g: 20, sale: RX },
  'Epinefrina 1 mg/mL': { g: 20, sale: RX },
  'Solución salina 0,9 % 500 mL': { g: 550, sale: RX },
  'Lactato de Ringer 500 mL': { g: 550, sale: RX },
  'Insulina glargina 100 UI': { g: 60, sale: RX, cold: true },
  'Insulina NPH 100 UI': { g: 60, sale: RX, cold: true },
  'Oxitocina 10 UI': { g: 20, sale: RX, cold: true },
  'Suero antiofídico polivalente': { g: 150, sale: RX, cold: true },
  'Vacuna antitetánica': { g: 30, sale: RX, cold: true },
  'Vacuna contra la influenza': { g: 30, sale: RX, cold: true },
  'Vacuna triple viral': { g: 30, sale: RX, cold: true },
  'Vacuna contra la fiebre amarilla': { g: 30, sale: RX, cold: true },
  'Vacuna contra la hepatitis B': { g: 30, sale: RX, cold: true },
  'Morfina 10 mg/mL': { g: 20, sale: CONTROL },
  'Tramadol 50 mg/mL': { g: 20, sale: CONTROL },
  'Midazolam 5 mg/mL': { g: 20, sale: CONTROL },
  'Clonazepam 2 mg': { g: 20, sale: CONTROL },
};

/** [nombre, unidades, días hasta el vencimiento] */
type StockLine = [string, number, number];

/**
 * El inventario de una central. El lote se arma con las iniciales del
 * producto, la sigla de la central y un consecutivo (AMO-RPL-2603).
 */
function stock(tag: string, lines: StockLine[]): DemoStockItem[] {
  return lines.map(([name, quantity, expiresInDays], index) => {
    const entry = CATALOG[name];
    if (!entry) {
      throw new Error(`"${name}" no está en el catálogo de la demo.`);
    }
    const initials = name
      .normalize('NFD')
      .replace(/[^A-Za-z]/g, '')
      .slice(0, 3)
      .toUpperCase();
    return {
      name,
      quantity,
      lot: `${initials}-${tag}-${2601 + index}`,
      expiresInDays,
      saleType: entry.sale,
      cold: entry.cold ?? false,
      unitWeightG: entry.g,
    };
  });
}

const RAPID = DroneKind.RAPID;
const BALANCED = DroneKind.BALANCED;
const CARGO = DroneKind.CARGO;

/**
 * RF-49: toda central tiene dos de cada tipo. El primero de cada par lleva
 * compartimento de frío: -01 y -02 Colibrí, -03 y -04 Garza, -05 y -06 Cóndor.
 */
const FLEET: DemoDrone[] = [
  { kind: RAPID, cold: true },
  { kind: RAPID, cold: false },
  { kind: BALANCED, cold: true },
  { kind: BALANCED, cold: false },
  { kind: CARGO, cold: true },
  { kind: CARGO, cold: false },
];

function central(
  site: NetworkSite,
  type: HubType,
  address: string,
  phone: string,
  tag: string,
  dispatchers: [DemoPerson, DemoPerson],
  lines: StockLine[],
  droneNotes: DemoHubPlan['droneNotes'] = [],
): DemoHubPlan {
  return {
    name: site.name,
    type,
    address,
    latitude: site.latitude,
    longitude: site.longitude,
    contactPhone: phone,
    contactEmail: `${site.code.replace(/^hub-/, '')}@${DOMAIN}`,
    dispatchers,
    dronePrefix: `AD-${tag}`,
    fleet: FLEET,
    droneNotes,
    stock: stock(tag, lines),
  };
}

const H = HUB_SITES;

export const hubPlans: DemoHubPlan[] = [
  // Valledupar: cuatro centrales repartidas por la ciudad.
  central(
    H.rosarioPumarejo,
    HubType.HOSPITAL,
    'Calle 16 No. 17-141, barrio Santana, Valledupar',
    '6055550301',
    'RPL',
    [
      staff('Natalia Araújo Molina', 'natalia.araujo', '3005550301'),
      staff('Fabián Oñate Romero', 'fabian.onate', '3005550302'),
    ],
    [
      ['Acetaminofén 500 mg', 240, 450],
      ['Ibuprofeno 400 mg', 150, 400],
      ['Amoxicilina 500 mg', 90, 320],
      ['Ceftriaxona 1 g', 60, 280],
      ['Solución salina 0,9 % 500 mL', 80, 500],
      ['Lactato de Ringer 500 mL', 40, 480],
      ['Insulina glargina 100 UI', 45, 150],
      ['Oxitocina 10 UI', 20, 120],
      ['Epinefrina 1 mg/mL', 30, 240],
      ['Morfina 10 mg/mL', 20, 260],
      ['Midazolam 5 mg/mL', 15, 300],
    ],
  ),
  central(
    H.arredondo,
    HubType.HOSPITAL,
    'Carrera 20 No. 43-63, barrio San Martín, Valledupar',
    '6055550302',
    'EAD',
    [
      staff('María Camila Orozco', 'maria.orozco', '3005550311'),
      staff('Jorge Iván Maestre', 'jorge.maestre', '3005550312'),
    ],
    [
      ['Acetaminofén 500 mg', 180, 420],
      ['Diclofenaco 75 mg/3 mL', 70, 360],
      ['Cefalexina 500 mg', 60, 300],
      ['Azitromicina 500 mg', 40, 340],
      ['Dexametasona 4 mg/mL', 50, 310],
      ['Solución salina 0,9 % 500 mL', 60, 500],
      ['Insulina NPH 100 UI', 30, 140],
      ['Vacuna antitetánica', 25, 180],
      ['Tramadol 50 mg/mL', 25, 280],
    ],
  ),
  central(
    H.laNevada,
    HubType.CLINIC,
    'Calle 6 No. 42-102, barrio La Nevada, Valledupar',
    '6055550303',
    'NEV',
    [
      staff('Paola Andrea Daza', 'paola.daza', '3105550321'),
      staff('Ricardo Arzuaga', 'ricardo.arzuaga', '3105550322'),
    ],
    [
      // Dos lotes del mismo producto: sale primero el que vence antes (FEFO).
      ['Acetaminofén 500 mg', 40, 25],
      ['Acetaminofén 500 mg', 160, 450],
      ['Loratadina 10 mg', 100, 400],
      ['Omeprazol 20 mg', 120, 380],
      ['Losartán 50 mg', 90, 410],
      ['Atorvastatina 20 mg', 70, 420],
      ['Salbutamol inhalador 100 mcg', 40, 330],
      ['Insulina glargina 100 UI', 25, 130],
      ['Clonazepam 2 mg', 20, 360],
    ],
  ),
  central(
    H.elCarmen,
    HubType.CLINIC,
    'Calle 18B No. 5-50, barrio El Carmen, Valledupar',
    '6055550304',
    'CAR',
    [
      staff('Liliana Mendoza Castro', 'liliana.mendoza', '3155550331'),
      staff('Óscar David Pumarejo', 'oscar.pumarejo', '3155550332'),
    ],
    [
      ['Ibuprofeno 400 mg', 130, 390],
      ['Naproxeno 250 mg', 80, 370],
      ['Metformina 850 mg', 110, 420],
      ['Enalapril 20 mg', 80, 400],
      ['Prednisolona 5 mg', 50, 300],
      ['Amoxicilina 500 mg', 70, 310],
      ['Oxitocina 10 UI', 15, 110],
      // Pocas unidades: para ver el aviso de stock bajo.
      ['Insulina NPH 100 UI', 4, 150],
    ],
  ),
  // Un hospital por municipio.
  central(
    H.laPaz,
    HubType.HOSPITAL,
    'Calle 6 No. 6-15, La Paz',
    '6055550311',
    'LPZ',
    [
      staff('Daniela Fragozo', 'daniela.fragozo', '3165550341'),
      staff('Hernán Quintero', 'hernan.quintero', '3165550342'),
    ],
    [
      ['Acetaminofén 500 mg', 150, 400],
      ['Suero oral', 200, 300],
      ['Amoxicilina 500 mg', 60, 290],
      ['Losartán 50 mg', 60, 380],
      ['Solución salina 0,9 % 500 mL', 40, 480],
      ['Insulina glargina 100 UI', 20, 140],
      ['Vacuna antitetánica', 20, 170],
      ['Tramadol 50 mg/mL', 10, 300],
    ],
  ),
  central(
    H.sanDiego,
    HubType.HOSPITAL,
    'Calle 4 No. 2-36, San Diego',
    '6055550312',
    'SDG',
    [
      staff('Yolanda Ariza', 'yolanda.ariza', '3175550351'),
      staff('Ramiro Daza', 'ramiro.daza', '3175550352'),
    ],
    [
      ['Acetaminofén 500 mg', 120, 380],
      ['Ibuprofeno 400 mg', 80, 360],
      ['Cefalexina 500 mg', 40, 300],
      ['Metformina 850 mg', 70, 400],
      ['Salbutamol inhalador 100 mcg', 25, 320],
      ['Lactato de Ringer 500 mL', 30, 460],
      ['Suero antiofídico polivalente', 6, 200],
    ],
  ),
  central(
    H.manaure,
    HubType.HOSPITAL,
    'Carrera 6 No. 2F-12, Manaure Balcón del Cesar',
    '6055550313',
    'MAN',
    [
      staff('Kelly Montero', 'kelly.montero', '3175550353'),
      staff('Iván Darío Castro', 'ivan.castro', '3175550354'),
    ],
    [
      ['Acetaminofén 500 mg', 100, 410],
      ['Loratadina 10 mg', 60, 380],
      ['Azitromicina 500 mg', 30, 330],
      ['Enalapril 20 mg', 50, 390],
      ['Prednisolona 5 mg', 30, 280],
      ['Vacuna contra la influenza', 30, 160],
      ['Suero antiofídico polivalente', 5, 190],
    ],
  ),
  central(
    H.puebloBello,
    HubType.HOSPITAL,
    'Carrera 11 No. 9-45, barrio Centro, Pueblo Bello',
    '6055550314',
    'PBE',
    [
      staff('Alba Torres Izquierdo', 'alba.torres', '3175550355'),
      staff('Jesús Ovalle', 'jesus.ovalle', '3175550356'),
    ],
    [
      ['Acetaminofén 500 mg', 90, 420],
      ['Suero oral', 120, 280],
      ['Amoxicilina 500 mg', 40, 300],
      ['Salbutamol inhalador 100 mcg', 20, 310],
      ['Solución salina 0,9 % 500 mL', 30, 470],
      ['Vacuna contra la fiebre amarilla', 25, 150],
      ['Suero antiofídico polivalente', 8, 210],
    ],
    [
      {
        number: 4,
        state: 'maintenance',
        reason: 'Cambio de hélice trasera',
        inDays: 3,
      },
    ],
  ),
  central(
    H.codazzi,
    HubType.HOSPITAL,
    'Calle 14 No. 8-67, Agustín Codazzi',
    '6055550315',
    'COD',
    [
      staff('Rosa Elena Gutiérrez', 'rosa.gutierrez', '3175550357'),
      staff('Wilmer Arias Rojas', 'wilmer.arias', '3175550358'),
    ],
    [
      ['Acetaminofén 500 mg', 160, 430],
      ['Ibuprofeno 400 mg', 90, 380],
      ['Ceftriaxona 1 g', 40, 270],
      ['Diclofenaco 75 mg/3 mL', 50, 350],
      ['Losartán 50 mg', 70, 400],
      ['Insulina glargina 100 UI', 20, 130],
      ['Oxitocina 10 UI', 10, 100],
      ['Morfina 10 mg/mL', 10, 250],
    ],
    [
      {
        number: 6,
        state: 'out_of_service',
        reason: 'Falla del módulo de batería',
        inDays: 14,
      },
    ],
  ),
  // Un puesto de salud por corregimiento.
  central(
    H.rioSeco,
    HubType.VACCINATION,
    'Calle principal de Río Seco, Valledupar',
    '6055550321',
    'RSE',
    [
      staff('Kelly Johana Mestre', 'kelly.mestre', '3185550361'),
      staff('Álvaro José Mendoza', 'alvaro.mendoza', '3185550362'),
    ],
    [
      ['Vacuna antitetánica', 40, 180],
      ['Vacuna contra la influenza', 50, 150],
      ['Vacuna triple viral', 30, 200],
      ['Vacuna contra la hepatitis B', 30, 220],
      ['Vacuna contra la fiebre amarilla', 20, 170],
      ['Acetaminofén 500 mg', 80, 400],
      ['Suero oral', 100, 300],
    ],
    [
      {
        number: 3,
        state: 'maintenance',
        reason: 'Calibración de sensores',
        inDays: 2,
      },
    ],
  ),
  central(
    H.valencia,
    HubType.CLINIC,
    'Entrada a Valencia de Jesús, Valledupar',
    '6055550322',
    'VDJ',
    [
      staff('Leidy Carolina Baute', 'leidy.baute', '3185550363'),
      staff('Fredy Antonio Ustáriz', 'fredy.ustariz', '3185550364'),
    ],
    [
      ['Acetaminofén 500 mg', 100, 410],
      ['Suero oral', 150, 290],
      ['Amoxicilina 500 mg', 40, 300],
      ['Metformina 850 mg', 50, 400],
      ['Epinefrina 1 mg/mL', 15, 230],
      ['Suero antiofídico polivalente', 10, 200],
      // Vence pronto: para ver la alerta de vencimiento.
      ['Insulina glargina 100 UI', 12, 18],
    ],
  ),
  central(
    H.mediaLuna,
    HubType.CLINIC,
    'Calle 3 No. 6-22, Media Luna, San Diego',
    '6055550323',
    'MLU',
    [
      staff('Diana Marcela Rosado', 'diana.rosado', '3185550365'),
      staff('Ever José Plata', 'ever.plata', '3185550366'),
    ],
    [
      ['Acetaminofén 500 mg', 90, 390],
      ['Naproxeno 250 mg', 50, 360],
      ['Suero oral', 120, 280],
      ['Omeprazol 20 mg', 60, 370],
      ['Enalapril 20 mg', 40, 400],
      ['Salbutamol inhalador 100 mcg', 15, 300],
      ['Suero antiofídico polivalente', 6, 200],
    ],
  ),
];

/**
 * Las geovallas operativas de la demo (RF-21), como las dibuja la app. Las
 * zonas legales (aeropuerto, bases, policía, cárceles) no van aquí: las
 * siembra `airspace/regional-airspace.ts` (RF-43).
 */
export const geofences = [
  {
    name: 'Fumigación aérea de cultivos',
    reason:
      'Avioneta fumigando entre Valencia de Jesús y Mariangola: obliga a rodear.',
    category: OperationalCategory.OTHER,
    shape: GeofenceShape.POLYGON,
    vertices: [
      { latitude: 10.244, longitude: -73.49 },
      { latitude: 10.244, longitude: -73.47 },
      { latitude: 10.262, longitude: -73.468 },
      { latitude: 10.262, longitude: -73.49 },
    ],
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
 * RF-37: a dónde piden los solicitantes simulados: lugares de la región que
 * alguna central alcanza y que quedan fuera de las zonas legales.
 */
export const simulatedDestinations = DEMO_PLACES.map((point) => ({
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
