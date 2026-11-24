// CA-03 — F – J (ascendente): el despacho solo asigna un dron cuando hay un
// corredor libre de zonas. Sale de la central B con dos drones (AD-RPL-08 y
// AD-RPL-09, que se registra aquí); la geovalla del paso 2 rodea la central
// B a 1,5 km, así que ningún corredor puede salir de ella.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-03 — F – J (Despacho – Rutas y geovallas)', () => {
  let solicitante;
  let despachador;
  let operador;
  let segundo;
  let geovalla;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador)).then(
      (centralB) => {
        cy.api(operador, 'GET', '/fleet/models').then((modelos) => {
          const garza = modelos.body.find((m) => m.name === 'Garza');
          cy.api(operador, 'POST', '/fleet/drones', {
            identifier: 'AD-RPL-09',
            droneModelId: garza.id,
            hubId: centralB,
          })
            .its('status')
            .should('eq', 201);
        });
      },
    );
    cy.then(() =>
      cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()),
    ).then((pedido) => (segundo = pedido.body.id));
  });

  after(() => {
    if (geovalla) cy.api(operador, 'DELETE', `/geofences/${geovalla}`);
  });

  it('CA-03 paso 1: sin zonas en el camino, el pedido queda pendiente de carga con su corredor', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        cy.api(despachador, 'POST', `/orders/${pedido.body.id}/authorize`, {}).then(
          (respuesta) => {
            expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
            expect(respuesta.body.status).to.eq('pending_load');
            expect(respuesta.body.assignment.route).to.exist;
            cy.log(JSON.stringify(respuesta.body.assignment.route).slice(0, 400));
          },
        );
      },
    );
  });

  it('CA-03 paso 2: el operador crea una geovalla en anillo alrededor del destino', () => {
    // Un círculo de 900 m centrado entre la central B y el destino deja el
    // destino adentro sin cubrir la central (una geovalla no puede cubrirla).
    cy.api(operador, 'POST', '/geofences', {
      name: 'PRUEBA-CA-03 Zona restringida',
      reason: 'Prueba de integración CA-03',
      category: 'other',
      shape: 'circle',
      center: { latitude: 10.366, longitude: -73.153 },
      radiusM: 900,
    }).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
      geovalla = respuesta.body.id;
    });
  });

  it('CA-03 paso 3: con el destino dentro de la geovalla, el segundo pedido no recibe dron y se rechaza', () => {
    cy.api(despachador, 'POST', `/orders/${segundo}/authorize`, {}).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        expect(respuesta.body.status).to.eq('rejected');
        expect(respuesta.body.droneId).to.eq(null);
      },
    );
  });

  it('CA-03 paso 4: el pedido queda rechazado con el motivo y sin dron', () => {
    cy.api(solicitante, 'GET', `/orders/${segundo}`).then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
      expect(respuesta.body.status).to.eq('rejected');
      expect(respuesta.body.droneId).to.eq(null);
      cy.log(`Motivo: ${respuesta.body.statusReason}`);
      expect(respuesta.body.statusReason).to.be.a('string');
    });
  });
});
