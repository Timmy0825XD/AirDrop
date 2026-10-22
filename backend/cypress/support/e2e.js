// Comandos comunes de las pruebas de integración.

// Contraseña de las cuentas @prueba.co que crea `pnpm seed:test`.
const TEST_PASSWORD = 'Password123';

/**
 * Deja la base con los datos de la sección 2.3 de la guía (central A con
 * WG-198-001 disponible, central B con WG-198-002 en mantenimiento,
 * despachadores, operador, solicitante e inventario). Cada caso arranca así.
 */
Cypress.Commands.add('seedTest', () => {
  cy.task('seedTest', null, { timeout: 300000 });
});

/** Inicia sesión por la API y devuelve el accessToken (sin mostrar la clave). */
Cypress.Commands.add('login', (email) => {
  cy.log(`Iniciar sesión: ${email}`);
  return cy
    .request({
      method: 'POST',
      url: '/auth/login',
      body: { email, password: TEST_PASSWORD },
      log: false,
    })
    .its('body.accessToken', { log: false });
});

/**
 * La central A de los datos de prueba (10.4631, -73.2532) queda dentro de la
 * geovalla de la demo «Zona de eventos Parque de la Leyenda»: ningún corredor
 * sale de ahí. Los despachos salen de la central B, con WG-198-002 puesto en
 * disponible (seed:test lo deja en mantenimiento). Devuelve el id de la
 * central B.
 */
Cypress.Commands.add('activarCentralB', (operador, despachadorB) => {
  return cy.api(despachadorB, 'GET', '/auth/me').then((yo) => {
    const centralB = yo.body.hubIds[0];
    cy.api(operador, 'GET', `/fleet/drones?hubId=${centralB}`).then(
      (drones) => {
        const dron = drones.body.find((d) => d.identifier === 'WG-198-002');
        cy.api(operador, 'PATCH', `/fleet/drones/${dron.id}/status`, {
          status: 'available',
        })
          .its('status')
          .should('eq', 200);
      },
    );
    return cy.wrap(centralB, { log: false });
  });
});

/** Consulta el pedido cada 3 s hasta ver `estado` (máximo `intentos`). */
Cypress.Commands.add('esperarEstado', (token, id, estado, intentos) => {
  return cy.api(token, 'GET', `/orders/${id}`).then((respuesta) => {
    if (respuesta.body.status === estado || intentos <= 1) {
      expect(respuesta.body.status, `estado del pedido`).to.eq(estado);
      return cy.wrap(respuesta.body, { log: false });
    }
    cy.wait(3000, { log: false });
    return cy.esperarEstado(token, id, estado, intentos - 1);
  });
});

/**
 * Recorre el flujo real hasta «en espera de entrega»: urgencia del
 * solicitante, autorización y confirmación de carga en la central B, y vuelo
 * hasta el aterrizaje (unos 2 minutos, necesita Redis). Devuelve el id.
 */
Cypress.Commands.add(
  'pedidoEnEsperaDeEntrega',
  (solicitante, despachador, urgencia) => {
    return cy
      .api(solicitante, 'POST', '/orders/emergencies', urgencia)
      .then((pedido) => {
        const id = pedido.body.id;
        cy.api(despachador, 'POST', `/orders/${id}/authorize`, {})
          .its('body.status')
          .should('eq', 'pending_load');
        cy.api(despachador, 'POST', `/orders/${id}/confirm-load`)
          .its('status')
          .should('eq', 201);
        cy.log('Vuelo en curso: esperando el aterrizaje');
        cy.esperarEstado(solicitante, id, 'awaiting_delivery', 100);
        return cy.wrap(id, { log: false });
      });
  },
);

/** Petición autenticada que no falla por el código HTTP: el caso lo revisa. */
Cypress.Commands.add('api', (token, method, url, body) => {
  return cy.request({
    method,
    url,
    body,
    headers: { Authorization: `Bearer ${token}` },
    failOnStatusCode: false,
  });
});
