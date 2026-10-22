// CD-06 — C – F: Pedidos autoriza con el Despacho real y sus reglas.
// Flota, rutas y simulación no se reemplazan: corren con los datos fijos de
// `seed:test`. El despacho sale de la central B (ver `activarCentralB`). El
// almacenamiento de la fórmula es el real. Anotar en Observaciones.
import {
  CUENTAS,
  hoyEnColombia,
  urgenciaConFormula,
  urgenciaLibre,
} from '../support/datos';

describe('CD-06 — C – F (Pedidos – Despacho)', () => {
  let solicitante;
  let despachador;
  let operador;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorB).then((token) => (despachador = token));
    cy.login(CUENTAS.operador).then((token) => (operador = token));
    cy.then(() => cy.activarCentralB(operador, despachador));
  });

  it('CD-06 paso 1: autoriza un pedido de venta libre y queda pendiente de carga', () => {
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
          expect(respuesta.body.assignment.identifier).to.eq('WG-198-002');
        });
      },
    );
  });

  it('CD-06 paso 2: rechaza un pedido bajo fórmula sin verificar la fórmula (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaConFormula(50 * 1024),
    ).then((pedido) => {
      expect(pedido.status).to.eq(201);
      cy.api(
        despachador,
        'POST',
        `/orders/${pedido.body.id}/authorize`,
        {},
      ).then((respuesta) => {
        expect(respuesta.status).to.eq(400);
        expect(respuesta.body.message).to.eq(
          'Debes verificar la fórmula antes de autorizar.',
        );
      });
    });
  });

  it('CD-06 paso 3: rechaza un pedido programado antes de su fecha (400)', () => {
    const hoy = hoyEnColombia();
    cy.api(solicitante, 'POST', '/orders/plans', {
      medicationName: 'Acetaminofén 500 mg',
      saleType: 'over_the_counter',
      quantity: 1,
      frequency: 'weekly',
      startDate: hoy,
      address: 'Calle 16 No. 19-35, Valledupar',
      latitude: 10.4802,
      longitude: -73.2475,
    }).then((plan) => {
      expect(plan.status).to.eq(201);
      cy.api(solicitante, 'GET', '/orders/mine').then((mios) => {
        const futuro = mios.body.find(
          (pedido) =>
            pedido.planId === plan.body.id && pedido.scheduledFor > hoy,
        );
        expect(futuro, 'entrega programada de la próxima semana').to.exist;
        cy.api(despachador, 'POST', `/orders/${futuro.id}/authorize`, {}).then(
          (respuesta) => {
            expect(respuesta.status).to.eq(400);
            expect(respuesta.body.message).to.eq(
              'Este pedido programado todavía no llega a su fecha.',
            );
          },
        );
      });
    });
  });
});
