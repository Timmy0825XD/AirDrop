// CD-03 — A – C (descendente): Pedidos real con Inventario, Despacho y
// Almacenamiento con los datos fijos de `seed:test` (no se pueden reemplazar
// por resguardos: el servidor es un solo proceso). La «aplicación» son las
// mismas peticiones que hace la app.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CD-03 — A – C (Aplicación – Pedidos)', () => {
  let solicitante;
  let pedido;

  before(() => {
    cy.seedTest();
  });

  it('CD-03 paso 1: el solicitante inicia sesión', () => {
    cy.login(CUENTAS.solicitante).then((token) => {
      solicitante = token;
      cy.api(token, 'GET', '/auth/me').then((yo) => {
        expect(yo.status).to.eq(200);
        expect(yo.body.role).to.eq('requester');
      });
    });
  });

  it('CD-03 paso 2: la urgencia de venta libre se crea recibida (201)', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
        pedido = respuesta.body.id;
      },
    );
  });

  it('CD-03 paso 3: la urgencia de control especial se rechaza (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaLibre({
        medicationName: 'Morfina 10 mg',
        saleType: 'special_control',
      }),
    ).then((respuesta) => {
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'El control especial no se pide por este canal.',
      );
    });
  });

  it('CD-03 paso 4: «Mis pedidos» muestra solo el pedido recibido', () => {
    cy.api(solicitante, 'GET', '/orders/mine').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body).to.have.length(1);
      expect(respuesta.body[0].id).to.eq(pedido);
      expect(respuesta.body[0].status).to.eq('received');
    });
  });
});
