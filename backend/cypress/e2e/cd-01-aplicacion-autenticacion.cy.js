// CD-01 — A – B (descendente, con Pedidos y Correo como resguardos): el acceso
// por rol con la Autenticación real.
import { CUENTAS } from '../support/datos';

describe('CD-01 — A – B (Aplicación – Autenticación)', () => {
  let solicitante;

  before(() => {
    cy.seedTest();
  });

  it('CD-01 paso 1: el solicitante entra con su token y su rol', () => {
    cy.login(CUENTAS.solicitante).then((token) => {
      solicitante = token;
      cy.api(token, 'GET', '/auth/me').its('body.role').should('eq', 'requester');
    });
  });

  it('CD-01 paso 2: el despachador entra con su rol y su central', () => {
    cy.login(CUENTAS.despachadorA).then((token) => {
      cy.api(token, 'GET', '/auth/me').then((yo) => {
        expect(yo.body.role).to.eq('dispatcher');
        expect(yo.body.hubIds).to.have.length(1);
      });
    });
  });

  it('CD-01 paso 3: el token del solicitante no sirve para crear una central (403)', () => {
    cy.api(solicitante, 'POST', '/hubs', {
      name: 'PRUEBA-No debe crearse',
      type: 'hospital',
      address: 'Calle 1',
      latitude: 10.31,
      longitude: -73.33,
      contactPhone: '3001234567',
    })
      .its('status')
      .should('eq', 403);
  });
});
