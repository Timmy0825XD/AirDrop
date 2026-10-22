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

/** Urgencia de venta libre (datos V1 de la guía). */
export function urgenciaLibre(overrides = {}) {
  return {
    medicationName: 'Acetaminofén 500 mg',
    saleType: 'over_the_counter',
    description: 'Fiebre alta persistente',
    address: 'Calle 16 No. 19-35, Valledupar',
    latitude: 10.4802,
    longitude: -73.2475,
    ...overrides,
  };
}

/** Urgencia bajo fórmula con una imagen de `bytes` bytes y el tipo indicado. */
export function urgenciaConFormula(bytes, mime = 'image/jpeg') {
  return urgenciaLibre({
    medicationName: 'Insulina glargina 100 UI',
    saleType: 'prescription',
    description: 'Dosis diaria de insulina',
    ...DOCUMENTO_SOLICITANTE,
    prescriptionMime: mime,
    prescriptionImageBase64: archivoFalso(bytes, mime),
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
