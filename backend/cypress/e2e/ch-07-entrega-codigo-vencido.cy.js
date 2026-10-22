// CH-07 — Interfaz – Código de entrega – Misión – Pedidos (valores V6): el
// código correcto después de la espera. La espera se acorta con
// DELIVERY_WAIT_MS=10000 al iniciar el servidor (10 s en lugar de 5 min):
// anotarlo en Observaciones. Necesita Redis.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CH-07 — Código correcto después del tiempo de espera', () => {
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
      // Se lee el código mientras sigue vigente.
      cy.api(solicitante, 'GET', `/orders/${id}/delivery-code`).then(
        (respuesta) => (codigo = respuesta.body.code),
      );
    });
  });

  it('CH-07 paso 1: pasa el tiempo de espera sin ingresar el código', () => {
    // Al vencer la espera, el reloj de vuelo manda el dron de regreso.
    cy.esperarEstado(solicitante, pedido, 'returning', 40);
  });

  it('CH-07 pasos 2 y 3: el código correcto, ya vencido, se rechaza', () => {
    cy.api(solicitante, 'POST', `/orders/${pedido}/delivery-code/validate`, {
      code: codigo,
    }).then((respuesta) => {
      cy.log(`Respuesta real: ${respuesta.status} ${respuesta.body.message}`);
      expect(respuesta.status).to.eq(400);
      // Con el pedido ya «en retorno» el estado se revisa antes que el código.
      expect(respuesta.body.message).to.be.oneOf([
        'Solo se entrega un pedido en espera de entrega.',
        'El código es inválido, ya se usó o venció.',
      ]);
    });
  });

  it('CH-07 paso 4: el dron regresa con el paquete y el pedido queda en retorno', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.status).to.eq('returning');
    });
  });
});
