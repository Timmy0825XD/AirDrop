// CH-05 — Interfaz – Código de entrega – BD (valores V4): código incorrecto
// con el código vigente. Recorre el flujo real hasta «en espera de entrega»
// (necesita Redis).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CH-05 — Entrega con un código incorrecto', () => {
  let solicitante;
  let despachador;
  let operador;
  let pedido;
  let codigo;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
    cy.then(() =>
      cy.pedidoEnEsperaDeEntrega(solicitante, despachador, urgenciaLibre()),
    ).then((id) => (pedido = id));
  });

  it('CH-05 paso 1: la pantalla de entrega muestra el código generado', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}/delivery-code`).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(200);
        expect(respuesta.body.code).to.match(/^\d{6}$/);
        codigo = respuesta.body.code;
      },
    );
  });

  it('CH-05 pasos 2 y 3: un código distinto no coincide y se rechaza', () => {
    // V4: seis dígitos distintos al código generado.
    const distinto = String((Number(codigo) + 1) % 1_000_000).padStart(6, '0');
    cy.api(solicitante, 'POST', `/orders/${pedido}/delivery-code/validate`, {
      code: distinto,
    }).then((respuesta) => {
      cy.log(`Respuesta real: ${respuesta.status} ${respuesta.body.message}`);
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'El código es inválido, ya se usó o venció.',
      );
    });
  });

  it('CH-05 paso 4: el pedido sigue en espera de entrega', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.status).to.eq('awaiting_delivery');
    });
  });
});
