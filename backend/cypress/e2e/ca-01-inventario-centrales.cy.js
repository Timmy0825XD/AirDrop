// CA-01 — E – H (ascendente): el ítem que agrega el despachador queda en el
// inventario de la central que creó el administrador.
import { ITEM_CA01 } from '../support/datos';

const CENTRAL = {
  name: 'PRUEBA-Farmacia CA-01',
  type: 'pharmacy',
  address: 'Vía a Valencia de Jesús, Valledupar',
  latitude: 10.315,
  longitude: -73.335,
  contactPhone: '3001112233',
};
const DESPACHADOR = {
  fullName: 'Despachador CA-01 Prueba',
  email: 'despachador.ca01@prueba.co',
  phone: '3201110010',
  password: 'Password123',
  role: 'dispatcher',
};

describe('CA-01 — E – H (Inventario – Centrales)', () => {
  let admin;
  let central;
  let despachador;
  let item;

  before(() => {
    cy.seedTest();
    cy.loginAdmin().then((token) => (admin = token));
  });

  it('CA-01 paso 1: el administrador crea la central y queda activa', () => {
    cy.api(admin, 'POST', '/hubs', CENTRAL).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
      expect(respuesta.body.status).to.eq('active');
      central = respuesta.body.id;
    });
  });

  it('CA-01 paso 2: el despachador asignado inicia sesión y ve su central', () => {
    cy.api(admin, 'POST', '/users', { ...DESPACHADOR, hubIds: [central] })
      .its('status')
      .should('eq', 201);
    cy.login(DESPACHADOR.email).then((token) => {
      despachador = token;
      cy.api(token, 'GET', '/auth/me').then((yo) => {
        expect(yo.body.role).to.eq('dispatcher');
        expect(yo.body.hubIds).to.deep.eq([central]);
      });
    });
  });

  it('CA-01 paso 3: el ítem se guarda con el identificador de la central', () => {
    cy.api(despachador, 'POST', '/inventory', ITEM_CA01).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
      expect(respuesta.body.hubId).to.eq(central);
      item = respuesta.body.id;
    });
  });

  it('CA-01 paso 4: el inventario de la central lista el ítem con 240 unidades', () => {
    cy.api(despachador, 'GET', '/inventory').then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
      const fila = respuesta.body.find((i) => i.id === item);
      expect(fila.name).to.eq('Acetaminofén 500 mg');
      expect(fila.quantity).to.eq(240);
      expect(fila.lot).to.eq('ACE-RPL-2601');
    });
  });
});
