// Pruebas de integración (Segunda Parte, sección 2.4). Corren sobre la API
// real en http://localhost:3000: la app Flutter web pinta en un lienzo y
// Cypress no puede leer sus botones, así que se usan las mismas peticiones.
const { execSync } = require('node:child_process');
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', {
        // Datos de la sección 2.3 de la guía: limpia y vuelve a crear.
        seedTest() {
          execSync('corepack pnpm seed:test', {
            cwd: __dirname,
            stdio: 'inherit',
          });
          return null;
        },
      });
    },
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    // El paso 3 de CD-09 necesita el servidor sin Redis: se corre aparte.
    excludeSpecPattern: process.env.REDIS_CAIDO
      ? []
      : ['cypress/e2e/redis-caido/**'],
    supportFile: 'cypress/support/e2e.js',
    video: false,
    screenshotOnRunFailure: false,
    defaultCommandTimeout: 15000,
    responseTimeout: 60000,
    execTimeout: 300000,
  },
});
