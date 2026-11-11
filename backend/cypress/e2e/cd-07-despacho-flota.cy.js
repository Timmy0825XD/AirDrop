// CD-07 — F – I: el Despacho con la Flota real elige un dron elegible y, si
// la central no tiene ninguno, la urgencia va a otra que sí (RU-10: se
// ofrece primero a las centrales con dron elegible). Rutas y simulación
// corren reales con los datos de `seed:test`. El despacho sale de la central B, cuyo único dron
// es WG-198-002 (ver `activarCentralB`); la guía dice WG-198-001 (central A).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CD-07 — F – I (Despacho – Flota)', () => {
  let solicitante;
  let despachador;
  let despachadorA;
  let operador;
  let dronAsignado;
  let segundoPedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachadorA = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
  });

  it('CD-07 paso 1: el pedido queda asignado al dron disponible de la central', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        expect(pedido.status).to.eq(201);
        cy.api(
          despachador,
          'POST',
          `/orders/${pedido.body.id}/authorize`,
          {},
        ).then((respuesta) => {
          expect(respuesta.status).to.eq(201);
          expect(respuesta.body.assignment.identifier).to.eq('WG-198-002');
          dronAsignado = respuesta.body.assignment.droneId;
        });
      },
    );
  });

  it('CD-07 paso 2: con el dron en mantenimiento, la urgencia no llega a la central B', () => {
    cy.api(operador, 'PATCH', `/fleet/drones/${dronAsignado}/status`, {
      status: 'maintenance',
      reason: 'Revisión de hélices',
    }).then((cambio) => {
      // Se registra lo que respondió la flota para las Observaciones.
      cy.log(
        `Cambio a mantenimiento: ${cambio.status} ${cambio.body.message ?? cambio.body.status}`,
      );
    });
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        expect(pedido.status).to.eq(201);
        segundoPedido = pedido.body.id;
        cy.api(
          despachador,
          'POST',
          `/orders/${segundoPedido}/authorize`,
          {},
        ).then((respuesta) => {
          // Antes respondía 409. Con RU-10 la urgencia sale hacia la central
          // que tiene dron (A) y B ni la ve en su cola.
          expect(respuesta.status).to.eq(403);
          expect(respuesta.body.message).to.eq(
            'Esta urgencia todavía no está en la cola de tu central.',
          );
        });
      },
    );
  });

  it('CD-07 paso 3: la central A la autoriza con su dron disponible', () => {
    cy.api(despachadorA, 'POST', `/orders/${segundoPedido}/authorize`, {}).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.assignment.identifier).to.eq('WG-198-001');
      },
    );
  });
});
