// Pruebas de aceptación (Segunda Parte, sección 2.6), CA001 a CA010.
// Se ejecutan en Swagger UI (http://localhost:3000/api), como lo haría una
// persona: Authorize con el token del rol, Try it out, el cuerpo del caso y
// Execute. Cada caso deja la captura de su respuesta (ACE_CAxxx.png).
//
//   ACEPTACION=1 npx cypress run --spec cypress/aceptacion/aceptacion.cy.js
import { CUENTAS, TAMIZAJE } from '../support/datos';

/** Fecha AAAA-MM-DD en Colombia, `dias` días después de hoy. */
function fechaColombia(dias) {
  const d = new Date(Date.now() + dias * 86400000);
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(d);
}

/** Próximo jueves (sin contar hoy). */
function proximoJueves() {
  for (let i = 1; i <= 7; i += 1) {
    const f = fechaColombia(i);
    if (new Date(`${f}T12:00:00Z`).getUTCDay() === 4) return f;
  }
  return fechaColombia(3);
}

/** Abre Swagger UI y autoriza con el token del rol. */
function abrirSwagger(token) {
  cy.visit('/api');
  cy.contains('button', 'Authorize').click();
  cy.get('.modal-ux input[type=text]').type(token, { log: false, delay: 0 });
  cy.get('.modal-ux').contains('button', 'Authorize').click();
  cy.get('.modal-ux').contains('button', 'Close').click();
}

/**
 * Ejecuta una operación: la abre, pone el cuerpo (y el id si lo tiene),
 * pulsa Execute, revisa el código y toma la captura.
 */
function ejecutar(operacion, cuerpo, esperado, captura, id) {
  const bloque = `[id$="-${operacion}"]`;
  cy.get(bloque).scrollIntoView().find('.opblock-summary').click();
  cy.get(bloque).contains('button', 'Try it out').click();
  if (id) {
    cy.get(bloque).find('input[placeholder="id"]').clear().type(id, { delay: 0 });
  }
  if (cuerpo) {
    cy.get(bloque)
      .find('textarea.body-param__text')
      .clear()
      .type(JSON.stringify(cuerpo, null, 2), {
        delay: 0,
        parseSpecialCharSequences: false,
      });
  }
  cy.get(bloque).contains('button', 'Execute').click();
  cy.get(bloque)
    .find('.live-responses-table tbody .response-col_status', { timeout: 30000 })
    .first()
    .should('contain.text', String(esperado));
  cy.get(bloque).find('.live-responses-table').scrollIntoView();
  // El bloque curl lleva el token: se tapa en la captura.
  cy.get(bloque).screenshot(captura, {
    capture: 'runner',
    overwrite: true,
    blackout: ['.curl-command', '.curl'],
  });
  // Cierra el bloque para el siguiente caso.
  cy.get(bloque).find('.opblock-summary').click();
}

