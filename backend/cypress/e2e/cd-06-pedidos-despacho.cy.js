// CD-06 — C – F: Pedidos autoriza con el Despacho real y sus reglas.
// Flota, rutas y simulación no se reemplazan: corren con los datos fijos de
// `seed:test`. El despacho sale de la central B (ver `activarCentralB`). El
// almacenamiento de la fórmula es el real. Anotar en Observaciones.
import {
  CERCA_DE_A,
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
        expect(pedido.status, JSON.stringify(pedido.body.message ?? '')).to.eq(201);
        cy.api(
          despachador,
          'POST',
          `/orders/${pedido.body.id}/authorize`,
          {},
        ).then((respuesta) => {
          expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
          expect(respuesta.body.status).to.eq('pending_load');
          expect(respuesta.body.assignment.identifier).to.eq('AD-RPL-08');
        });
      },
    );
  });

  it('CD-06 paso 2: rechaza un pedido bajo fórmula sin verificar la fórmula (400)', () => {
    // La insulina es de la central A y viaja en frío: su dron AD-RPL-07 lleva
    // el compartimento y la urgencia se pide cerca de A, así entra a su cola.
    cy.login(CUENTAS.despachadorA).then((despachadorA) =>
      cy.api(despachadorA, 'GET', '/auth/me').then((yo) =>
        cy.api(operador, 'GET', `/fleet/drones?hubId=${yo.body.hubIds[0]}`).then((drones) => {
          const dron = drones.body.find((d) => d.identifier === 'AD-RPL-07');
          cy.api(operador, 'PATCH', `/fleet/drones/${dron.id}/cold-compartment`, { installed: true });
          cy.api(solicitante, 'POST', '/orders/emergencies', {
            ...urgenciaConFormula(50 * 1024),
            ...CERCA_DE_A,
          }).then((pedido) => {
            expect(pedido.status, JSON.stringify(pedido.body.message ?? '')).to.eq(201);
            cy.api(despachadorA, 'POST', `/orders/${pedido.body.id}/authorize`, {}).then(
              (respuesta) => {
                expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(400);
                expect(respuesta.body.message).to.eq(
                  'Debes verificar la fórmula antes de autorizar.',
                );
              },
            );
          });
        }),
      ),
    );
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
      expect(plan.status, JSON.stringify(plan.body.message ?? '')).to.eq(201);
      cy.api(solicitante, 'GET', '/orders/mine').then((mios) => {
        const futuro = mios.body.find(
          (pedido) =>
            pedido.planId === plan.body.id && pedido.scheduledFor > hoy,
        );
        expect(futuro, 'entrega programada de la próxima semana').to.exist;
        cy.api(despachador, 'POST', `/orders/${futuro.id}/authorize`, {}).then(
          (respuesta) => {
            expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(400);
            expect(respuesta.body.message).to.eq(
              'Este pedido programado todavía no llega a su fecha.',
            );
          },
        );
      });
    });
  });
});
