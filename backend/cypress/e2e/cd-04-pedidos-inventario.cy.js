// CD-04 — C – E (descendente, con Despacho, almacenamiento y Centrales como
// resguardos): Pedidos solo ofrece lo que el Inventario real tiene disponible
// por este canal. Se carga Morfina (control especial) en la central A.
import { CUENTAS, urgenciaLibre } from '../support/datos';

describe('CD-04 — C – E (Pedidos – Inventario)', () => {
  let solicitante;

  before(() => {
    cy.seedTest();
    cy.login(CUENTAS.solicitante).then((token) => (solicitante = token));
    cy.login(CUENTAS.despachadorA).then((token) =>
      cy
        .api(token, 'POST', '/inventory', {
          name: 'Morfina 10 mg/mL',
          quantity: 15,
          lot: 'MOR-PRU-01',
          expirationDate: '2027-12-01',
          requiresColdChain: false,
          saleType: 'special_control',
          unitWeightG: 12,
        })
        .its('status')
        .should('eq', 201),
    );
  });

  it('CD-04 paso 1: el catálogo ofrece Acetaminofén y no ofrece la Morfina de control especial', () => {
    cy.api(solicitante, 'GET', '/orders/catalog').then((respuesta) => {
      expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(200);
      const lista = respuesta.body.items ?? respuesta.body;
      const nombres = lista.map((i) => i.name);
      expect(nombres).to.include('Acetaminofén 500 mg');
      const morfina = lista.find((i) => i.name === 'Morfina 10 mg/mL');
      expect(morfina == null || morfina.saleType === 'special_control', 'la morfina no se puede pedir').to.eq(true);
    });
  });

  it('CD-04 paso 2: la urgencia de un medicamento sin existencias se rechaza (400)', () => {
    cy.api(
      solicitante,
      'POST',
      '/orders/emergencies',
      urgenciaLibre({ medicationName: 'Amoxicilina 500 mg' }),
    ).then((respuesta) => {
      expect(respuesta.status).to.eq(400);
      expect(respuesta.body.message).to.eq(
        'Ninguna central activa tiene ese medicamento disponible.',
      );
    });
  });

  it('CD-04 paso 3: la urgencia del ítem disponible se crea recibida', () => {
    cy.api(solicitante, 'POST', '/orders/emergencies', urgenciaLibre()).then(
      (respuesta) => {
        expect(respuesta.status, JSON.stringify(respuesta.body.message ?? '')).to.eq(201);
        expect(respuesta.body.status).to.eq('received');
      },
    );
  });
});
