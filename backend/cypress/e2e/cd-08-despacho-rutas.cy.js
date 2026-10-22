// CD-08 — F – J: el Despacho con Rutas y geovallas reales calcula el corredor
// y lo bloquea cuando hay una geovalla. Simulación sin arrancar (no se confirma
// carga). Sale de la central B (ver `activarCentralB`) y, como preparación, se
// le registra un segundo dron (WG-198-003): así, en el paso 3, hay un dron
// libre y el rechazo solo puede venir de la geovalla.
import { CUENTAS, urgenciaLibre } from '../support/datos';

const GEOVALLA = {
  name: 'PRUEBA-CD-08 Geovalla del destino',
  reason: 'Prueba de integración CD-08',
  polygon: {
    type: 'Polygon',
    coordinates: [
      [
        [-73.244, 10.486],
        [-73.236, 10.486],
        [-73.236, 10.494],
        [-73.244, 10.494],
        [-73.244, 10.486],
      ],
    ],
  },
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
            identifier: 'WG-198-003',
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

  it('CD-08 paso 1: el pedido sin geovallas en su camino queda pendiente de carga a 100 m', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        expect(pedido.status).to.eq(201);
        cy.api(
          despachador,
          'POST',
          `/orders/${pedido.body.id}/authorize`,
          {},
        ).then((respuesta) => {
          expect(respuesta.status).to.eq(201);
          expect(respuesta.body.status).to.eq('pending_load');
          expect(respuesta.body.assignment.route.altitudeM).to.eq(100);
        });
      },
    );
  });

  it('CD-08 paso 2: la geovalla alrededor de 10.4900, -73.2400 se guarda', () => {
    cy.api(operador, 'POST', '/geofences', GEOVALLA).then((respuesta) => {
      expect(respuesta.status).to.eq(201);
      geovalla = respuesta.body.id;
    });
  });

  it('CD-08 paso 3: autorizar el segundo pedido se rechaza (409)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaLibre({ latitude: 10.49, longitude: -73.24 }),
    ).then((pedido) => {
      expect(pedido.status).to.eq(201);
      cy.api(
        despachador,
        'POST',
        `/orders/${pedido.body.id}/authorize`,
        {},
      ).then((respuesta) => {
        expect(respuesta.status).to.eq(409);
        expect(respuesta.body.message).to.eq(
          'Ningún dron de la central puede cumplir esta salida.',
        );
      });
    });
  });
});
