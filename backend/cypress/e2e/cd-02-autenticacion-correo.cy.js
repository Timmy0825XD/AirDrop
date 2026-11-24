// CD-02 — B – D (descendente, con Pedidos como resguardo): el código de
// verificación real. Un código que no coincide se rechaza y uno nuevo activa la
// cuenta. El código se lee del log del servidor (ver CA-05).
import { solicitanteNuevo } from '../support/datos';

describe('CD-02 — B – D (Autenticación – Correo)', () => {
  const persona = solicitanteNuevo();

  before(() => {
    cy.seedTest();
  });

  it('CD-02 paso 1: el registro deja la cuenta sin verificar y envía el código', () => {
    cy.request({ method: 'POST', url: '/auth/register', body: persona, failOnStatusCode: false }).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        cy.task('ultimoOtp').should('match', /^\d{6}$/);
      },
    );
  });

  it('CD-02 paso 2: un código que no es el enviado se rechaza (400)', () => {
    cy.task('ultimoOtp').then((codigo) => {
      const otro = String((Number(codigo) + 1) % 1000000).padStart(6, '0');
      cy.request({
        method: 'POST',
        url: '/auth/verify-otp',
        body: { email: persona.email, code: otro },
        failOnStatusCode: false,
      }).then((respuesta) => {
        expect(respuesta.status).to.eq(400);
        expect(respuesta.body.message).to.eq('El código es inválido o ya venció.');
      });
    });
  });

  it('CD-02 paso 3: con un código nuevo la cuenta queda activa', () => {
    cy.request({
      method: 'POST',
      url: '/auth/resend-otp',
      body: { email: persona.email },
      failOnStatusCode: false,
    }).then((reenvio) => {
      expect(reenvio.status, JSON.stringify(reenvio.body.message ?? '')).to.be.oneOf([200, 201]);
      cy.task('ultimoOtp').then((codigo) => {
        cy.request('POST', '/auth/verify-otp', { email: persona.email, code: codigo })
          .its('body.accessToken')
          .should('be.a', 'string');
      });
    });
  });
});
