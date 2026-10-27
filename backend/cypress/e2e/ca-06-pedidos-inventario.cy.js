// CA-06 — C – E (ascendente): el catálogo del solicitante sale del inventario
// de las centrales activas y crear la urgencia no descuenta existencias.
// Inventario de la central A de `seed:test` (Acetaminofén 500 mg, 120 u.).
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CA-06 — C – E (Pedidos – Inventario)', () => {
  let solicitante;
  let despachador;
  let pedido;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) => (despachador = token));
  });

  /** Unidades de Acetaminofén en el inventario de la central A. */
  function unidadesEnCentralA() {
    return cy.api(despachador, 'GET', '/inventory').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      const item = respuesta.body.find(
        (fila) => fila.name === 'Acetaminofén 500 mg',
      );
      return item.quantity;
    });
  }

  it('CA-06 paso 1: el catálogo muestra Acetaminofén 500 mg con 120 unidades en la central', () => {
    cy.api(solicitante, 'GET', '/orders/catalog').then((catalogo) => {
      expect(catalogo.status).to.eq(200);
      expect(catalogo.body.map((fila) => fila.name)).to.include(
        'Acetaminofén 500 mg',
      );
    });
    // El catálogo del solicitante no muestra cantidades; las unidades se leen
    // del inventario de la central.
    unidadesEnCentralA().should('eq', 120);
  });

  it('CA-06 paso 2: la urgencia se crea recibida y con prioridad alta', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
        expect(respuesta.body.priority).to.eq('high');
        pedido = respuesta.body.id;
      },
    );
  });

  it('CA-06 paso 3: «Mis pedidos» muestra el pedido recibido, sin dron', () => {
    cy.api(solicitante, 'GET', '/orders/mine').then((respuesta) => {
      expect(respuesta.status).to.eq(200);
      const fila = respuesta.body.find((p) => p.id === pedido);
      expect(fila.status).to.eq('received');
      expect(fila.droneId).to.be.null;
    });
  });

  it('CA-06 paso 4: el inventario sigue en 120 (se descuenta al confirmar la carga)', () => {
    unidadesEnCentralA().should('eq', 120);
  });
});
