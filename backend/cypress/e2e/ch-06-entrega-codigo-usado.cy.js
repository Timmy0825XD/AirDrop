// CH-06 — Interfaz – Código de entrega – Pedidos (valores V5): reutilizar el
// código de una entrega ya cerrada. Preparación: el pedido llega por el flujo
// real (necesita Redis) y se entrega con su código.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CH-06 — Reutilizar el código de una entrega cerrada', () => {
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
    ).then((id) => {
      pedido = id;
      cy.api(solicitante, 'GET', `/orders/${id}/delivery-code`).then(
        (respuesta) => {
          codigo = respuesta.body.code;
          cy.api(solicitante, 'POST', `/orders/${id}/delivery-code/validate`, {
            code: codigo,
          })
            .its('body.status')
            .should('eq', 'delivered');
        },
      );
    });
  });

  it('CH-06 paso 1: para un pedido entregado no se genera un código nuevo', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}/delivery-code`).then(
      (respuesta) => {
        cy.log(`Respuesta real: ${respuesta.status} ${respuesta.body.message}`);
        expect(respuesta.status).to.eq(400);
        expect(respuesta.body.code).to.be.undefined;
      },
    );
  });

  it('CH-06 pasos 2 y 3: el mismo código ya usado se rechaza', () => {
    cy.api(solicitante, 'POST', `/orders/${pedido}/delivery-code/validate`, {
      code: codigo,
    }).then((respuesta) => {
      cy.log(`Respuesta real: ${respuesta.status} ${respuesta.body.message}`);
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'El código es inválido, ya se usó o venció.',
      );
    });
  });

  it('CH-06 paso 4: el pedido sigue entregado, sin cambios', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.status).to.eq('delivered');
    });
  });
});
