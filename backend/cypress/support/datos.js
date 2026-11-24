// Datos de prueba compartidos por los casos CD (guía, sección 2.3).

export const CUENTAS = {
  despachadorA: 'despachador.a@prueba.co',
  despachadorB: 'despachador.b@prueba.co',
  operador: 'operador@prueba.co',
  solicitante: 'solicitante@prueba.co',
};

/** Documento con el que `seed:test` registra al solicitante. */
export const DOCUMENTO_SOLICITANTE = {
  patientDocumentType: 'citizenship_id',
  patientDocumentNumber: '1099000001',
};

/** Paso 1 de la urgencia: el tamizaje en fichas (RF-41). */
export const TAMIZAJE = {
  redFlags: [],
  patientGroup: 'adult',
  symptoms: ['fever'],
  onset: 'today',
  severity: 'moderate',
};

/** Urgencia de venta libre (valores V1): tamizaje, medicamento y punto en el mapa. */
export function urgenciaLibre(overrides = {}) {
  return {
    medicationName: 'Acetaminofén 500 mg',
    saleType: 'over_the_counter',
    triage: TAMIZAJE,
    allergies: '',
    address: 'Casa esquinera de reja verde',
    // Cerca de La Paz: la central B (PRUEBA-Clínica del Norte) es la que
    // llega antes, así que la urgencia entra primero a su cola (RU-10).
    latitude: 10.365,
    longitude: -73.152,
    ...overrides,
  };
}

/**
 * Urgencia bajo fórmula (RU-25): `fotos` archivos de `bytes` bytes cada uno,
 * del tipo indicado (una foto JPG, un PDF o cualquier otro).
 */
export function urgenciaConFormula(bytes, mime = 'image/jpeg', fotos = 1) {
  return urgenciaLibre({
    medicationName: 'Insulina glargina 100 UI',
    saleType: 'prescription',
    triage: { ...TAMIZAJE, symptoms: ['blood_sugar'] },
    ...DOCUMENTO_SOLICITANTE,
    prescriptions: Array.from({ length: fotos }, () => ({
      mime,
      base64: archivoFalso(bytes, mime),
    })),
  });
}

/** Contenido de relleno con la cabecera del tipo (JPEG o PDF), en base64. */
function archivoFalso(bytes, mime) {
  const content = Cypress.Buffer.alloc(bytes, 0x20);
  const header =
    mime === 'application/pdf'
      ? Cypress.Buffer.from('%PDF-1.4\n')
      : Cypress.Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  header.copy(content, 0);
  if (mime !== 'application/pdf') {
    Cypress.Buffer.from([0xff, 0xd9]).copy(content, bytes - 2);
  }
  return content.toString('base64');
}

/** Fecha de hoy en Colombia (AAAA-MM-DD), como la calcula el servidor. */
export function hoyEnColombia() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

/** Ítem del caso CA-01 (y de CD-05). */
export const ITEM_CA01 = {
  name: 'Acetaminofén 500 mg',
  quantity: 240,
  lot: 'ACE-RPL-2601',
  expirationDate: '2028-02-13',
  requiresColdChain: false,
  saleType: 'over_the_counter',
  unitWeightG: 30,
};

/** Un dato distinto en cada corrida: últimos `n` dígitos de la hora. */
export function unico(n) {
  return String(Date.now()).slice(-n);
}

/** Solicitante nuevo para los casos de registro (CA-05 y CD-02). */
export function solicitanteNuevo() {
  const n = unico(8);
  return {
    fullName: 'Solicitante Registro Prueba',
    documentType: 'citizenship_id',
    documentNumber: `10${n}`,
    email: `registro.${n}@prueba.co`,
    phone: `31${n}`,
    password: 'Password123',
    consentAccepted: true,
  };
}

/** Urgencia cerca de la central A (PRUEBA-Hospital Rosario Pumarejo, Río Seco). */
export const CERCA_DE_A = { latitude: 10.596, longitude: -73.214 };
