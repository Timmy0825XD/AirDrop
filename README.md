# AirDrop

Logística aérea médica **simulada** para emergencias y reabastecimiento programado. Decide qué central despacha, qué dron puede cumplir la misión y qué ruta es segura, y si ningún dron es viable propone una alternativa en lugar de rechazar el pedido.

Caso de estudio: Valledupar y zona cercana. El dron se simula con los parámetros del [Wingcopter 198](https://wingcopter.com/); no hay hardware real ni aplicación web.

## Qué hace

- **Emergencia** (bajo demanda, prioridad máxima) y **reabastecimiento programado**.
- Motor de decisión: elige el dron elegible según carga, alcance y clima, y propone una alternativa si ninguno lo es.
- Rutas con geovallas y vuelo simulado con telemetría en tiempo real.
- Entrega con código de un solo uso. Si no llega en 5 minutos, el dron vuelve con el paquete.
- Cuatro roles: solicitante, despachador, operador de flota y administrador.

## Tecnología

| Parte | Stack |
| --- | --- |
| `frontend/` | Flutter (Android e iOS), Riverpod, go_router, `flutter_map` |
| `backend/` | NestJS, TypeORM, PostgreSQL con PostGIS (Supabase), Redis, Socket.IO |

## Cómo encenderlo

### Requisitos

- Node.js 22+ y pnpm (`corepack enable`)
- Flutter estable con Dart `^3.12` (`flutter doctor` sin errores)
- Un proyecto de [Supabase](https://supabase.com) (base de datos y bucket de fórmulas)
- Redis en ejecución: sin él el reloj de vuelo no arranca
- Cuenta de [Brevo](https://www.brevo.com) para el OTP por correo (opcional en desarrollo: el código se imprime en el log)

### 1. Backend

```bash
cd backend
cp .env.example .env     # completa DATABASE_URL, JWT_SECRET, SUPABASE_* y REDIS_URL
pnpm install
pnpm start:dev
```

La API queda en `http://localhost:3000`. El primer arranque crea las tablas, activa PostGIS, siembra el modelo de dron y el administrador (`ADMIN_EMAIL` / `ADMIN_PASSWORD` del `.env`).

Con el servidor arriba, la documentación interactiva está en `http://localhost:3000/api` (Swagger; usa **Authorize** con el token del login).

Detalle de variables y rutas: [`backend/README.md`](backend/README.md).

### 2. App

```bash
cd frontend
flutter pub get
flutter run
```

La app apunta a `http://10.0.2.2:3000` en el emulador de Android y a `http://localhost:3000` en web y escritorio. En un teléfono físico hay que cambiar la URL en `lib/core/network/api_client.dart`.

### 3. Datos de prueba (opcional)

```bash
cd backend
pnpm seed:test    # centrales PRUEBA-, cuentas @prueba.co, inventario y drones
pnpm seed:clean   # borra todo lo anterior
```

Usa una base **de pruebas**: el script lee el mismo `DATABASE_URL` y se niega a correr con `NODE_ENV=production`. Las cuentas quedan con la contraseña `Password123`.

## Pruebas y calidad

```bash
cd backend
pnpm test         # unitarias (Jest)
pnpm test:e2e     # integración contra la base de datos
pnpm lint:check   # ESLint sin modificar archivos
```

## Variables útiles en pruebas

| Variable | Efecto |
| --- | --- |
| `DELIVERY_WAIT_MS` | Acorta la espera del código de entrega (por defecto 300000 = 5 min) |
| `CORS_ORIGINS` | Orígenes de navegador permitidos, separados por comas |

## Documentación

| Qué buscas | Dónde |
| --- | --- |
| Índice y objetivos del proyecto | [`INDEX.md`](INDEX.md) |
| Reglas de negocio, requisitos y casos de uso | [`context/index.md`](context/index.md) |
| Reglas de implementación | [`AGENTS.md`](AGENTS.md), [`backend/AGENTS.md`](backend/AGENTS.md), [`frontend/AGENTS.md`](frontend/AGENTS.md) |
| Guías de pruebas | [`learning/documentacion/`](learning/documentacion/) |

## Flujo de trabajo

Git Flow con commits convencionales (`tipo(alcance): descripción`). No se trabaja directo en `main` ni `develop`: cada cambio va en su rama y entra por pull request.
