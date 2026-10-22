// CH-04 — Interfaz – Código de entrega – Pedidos – Misión – BD (valores V3).
// Recorre el flujo real hasta «en espera de entrega» (necesita Redis) y entrega
// con el código correcto. El código no se genera con un POST ni se guarda su
// hash: se deriva del pedido y se consulta con GET /orders/:id/delivery-code.
// Al entregar, el dron vuelve a su central y se libera al aterrizar allá.
import { CUENTAS, urgenciaLibre } from '../support/datos';

/** Consulta el dron cada 3 s hasta que vuelva a estar disponible. */
function esperarDronLibre(operador, central, identificador, intentos) {
  cy.api(operador, 'GET', `/fleet/drones?hubId=${central}`).then((drones) => {
    const dron = drones.body.find((d) => d.identifier === identificador);
    if (dron.status === 'available' || intentos <= 1) {
      expect(dron.status, `estado de ${identificador}`).to.eq('available');
      return;
    }
    cy.wait(3000, { log: false });
    esperarDronLibre(operador, central, identificador, intentos - 1);
  });
}

describe('CH-04 — Entrega con el código correcto', () => {
  let solicitante;
  let despachador;
  let operador;
  let central;
  let pedido;
  let codigo;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador)).then(
      (id) => (central = id),
    );
    cy.then(() =>
      cy.pedidoEnEsperaDeEntrega(solicitante, despachador, urgenciaLibre()),
    ).then((id) => (pedido = id));
  });

  it('CH-04 pasos 1 y 2: la pantalla de entrega muestra el código de 6 dígitos y su vencimiento', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}/delivery-code`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(200);
        expect(respuesta.body.code).to.match(/^\d{6}$/);
        expect(respuesta.body.expiresAt, 'vence tras el aterrizaje').to.be.a(
          'string',
        );
        codigo = respuesta.body.code;
      },
    );
  });

  it('CH-04 paso 3: ingresar el código correcto, sin usar y vigente, se acepta', () => {
    cy.api(solicitante, 'POST', `/orders/${pedido}/delivery-code/validate`, {
      code: codigo,
    }).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.status).to.eq('delivered');
    });
  });

  it('CH-04 paso 4: la misión se cierra y el dron queda libre', () => {
    // El dron regresa a su central y se libera al aterrizar allá (~2 min).
    esperarDronLibre(operador, central, 'WG-198-002', 100);
  });

  it('CH-04 paso 5: el pedido queda entregado', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.status).to.eq('delivered');
    });
  });
});
