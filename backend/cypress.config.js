// Pruebas de integración (Segunda Parte, sección 2.4). Corren sobre la API
// real en http://localhost:3000: la app Flutter web pinta en un lienzo y
// Cypress no puede leer sus botones, así que se usan las mismas peticiones.
//
// Antes de correr:
//   1. Servidor local con el log en un archivo y sin Brevo, para leer los OTP:
//        BREVO_API_KEY= pnpm start:dev > servidor.log 2>&1
//   2. pnpm test:int   (OTP_LOG apunta al log si no está en backend/servidor.log)
// Al terminar, POST /control/reset deja el escenario de la demo como la semilla.
const { execSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const { defineConfig } = require('cypress');

/** Lee ADMIN_EMAIL y ADMIN_PASSWORD del .env para el reloj y el reinicio. */
function leerEnv() {
  const env = {};
  const archivo = path.join(__dirname, '.env');
  if (!fs.existsSync(archivo)) return env;
  for (const linea of fs.readFileSync(archivo, 'utf8').split(/\r?\n/)) {
    const m = linea.match(/^([A-Z_0-9]+)=(.*)$/);
    if (m) env[m[1]] = m[2].replace(/^"|"$/g, '');
  }
  return env;
}

const ENV = leerEnv();
const OTP_LOG = process.env.OTP_LOG || path.join(__dirname, 'servidor.log');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on) {
      on('task', {
        // Datos de prueba (seed:test) y la red de la demo suspendida, para que
        // las urgencias de prueba solo se ofrezcan a las centrales PRUEBA-.
        seedTest() {
          execSync('corepack pnpm seed:test', {
            cwd: __dirname,
            stdio: 'inherit',
            env: {
              ...process.env,
              AISLAR_DEMO: '1',
              // La siembra puede usar otra conexión (p. ej. el session pooler).
              ...(process.env.SEED_DATABASE_URL
                ? { DATABASE_URL: process.env.SEED_DATABASE_URL }
                : {}),
            },
          });
          return null;
        },
        // Credenciales del administrador del .env (no se muestran en el log).
        adminCreds() {
          return { email: ENV.ADMIN_EMAIL, password: ENV.ADMIN_PASSWORD };
        },
        // Último código OTP que el servidor escribió en su log (solo en
        // desarrollo, cuando Brevo no está configurado).
        ultimoOtp() {
          const log = fs.readFileSync(OTP_LOG, 'utf8');
          const codigos = [
            ...log.matchAll(/OTP \w+ \(solo desarrollo\/pruebas\): (\d{6})/g),
          ];
          return codigos.length ? codigos[codigos.length - 1][1] : null;
        },
      });
    },
    baseUrl: 'http://localhost:3000',
    specPattern: ['cypress/e2e/**/*.cy.js', 'cypress/aceptacion/**/*.cy.js'],
    // CA-04 paso 4 y CD-09 paso 3 necesitan el servidor sin Redis, y la
    // aceptación (Swagger) es otro nivel de pruebas: se corren aparte.
    excludeSpecPattern: [
      ...(process.env.REDIS_CAIDO ? [] : ['cypress/e2e/redis-caido/**']),
      ...(process.env.ACEPTACION ? [] : ['cypress/aceptacion/**']),
    ],
    supportFile: 'cypress/support/e2e.js',
    video: false,
    screenshotOnRunFailure: false,
    defaultCommandTimeout: 15000,
    responseTimeout: 60000,
    execTimeout: 300000,
    taskTimeout: 300000,
  },
});
