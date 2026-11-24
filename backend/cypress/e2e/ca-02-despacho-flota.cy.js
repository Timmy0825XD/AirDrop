// CA-02 — F – I (ascendente): al autorizar, el despacho elige un dron
// disponible de la flota y, si no queda ninguno que pueda volar, el pedido no
// se asigna: queda reasignado como traslado convencional (RF-18). Sale de la
// central B (ver `activarCentralB`), cuyo único dron es AD-RPL-08.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-02 — F – I (Despacho – Flota)', () => {
  let solicitante;
  let despachador;
  let operador;
  let primero;
  let segundo;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
  });

  it('CA-02 paso 1: al autorizar, el pedido pasa a pendiente de carga', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        primero = pedido.body.id;
        cy.api(despachador, 'POST', `/orders/${primero}/authorize`, {}).then(
          (respuesta) => {
            expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
            expect(respuesta.body.status).to.eq('pending_load');
          },
        );
      },
    );
  });

  it('CA-02 paso 2: la asignación muestra el dron AD-RPL-08, su tipo y por qué se eligió', () => {
    cy.api(despachador, 'GET', `/orders/${primero}/decision`).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
        expect(respuesta.body.trace.outcome).to.eq('assigned');
        const elegido = respuesta.body.trace.hubs
          .flatMap((h) => h.drones)
          .find((d) => d.status === 'chosen');
        expect(elegido.identifier).to.eq('AD-RPL-08');
        expect(elegido.typeName).to.eq('Garza');
      },
    );
  });

  it('CA-02 paso 3: sin otro dron que pueda volar, el segundo pedido queda como traslado convencional', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (pedido) => {
        segundo = pedido.body.id;
        cy.api(despachador, 'POST', `/orders/${segundo}/authorize`, {}).then(
          (respuesta) => {
            expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
            expect(respuesta.body.status).to.eq('reassigned');
            expect(respuesta.body.droneId).to.eq(null);
          },
        );
      },
    );
  });

  it('CA-02 paso 4: la decisión explica que ningún dron de la red puede cumplir la salida', () => {
    cy.api(despachador, 'GET', `/orders/${segundo}/decision`).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
        expect(respuesta.body.trace.outcome).to.eq('conventional');
        expect(respuesta.body.trace.reason).to.contain('Ningún dron');
      },
    );
  });
});
