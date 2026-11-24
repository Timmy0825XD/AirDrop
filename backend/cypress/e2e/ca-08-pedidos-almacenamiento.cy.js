// CA-08 — C – G (ascendente): la fórmula de un pedido bajo fórmula se guarda
// en el almacenamiento privado y solo la ve el despachador de la central que
// tiene el pedido. La insulina viaja en frío: al dron de la central A
// (AD-RPL-07) se le instala el compartimento para que la urgencia se ofrezca.
import { CERCA_DE_A, CUENTAS, urgenciaConFormula } from '../support/datos';

const KB = 1024;

describe('CA-08 — C – G (Pedidos – Almacenamiento de fórmulas)', () => {
  let solicitante;
  let despachador;
  let operador;
  let pedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.api(despachador, 'GET', '/auth/me')).then((yo) => {
      cy.api(operador, 'GET', `/fleet/drones?hubId=${yo.body.hubIds[0]}`).then((drones) => {
        const dron = drones.body.find((d) => d.identifier === 'AD-RPL-07');
        cy.api(operador, 'PATCH', `/fleet/drones/${dron.id}/cold-compartment`, {
          installed: true,
        })
          .its('status')
          .should('eq', 200);
      });
    });
  });

  it('CA-08 paso 1: la urgencia bajo fórmula con dos fotos se crea recibida', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', {
      ...urgenciaConFormula(300 * KB, 'image/jpeg', 2),
      ...CERCA_DE_A,
    }).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
      expect(respuesta.body.status).to.eq('received');
      pedido = respuesta.body.id;
    });
  });

  it('CA-08 paso 2: el despachador de la central ve las dos fotos guardadas', () => {
    cy.api(despachador, 'GET', `/orders/${pedido}/prescription/files`).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
        const archivos = respuesta.body.files ?? respuesta.body;
        expect(archivos).to.have.length(2);
      },
    );
    cy.api(despachador, 'GET', `/orders/${pedido}/prescription/0`)
      .its('status')
      .should('eq', 200);
  });

  it('CA-08 paso 3: sin sesión, la fórmula no se entrega', () => {
    cy.request({
      method: 'GET',
      url: `/orders/${pedido}/prescription/0`,
      failOnStatusCode: false,
    })
      .its('status')
      .should('eq', 401);
  });

  it('CA-08 paso 4: el operador de flota no puede ver la fórmula (403)', () => {
    cy.api(operador, 'GET', `/orders/${pedido}/prescription/0`)
      .its('status')
      .should('eq', 403);
  });
});
