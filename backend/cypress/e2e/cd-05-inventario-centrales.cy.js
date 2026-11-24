// CD-05 — E – H (descendente, con Despacho, Flota, Rutas y Simulación como
// resguardos): Inventario y Centrales reales respetan la suspensión.
import { CUENTAS, ITEM_CA01 } from '../support/datos';

describe('CD-05 — E – H (Inventario – Centrales)', () => {
  let admin;
  let despachador;
  let solicitante;
  let central;

  before(() => {
    cy.seedTest();
    cy.loginAdmin().then((token) => (admin = token));
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) => {
      despachador = token;
      cy.api(token, 'GET', '/auth/me').then((yo) => (central = yo.body.hubIds[0]));
    });
  });

  it('CD-05 paso 1: el administrador suspende la central', () => {
    cy.api(admin, 'PATCH', `/hubs/${central}/suspension`, { suspended: true }).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
        expect(respuesta.body.status).to.eq('suspended');
      },
    );
  });

  it('CD-05 paso 2: con la central suspendida, agregar un ítem se rechaza (403)', () => {
    cy.api(despachador, 'POST', '/inventory', ITEM_CA01).then((respuesta) => {
      expect(respuesta.status).to.eq(403);
      expect(respuesta.body.message).to.eq('La central está suspendida.');
    });
  });

  it('CD-05 paso 3: al reactivarla, el ítem se guarda', () => {
    cy.api(admin, 'PATCH', `/hubs/${central}/suspension`, { suspended: false })
      .its('body.status')
      .should('eq', 'active');
    cy.api(despachador, 'POST', '/inventory', ITEM_CA01)
      .its('status')
      .should('eq', 201);
  });

  it('CD-05 paso 4: el catálogo del solicitante ofrece Acetaminofén', () => {
    cy.api(solicitante, 'GET', '/orders/catalog').then((respuesta) => {
      const lista = respuesta.body.items ?? respuesta.body;
      expect(lista.map((i) => i.name)).to.include('Acetaminofén 500 mg');
    });
  });
});
