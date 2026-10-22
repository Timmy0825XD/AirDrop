// CD-09 — F – K: el Despacho con la Simulación y la telemetría reales inicia
// el vuelo y exige la central de origen. Necesita Redis encendido. El pedido
// sale de la central B (ver `activarCentralB`); la «otra central» es la A.
// El paso 3 (Redis caído) está en redis-caido/cd-09-paso3.cy.js y se corre
// aparte, con el servidor iniciado sin Redis.
import { CUENTAS, urgenciaLibre } from '../support/datos';

/** Consulta el pedido cada 2 s hasta ver `estado` (máximo `intentos`). */
function esperarEstado(token, id, estado, intentos) {
  cy.api(token, 'GET', `/orders/${id}`).then((respuesta) => {
    if (respuesta.body.status === estado || intentos <= 1) {
      expect(respuesta.body.status).to.eq(estado);
      return;
    }
    cy.wait(2000, { log: false });
    esperarEstado(token, id, estado, intentos - 1);
  });
}

describe('CD-09 — F – K (Despacho – Simulación y telemetría)', () => {
  let solicitante;
  let despachadorOrigen;
  let despachadorOtra;
  let operador;
  let pedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachadorOrigen = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachadorOtra = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachadorOrigen));
    // Preparación: un pedido pendiente de carga en la central de origen.
    cy.then(() =>
      cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()),
    ).then((creado) => {
      pedido = creado.body.id;
      cy.api(despachadorOrigen, 'POST', `/orders/${pedido}/authorize`, {})
        .its('body.status')
        .should('eq', 'pending_load');
    });
  });

  it('CD-09 paso 1: el despachador de otra central no confirma la carga (403)', () => {
    cy.api(despachadorOtra, 'POST', `/orders/${pedido}/confirm-load`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(403);
        expect(respuesta.body.message).to.eq(
          'Solo el despachador de la central de origen confirma la carga.',
        );
      },
    );
  });

  it('CD-09 paso 2: el despachador de origen confirma la carga, el pedido vuela y hay telemetría', () => {
    cy.api(despachadorOrigen, 'POST', `/orders/${pedido}/confirm-load`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.loadConfirmedAt).to.be.a('string');
      },
    );
    // El reloj de vuelo cambia el estado en su siguiente ciclo (≤ 2 s).
    esperarEstado(despachadorOrigen, pedido, 'in_flight', 15);
    cy.api(despachadorOrigen, 'GET', `/telemetry/orders/${pedido}`).then(
      (telemetria) => {
        expect(telemetria.status).to.eq(200);
      },
    );
  });
});
