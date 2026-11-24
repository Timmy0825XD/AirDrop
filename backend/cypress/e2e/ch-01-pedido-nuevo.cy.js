// CH-01 — Interfaz – Inventario – Pedidos – BD (pedido nuevo, valores V1):
// crear la urgencia y ver su estado en el seguimiento, sin mapa.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CH-01 — Pedido nuevo (V1)', () => {
  let solicitante;
  let pedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
  });

  it('CH-01 paso 1: el catálogo muestra Acetaminofén 500 mg', () => {
    cy.api(solicitante, 'GET', '/orders/catalog').then((respuesta) => {
      const lista = respuesta.body.items ?? respuesta.body;
      expect(lista.map((i) => i.name)).to.include('Acetaminofén 500 mg');
    });
  });

  it('CH-01 pasos 2 y 3: Pedidos valida y guarda la urgencia como recibida con prioridad alta', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
        expect(respuesta.body.priority).to.eq('high');
        pedido = respuesta.body.id;
      },
    );
  });

  it('CH-01 paso 4: el seguimiento muestra «recibido» sin dron asignado', () => {
    cy.api(solicitante, 'GET', `/orders/${pedido}`).then((respuesta) => {
      expect(respuesta.body.status).to.eq('received');
      expect(respuesta.body.droneId).to.eq(null);
    });
  });

  it('CH-01 paso 5: el mapa no se habilita porque no hay vuelo', () => {
    cy.api(solicitante, 'GET', `/telemetry/orders/${pedido}`).then((respuesta) => {
      const sinVuelo = respuesta.status >= 400 || respuesta.body == null || respuesta.body.position == null;
      expect(sinVuelo, `respuesta ${respuesta.status}`).to.eq(true);
    });
  });
});
