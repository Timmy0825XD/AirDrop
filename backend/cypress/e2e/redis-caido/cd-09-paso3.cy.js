// CD-09 paso 3 — falla provocada: el servidor se inicia con un REDIS_URL que
// no responde (Redis «detenido»). Sin telemetría no debe arrancar el vuelo.
// Se corre solo, con REDIS_CAIDO=1. Sale de la central B (ver
// `activarCentralB`).
import { CUENTAS, urgenciaLibre } from '../../support/datos';

describe('CD-09 — F – K (Redis caído)', () => {
  let solicitante;
  let despachador;
  let operador;
  let pedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
    cy.then(() =>
      cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()),
    ).then((creado) => {
      pedido = creado.body.id;
      cy.api(despachador, 'POST', `/orders/${pedido}/authorize`, {})
        .its('body.status')
        .should('eq', 'pending_load');
    });
  });

  it('CD-09 paso 3: con Redis detenido, confirmar la carga responde 503', () => {
    cy.api(despachador, 'POST', `/orders/${pedido}/confirm-load`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(503);
        expect(respuesta.body.message).to.eq(
          'La telemetría no está disponible. No se puede iniciar el vuelo.',
        );
      },
    );
  });
});