describe('Pruebas de aceptación en Swagger (CA001 a CA010)', () => {
  const tokens = {};
  let centralA;
  let garza;
  let dronA;

  before(() => {
    cy.viewport(1400, 1000);
    cy.seedTest();
    cy.loginAdmin().then((t) => (tokens.admin = t));
    cy.login(CUENTAS.despachadorA).then((t) => (tokens.despachador = t));
    cy.login(CUENTAS.operador).then((t) => (tokens.operador = t));
    cy.login(CUENTAS.solicitante).then((t) => (tokens.solicitante = t));
    cy.then(() => cy.api(tokens.despachador, 'GET', '/auth/me')).then((yo) => {
      centralA = yo.body.hubIds[0];
      cy.api(tokens.operador, 'GET', `/fleet/drones?hubId=${centralA}`).then(
        (d) => (dronA = d.body.find((x) => x.identifier === 'AD-RPL-07').id),
      );
      cy.api(tokens.operador, 'GET', '/fleet/models').then(
        (m) => (garza = m.body.find((x) => x.name === 'Garza').id),
      );
    });
  });

  beforeEach(() => cy.viewport(1400, 1000));

  const CENTRAL = {
    name: 'PRUEBA-Hospital Eduardo Arredondo Daza',
    type: 'hospital',
    address: 'Calle 44 No. 26-10, Valledupar',
    latitude: 10.4485,
    longitude: -73.2589,
    contactPhone: '3001234567',
  };

  it('CA001: el administrador da de alta una central', () => {
    abrirSwagger(tokens.admin);
    ejecutar('HubsController_create', CENTRAL, 201, 'ACE_CA001');
  });

  it('CA002: una central con el celular de 9 dígitos se rechaza', () => {
    abrirSwagger(tokens.admin);
    ejecutar('HubsController_create', { ...CENTRAL, name: 'PRUEBA-CA002', contactPhone: '300123456' }, 400, 'ACE_CA002');
  });

  const ITEM = {
    name: 'Acetaminofén 500 mg',
    quantity: 240,
    lot: 'ACE-RPL-2601',
    expirationDate: '2028-02-13',
    requiresColdChain: false,
    saleType: 'over_the_counter',
    unitWeightG: 30,
  };

  it('CA003: el despachador registra un medicamento en su central', () => {
    abrirSwagger(tokens.despachador);
    ejecutar('InventoryController_create', ITEM, 201, 'ACE_CA003');
  });

  it('CA004: un medicamento que ya venció se rechaza', () => {
    abrirSwagger(tokens.despachador);
    ejecutar('InventoryController_create', { ...ITEM, expirationDate: '2025-12-31' }, 400, 'ACE_CA004');
  });

  it('CA005: el operador registra un Garza con compartimento de frío', () => {
    abrirSwagger(tokens.operador);
    ejecutar(
      'FleetController_createDrone',
      { identifier: 'AD-RPL-09', droneModelId: garza, hubId: centralA, coldCompartment: true },
      201,
      'ACE_CA005',
    );
  });

  it('CA006: el operador manda un dron a mantenimiento', () => {
    abrirSwagger(tokens.operador);
    ejecutar(
      'FleetController_updateStatus',
      { status: 'maintenance', reason: 'Revisión de hélices', estimatedEndDate: fechaColombia(4) },
      200,
      'ACE_CA006',
      dronA,
    );
  });

  it('CA007: el solicitante pide un medicamento urgente de venta libre', () => {
    abrirSwagger(tokens.solicitante);
    ejecutar(
      'OrdersController_createEmergency',
      {
        medicationName: 'Acetaminofén 500 mg',
        saleType: 'over_the_counter',
        triage: TAMIZAJE,
        allergies: '',
        address: 'Casa esquinera de reja verde',
        latitude: 10.365,
        longitude: -73.152,
      },
      201,
      'ACE_CA007',
    );
  });

  it('CA008: un medicamento de control especial no se pide por este canal', () => {
    abrirSwagger(tokens.solicitante);
    ejecutar(
      'OrdersController_createEmergency',
      {
        medicationName: 'Morfina 10 mg/mL',
        saleType: 'special_control',
        triage: TAMIZAJE,
        latitude: 10.365,
        longitude: -73.152,
      },
      400,
      'ACE_CA008',
    );
  });

  const PLAN = () => ({
    medicationName: 'Acetaminofén 500 mg',
    saleType: 'over_the_counter',
    quantity: 30,
    schedule: { kind: 'weekly', daysOfWeek: [4], everyWeeks: 1, startDate: proximoJueves(), count: 4, time: '10:00' },
    address: 'Casa esquinera de reja verde',
    latitude: 10.365,
    longitude: -73.152,
  });

  it('CA009: el solicitante programa una entrega semanal', () => {
    abrirSwagger(tokens.solicitante);
    ejecutar('OrdersController_createPlan', PLAN(), 201, 'ACE_CA009');
  });

  it('CA010: un plan que empieza ayer se rechaza', () => {
    abrirSwagger(tokens.solicitante);
    const plan = PLAN();
    plan.schedule.startDate = fechaColombia(-1);
    ejecutar('OrdersController_createPlan', plan, 400, 'ACE_CA010');
  });
});
