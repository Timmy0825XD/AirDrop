// CA-05 — B – D (ascendente): el registro y el inicio de sesión sin verificar
// mandan el código de verificación. En desarrollo, sin Brevo configurado, el
// servidor escribe el código en su log (OtpDeliveryService) y la tarea
// `ultimoOtp` lo lee de ahí: es el mismo código que llegaría al correo.
import { solicitanteNuevo } from '../support/datos';

describe('CA-05 — B – D (Autenticación – Correo)', () => {
  const persona = solicitanteNuevo();
  let primerCodigo;

  before(() => {
    cy.seedTest();
  });

  it('CA-05 paso 1: el registro deja la cuenta sin verificar y envía un código de 6 dígitos', () => {
    cy.request({ method: 'POST', url: '/auth/register', body: persona, failOnStatusCode: false }).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        cy.task('ultimoOtp').then((codigo) => {
          expect(codigo).to.match(/^\d{6}$/);
          primerCodigo = codigo;
        });
      },
    );
  });

  it('CA-05 paso 2: iniciar sesión sin verificar responde 403 y envía un código nuevo', () => {
    cy.request({
      method: 'POST',
      url: '/auth/login',
      body: { email: persona.email, password: persona.password },
      failOnStatusCode: false,
    }).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(403);
      expect(JSON.stringify(respuesta.body)).to.contain('verificar');
      cy.task('ultimoOtp').then((codigo) => {
        expect(codigo).to.match(/^\d{6}$/);
        expect(codigo, 'es un código nuevo').not.to.eq(primerCodigo);
      });
    });
  });

  it('CA-05 paso 3: con el código nuevo la cuenta queda activa', () => {
    cy.task('ultimoOtp').then((codigo) => {
      cy.request({
        method: 'POST',
        url: '/auth/verify-otp',
        body: { email: persona.email, code: codigo },
        failOnStatusCode: false,
      }).then((respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        expect(respuesta.body.accessToken).to.be.a('string');
      });
    });
  });

  it('CA-05 paso 4: el inicio de sesión entrega el token con el rol de solicitante', () => {
    cy.request('POST', '/auth/login', {
      email: persona.email,
      password: persona.password,
    }).then((respuesta) => {
      expect(respuesta.status).to.be.oneOf([200, 201]);
      cy.api(respuesta.body.accessToken, 'GET', '/auth/me')
        .its('body.role')
        .should('eq', 'requester');
    });
  });
});
