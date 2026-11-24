// CA-10 — A – C (ascendente): recorrido del solicitante en la aplicación:
// pide la urgencia, la ve en «Mis pedidos» y abre el seguimiento, que todavía
// no tiene mapa porque no hay vuelo (RF-15).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-10 — A – C (Aplicación – Pedidos)', () => {
  let solicitante;
  let pedido;

  before(() => {
    cy.seedTest();
  });

  it('CA-10 paso 1: el solicitante inicia sesión y entra con su rol', () => {
    cy.login(CUENTAS.solicitante).then((token) => {
      solicitante = token;
      cy.api(token, 'GET', '/auth/me').its('body.role').should('eq', 'requester');
    });
  });

  it('CA-10 paso 2: la urgencia queda en la cola de despacho', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
        pedido = respuesta.body.id;
      },
    );
  });

  it('CA-10 paso 3: «Mis pedidos» muestra el pedido recibido', () => {
    cy.api(solicitante, 'GET', '/orders/mine').then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
      const lista = respuesta.body.items ?? respuesta.body;
      const fila = lista.find((p) => p.id === pedido);
      expect(fila.status).to.eq('received');
    });
  });

  it('CA-10 paso 4: el seguimiento no tiene telemetría porque el pedido no está en vuelo', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.body.status).to.eq('received');
      expect(respuesta.body.droneId).to.eq(null);
    });
    cy.api(solicitante, 'GET', `/telemetry/orders/${pedido}`).then((respuesta) => {
      // Sin vuelo no hay posición que mostrar en el mapa.
      const sinVuelo = respuesta.status >= 400 || respuesta.body == null || respuesta.body.position == null;
      expect(sinVuelo, `respuesta ${respuesta.status}`).to.eq(true);
    });
  });
});
