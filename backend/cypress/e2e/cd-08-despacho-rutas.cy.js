// CD-08 — F – J: el Despacho con Rutas y geovallas reales calcula el corredor
// y no acepta un destino dentro de una geovalla. Simulación sin arrancar (no se confirma
// carga). Sale de la central B (ver `activarCentralB`) y, como preparación, se
// le registra un segundo dron (AD-RPL-09): así, en el paso 3, hay un dron
// libre y el rechazo solo puede venir de la geovalla.
// El destino prohibido se rechaza al crear la urgencia (400), antes de
// llegar al despacho: ninguna central podría entregarlo.
import { CUENTAS, urgenciaLibre } from '../support/datos';

const GEOVALLA = {
  name: 'PRUEBA-CD-08 Geovalla del destino',
  reason: 'Prueba de integración CD-08',
  category: 'other',
  shape: 'polygon',
  vertices: [
    { latitude: 10.486, longitude: -73.244 },
    { latitude: 10.486, longitude: -73.236 },
    { latitude: 10.494, longitude: -73.236 },
    { latitude: 10.494, longitude: -73.244 },
  ],
};

describe('CD-08 — F – J (Despacho – Rutas y geovallas)', () => {
  let solicitante;
  let despachador;
  let operador;
  let geovalla;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador)).then(
      (centralB) => {
        cy.api(operador, 'GET', '/fleet/models').then((modelos) => {
          cy.api(operador, 'POST', '/fleet/drones', {
            identifier: 'AD-RPL-09',
            droneModelId: modelos.body[0].id,
            hubId: centralB,
          })
            .its('status')
            .should('eq', 201);
        });
      },
    );
  });

  // La geovalla afecta a todas las rutas: se borra siempre al terminar.
  after(() => {
    if (geovalla) {
      cy.api(operador, 'DELETE', `/geofences/${geovalla}`);
    }
  });

  it('CD-08 paso 1: el pedido sin geovallas en su camino queda pendiente de carga con su corredor', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        expect(pedido.status, JSON.stringify(pedido.body.message ?? '')).to.eq(201);
        cy.api(
          despachador,
          'POST',
          `/orders/${pedido.body.id}/authorize`,
          {},
        ).then((respuesta) => {
          expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
          expect(respuesta.body.status).to.eq('pending_load');
          expect(respuesta.body.assignment.route).to.exist;
        });
      },
    );
  });

  it('CD-08 paso 2: la geovalla alrededor de 10.4900, -73.2400 se guarda', () => {
    cy.api(operador, 'POST', '/geofences', GEOVALLA).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
      geovalla = respuesta.body.id;
    });
  });

  it('CD-08 paso 3: la urgencia con destino dentro de la geovalla se rechaza (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaLibre({ latitude: 10.49, longitude: -73.24 }),
    ).then((pedido) => {
      expect(pedido.status, JSON.stringify(pedido.body.message ?? '')).to.eq(400);
      expect(pedido.body.message).to.eq(
        'El destino está dentro de una zona prohibida para drones. Elige otro punto de entrega.',
      );
    });
  });
});
