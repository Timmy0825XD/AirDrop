// CA-07 — C – F (ascendente): el pedido del solicitante llega a la cola del
// despachador y se autoriza una sola vez. Sale de la central B (ver
// `activarCentralB`).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-07 — C – F (Pedidos – Despacho)', () => {
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
  });

  it('CA-07 paso 1: el solicitante crea la urgencia y queda recibida', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
        pedido = respuesta.body.id;
      },
    );
  });

  it('CA-07 paso 2: el pedido aparece en la cola de la central', () => {
    cy.api(despachador, 'GET', '/orders/queue').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.map((p) => p.id)).to.include(pedido);
    });
  });

  it('CA-07 paso 3: al autorizar queda pendiente de carga con dron y ruta', () => {
    cy.api(despachador, 'POST', `/orders/${pedido}/authorize`, {}).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.status).to.eq('pending_load');
        expect(respuesta.body.assignment.identifier).to.eq('WG-198-002');
        expect(respuesta.body.assignment.route).to.exist;
      },
    );
  });

  it('CA-07 paso 4: autorizar de nuevo el mismo pedido se rechaza (400)', () => {
    cy.api(despachador, 'POST', `/orders/${pedido}/authorize`, {}).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(400);
        expect(respuesta.body.message).to.eq(
          'Solo se autoriza un pedido que sigue en recibido.',
        );
      },
    );
  });
});
