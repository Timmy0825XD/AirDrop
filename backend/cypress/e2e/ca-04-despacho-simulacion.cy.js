// CA-04 — F – K (ascendente): confirmar la carga inicia el vuelo simulado con
// telemetría. Necesita Redis. Sale de la central B (ver `activarCentralB`).
// El paso 4 (Redis detenido) está en redis-caido/ca-04-paso4.cy.js y se
// corre aparte, con el servidor iniciado sin Redis.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-04 — F – K (Despacho – Simulación y telemetría)', () => {
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
    // Preparación: un pedido pendiente de carga con dron y ruta.
    cy.then(() =>
      cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()),
    ).then((creado) => {
      pedido = creado.body.id;
      cy.api(despachador, 'POST', `/orders/${pedido}/authorize`, {})
        .its('body.status')
        .should('eq', 'pending_load');
    });
  });

  it('CA-04 paso 1: los pendientes de carga muestran el pedido con su dron', () => {
    cy.api(despachador, 'GET', '/orders/pending-load').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      const fila = respuesta.body.find((p) => p.id === pedido);
      expect(fila, 'pedido en la lista').to.exist;
      expect(fila.assignment.identifier).to.eq('WG-198-002');
    });
  });

  it('CA-04 paso 2: confirmar la carga pasa el pedido a «en vuelo»', () => {
    cy.api(despachador, 'POST', `/orders/${pedido}/confirm-load`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
      },
    );
    // El reloj de vuelo cambia el estado en su siguiente ciclo (≤ 2 s).
    cy.esperarEstado(despachador, pedido, 'in_flight', 10);
  });

  it('CA-04 paso 3: el operador recibe telemetría con posición, altitud, velocidad y batería al menos cada 2 s', () => {
    cy.api(operador, 'GET', `/telemetry/orders/${pedido}`).then((primera) => {
      expect(primera.status).to.eq(200);
      for (const campo of [
        'latitude',
        'longitude',
        'altitudeM',
        'speedKmh',
        'batteryPercent',
      ]) {
        expect(primera.body, campo).to.have.property(campo);
      }
      cy.wait(2500);
      cy.api(operador, 'GET', `/telemetry/orders/${pedido}`).then((segunda) => {
        expect(segunda.status).to.eq(200);
        // En 2,5 s llegó al menos un paquete nuevo: el vuelo avanzó.
        expect(
          JSON.stringify(segunda.body),
          'paquete distinto al anterior',
        ).not.to.eq(JSON.stringify(primera.body));
      });
    });
  });
});
