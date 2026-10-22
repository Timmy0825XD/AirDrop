// CD-10 — C – G: Pedidos con el Almacenamiento real (bucket privado
// «prescriptions») guarda solo imágenes válidas de la fórmula. El inventario
// es el de `seed:test` (Insulina glargina bajo fórmula en la central A).
import { CUENTAS, urgenciaConFormula } from '../support/datos';

const KB = 1024;
const MB = 1024 * KB;

describe('CD-10 — C – G (Pedidos – Almacenamiento de fórmulas)', () => {
  let solicitante;
  let despachador;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachador = token));
  });

  it('CD-10 paso 1: con una imagen JPEG de 300 KB el pedido se crea y la imagen queda en el bucket', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaConFormula(300 * KB),
    ).then((pedido) => {
      expect(pedido.status).to.eq(201);
      // El despachador la lee de vuelta desde el bucket privado.
      cy.request({
        url: `/orders/${pedido.body.id}/prescription`,
        headers: { Authorization: `Bearer ${despachador}` },
        encoding: 'binary',
      }).then((imagen) => {
        expect(imagen.status).to.eq(200);
        expect(imagen.headers['content-type']).to.contain('image/jpeg');
        expect(imagen.body.length).to.eq(300 * KB);
      });
    });
  });

  it('CD-10 paso 2: rechaza una imagen de 3 MB (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaConFormula(3 * MB),
    ).then((respuesta) => {
      cy.log(`Respuesta real: ${respuesta.status}`);
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'La imagen de la fórmula debe pesar hasta 2 MB.',
      );
    });
  });

  it('CD-10 paso 3: rechaza un archivo PDF (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaConFormula(100 * KB, 'application/pdf'),
    ).then((respuesta) => {
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'La fórmula debe ser una imagen JPEG o PNG.',
      );
    });
  });
});
