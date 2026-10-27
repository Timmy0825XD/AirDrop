// CH-02 — Interfaz – Inventario – Pedidos (valores V2): urgencia de un
// medicamento que no tiene existencias en ninguna central activa.
import { CUENTAS, urgenciaLibre } from '../support/datos';

const SIN_EXISTENCIAS = 'Medicamento sin existencias';

describe('CH-02 — Urgencia sin existencias', () => {
  let solicitante;
  let antes;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => {
      solicitante = token;
      cy.api(token, 'GET', '/orders/mine').then(
        (respuesta) => (antes = respuesta.body.length),
      );
    });
  });

  it('CH-02 paso 1: el medicamento no aparece en el catálogo', () => {
    cy.api(solicitante, 'GET', '/orders/catalog').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body.map((fila) => fila.name)).not.to.include(
        SIN_EXISTENCIAS,
      );
    });
  });

  it('CH-02 pasos 2 a 4: la urgencia se rechaza (400) por no haber existencias', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaLibre({ medicationName: SIN_EXISTENCIAS }),
    ).then((respuesta) => {
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'Ninguna central activa tiene ese medicamento disponible.',
      );
    });
  });

  it('CH-02 paso 4: no se creó ningún pedido nuevo', () => {
    cy.api(solicitante, 'GET', '/orders/mine').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      expect(respuesta.body).to.have.length(antes);
    });
  });
});
