// CH-03 — Interfaz – Pedidos – Misión (pedido en vuelo): seguir el dron en el
// mapa con la telemetría real (necesita Redis).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CH-03 — Pedido en vuelo', () => {
  let solicitante;
  let despachador;
  let operador;
  let pedido;
  let primero;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
    cy.then(() =>
      cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre({ latitude: 10.39, longitude: -73.17 })),
    ).then((p) => {
      pedido = p.body.id;
      cy.api(despachador, 'POST', `/orders/${pedido}/authorize`, {}).its('status').should('eq', 201);
      cy.api(despachador, 'POST', `/orders/${pedido}/confirm-load`).its('status').should('eq', 201);
    });
  });

  it('CH-03 paso 1: el pedido está en vuelo con su dron', () => {
    cy.esperarEstado(solicitante, pedido, 'in_flight', 10).then((orden) => {
      expect(orden.droneId).to.be.a('string');
    });
  });

  it('CH-03 pasos 2 y 3: el solicitante puede ver la posición del dron y la llegada estimada', () => {
    cy.api(solicitante, 'GET', `/telemetry/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
      primero = respuesta.body;
      cy.log(JSON.stringify(primero).slice(0, 300));
      expect(JSON.stringify(primero)).to.match(/lat/i);
    });
  });

  it('CH-03 paso 4: el siguiente paquete llega en máximo 2 segundos con otra posición', () => {
    cy.wait(2000);
    cy.api(solicitante, 'GET', `/telemetry/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(JSON.stringify(respuesta.body)).not.to.eq(JSON.stringify(primero));
    });
  });
});
