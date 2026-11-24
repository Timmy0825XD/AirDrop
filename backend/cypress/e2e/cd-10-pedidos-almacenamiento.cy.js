// CD-10 — C – G (descendente, con los demás componentes como resguardos):
// Pedidos con el Almacenamiento real (bucket privado «prescriptions») guarda
// solo archivos válidos de la fórmula (RU-25: un PDF o de 1 a 3 fotos JPG o
// PNG, de hasta 5 MB cada uno). La insulina es de la central A y viaja en
// frío: a su dron (AD-RPL-07) se le instala el compartimento.
import { CERCA_DE_A, CUENTAS, urgenciaConFormula } from '../support/datos';

const KB = 1024;
const MB = 1024 * KB;

describe('CD-10 — C – G (Pedidos – Almacenamiento de fórmulas)', () => {
  let solicitante;
  let despachador;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((operador) =>
      cy.api(despachador, 'GET', '/auth/me').then((yo) =>
        cy.api(operador, 'GET', `/fleet/drones?hubId=${yo.body.hubIds[0]}`).then((drones) => {
          const dron = drones.body.find((d) => d.identifier === 'AD-RPL-07');
          cy.api(operador, 'PATCH', `/fleet/drones/${dron.id}/cold-compartment`, { installed: true })
            .its('status')
            .should('eq', 200);
        }),
      ),
    );
  });

  it('CD-10 paso 1: con dos fotos JPG de 300 KB el pedido se crea y las fotos quedan en el bucket', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', {
      ...urgenciaConFormula(300 * KB, 'image/jpeg', 2),
      ...CERCA_DE_A,
    }).then((pedido) => {
      expect(pedido.status, JSON.stringify(pedido.body.message ?? '')).to.eq(201);
      // El despachador lee de vuelta la primera foto desde el bucket privado.
      cy.request({
        url: `/orders/${pedido.body.id}/prescription/0`,
        headers: { Authorization: `Bearer ${despachador}` },
        encoding: 'binary',
      }).then((imagen) => {
        expect(imagen.status).to.eq(200);
        expect(imagen.headers['content-type']).to.contain('image/jpeg');
        expect(imagen.body.length).to.eq(300 * KB);
      });
    });
  });

  it('CD-10 paso 2: rechaza una foto de 6 MB (400)', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', {
      ...urgenciaConFormula(6 * MB),
      ...CERCA_DE_A,
    }).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'Cada archivo de la fórmula debe pesar hasta 5 MB.',
      );
    });
  });

  it('CD-10 paso 3: rechaza un documento de Word (400)', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', {
      ...urgenciaConFormula(
        100 * KB,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      ),
      ...CERCA_DE_A,
    }).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(400);
      expect(JSON.stringify(respuesta.body.message)).to.contain(
        'La fórmula debe ser un PDF o una foto JPG o PNG.',
      );
    });
  });
});
