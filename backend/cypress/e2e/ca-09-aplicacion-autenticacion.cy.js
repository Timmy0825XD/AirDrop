// CA-09 — A – B (ascendente): cada rol entra a lo suyo, se respetan los
// permisos y el quinto intento fallido bloquea el inicio de sesión (RNF-04).
import { CUENTAS } from '../support/datos';

function intentar(clave) {
  return cy.request({
    method: 'POST',
    url: '/auth/login',
    body: { email: CUENTAS.solicitante, password: clave },
    failOnStatusCode: false,
  });
}

describe('CA-09 — A – B (Aplicación – Autenticación)', () => {
  let solicitante;

  before(() => {
    cy.seedTest();
  });

  it('CA-09 paso 1: el solicitante inicia sesión con su rol', () => {
    cy.login(CUENTAS.solicitante).then((token) => {
      solicitante = token;
      cy.api(token, 'GET', '/auth/me').its('body.role').should('eq', 'requester');
    });
  });

  it('CA-09 paso 2: con el token del solicitante, crear una central responde 403', () => {
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

  it('CA-09 paso 3: una contraseña incorrecta responde 401 sin decir cuál dato falló', () => {
    intentar('Equivocada123').then((respuesta) => {
      expect(respuesta.status).to.eq(401);
      expect(respuesta.body.message).to.eq('El correo y la contraseña no coinciden.');
    });
  });

  it('CA-09 paso 4: al quinto intento fallido el inicio de sesión se bloquea', () => {
    intentar('Equivocada123');
    intentar('Equivocada123');
    intentar('Equivocada123');
    intentar('Equivocada123').then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(403);
      expect(respuesta.body.message).to.eq(
        'Demasiados intentos. Intenta de nuevo en unos minutos.',
      );
    });
  });
});
