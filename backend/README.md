# Backend

API NestJS de AirDrop. Convenciones: [AGENTS.md](AGENTS.md). La regla de negocio está en [`../context/index.md`](../context/index.md).

Las tablas de rutas de abajo salen de los controladores de `src/`. Lo que el contexto pide y todavía no existe está en [`../context/producto/pendientes-backend.md`](../context/producto/pendientes-backend.md).

Postgres vive en **Supabase** (una BD para el equipo). No usamos Docker.

## Requisitos

- Node.js 22+
- pnpm (`corepack enable`)
- Proyecto en [supabase.com](https://supabase.com) (gratis): base de datos y bucket privado de fórmulas
- Redis (`REDIS_URL`): sin él el reloj de vuelo no arranca
- Cuenta de [Brevo](https://www.brevo.com) para enviar el OTP por correo

## Credenciales (una vez)

1. En Supabase: **Project Settings → Database**.
2. Copia la URI de **Session pooler, puerto 5432** (no uses Transaction pooler / 6543: TypeORM no se lleva bien con ese modo).
3. En esta carpeta:

```bash
cd backend
cp .env.example .env
```

4. En `.env`, pega la URI en `DATABASE_URL` (usuario, clave y host los trae esa URI). Cambia `JWT_SECRET`.

Otras variables de `.env.example`:

| Variable | Para qué |
| --- | --- |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_FULL_NAME` | Cuenta de administrador que se siembra al arrancar |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Bucket privado `prescriptions` (foto de la fórmula). La clave `service_role` solo vive aquí |
| `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME` | Envío del OTP por correo |
| `REDIS_URL` | Snapshot de telemetría y pub/sub hacia el socket |

No subas `.env` a GitHub. Compártelo por un canal privado del equipo.

## Arranque

```bash
cd backend
pnpm install
pnpm start:dev
```

La API queda en `http://localhost:3000`. El primer arranque crea tablas (`synchronize` en desarrollo), activa PostGIS, crea el bucket de fórmulas, siembra el `DroneModel` y un admin.

El OTP viaja por correo (Brevo). Si Brevo no está configurado y el ambiente no es producción, el código se imprime en el log.

## Autenticación y roles

JWT con expiración de 8 horas (fija en `auth.module.ts`; `JWT_EXPIRES_IN` de `.env.example` hoy no se lee). Cada ruta declara su rol con `@Roles`. Login: 5 intentos y bloqueo de 15 minutos (RNF-04).

## Rutas

### Auth (HU-01 a HU-05)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/auth/register` | no (solo crea solicitantes) |
| POST | `/auth/verify-otp` | no |
| POST | `/auth/resend-otp` | no |
| POST | `/auth/login` | no |
| POST | `/auth/logout` | JWT |
| POST | `/auth/forgot-password` | no |
| POST | `/auth/reset-password` | no |
| GET | `/auth/me` | JWT |
| PATCH | `/auth/me` | JWT |

Nombre máximo 40, correo 50, celular **10 dígitos** colombianos. OTP de registro: 10 minutos; de recuperación: 15.

### Cuentas institucionales (HU-10)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/users` | admin |
| GET | `/users` | admin |
| PATCH | `/users/:id/suspension` | admin |

### Centrales (HU-06, HU-07)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/hubs` | admin |
| GET | `/hubs` | admin u operador (el operador ve las suyas) |
| GET | `/hubs/me` | despachador |
| PATCH | `/hubs/:id/suspension` | admin |

La central la crea el administrador y nace `active`; no hay estado de aprobación pendiente. Editarla no existe todavía (pendiente 8).

### Inventario (HU-09)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/inventory` | despachador |
| GET | `/inventory` | despachador |
| PATCH | `/inventory/:id` | despachador |
| DELETE | `/inventory/:id` | despachador |

### Flota (HU-11 a HU-13)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/fleet/models` | operador o admin |
| GET | `/fleet/drones?hubId=` | operador o admin (el admin hoy recibe 403, pendiente 5) |
| POST | `/fleet/drones` | operador |
| PATCH | `/fleet/drones/:id/status` | operador |
| POST | `/fleet/drones/:id/maintenance` | operador |

Al arrancar se siembra el `DroneModel` Wingcopter 198 (150 km/h, 6 kg, 110 km). El dron nace en `available`. Identificador máximo 32 caracteres. Un dron en misión no cambia de estado.

### Geovallas (HU-14)

Todas del operador de flota.

| Método | Ruta |
| --- | --- |
| POST | `/geofences` |
| GET | `/geofences` |
| PATCH | `/geofences/:id` |
| DELETE | `/geofences/:id` |

### Pedidos (HU-15 a HU-21)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/orders/catalog` | solicitante o despachador |
| GET | `/orders/mine` | solicitante |
| GET | `/orders/origin-hubs` | despachador |
| GET | `/orders/queue` | despachador |
| GET | `/orders/scheduled` | despachador |
| GET | `/orders/pending-load` | despachador |
| GET | `/orders/in-flight` | despachador |
| POST | `/orders/emergencies` | solicitante |
| POST | `/orders/hub-emergencies` | despachador |
| POST | `/orders/plans` | solicitante |
| POST | `/orders/hub-plans` | despachador |
| GET | `/orders/plans` | solicitante o despachador |
| GET | `/orders/plans/:id` | solicitante o despachador |
| POST | `/orders/plans/:id/extend` | solicitante o despachador |
| POST | `/orders/plans/:id/cancel` | solicitante o despachador |
| GET | `/orders/:id` | solicitante o despachador |
| GET | `/orders/:id/prescription` | despachador |
| POST | `/orders/:id/authorize` | despachador (motor de decisión: reserva dron y ruta, no despega) |
| POST | `/orders/:id/confirm-load` | despachador (arranca la simulación) |
| POST | `/orders/:id/reject` | despachador |

### Telemetría (HU-26 a HU-28)

| Canal | Ruta | Auth |
| --- | --- | --- |
| GET | `/telemetry/orders/:id` | solicitante, despachador u operador |
| WebSocket | namespace `/telemetry`, mensaje `subscribe` | JWT en `auth.token` |

El gateway responde `subscribe` con los eventos `subscribed` o `error` (no con ack) y empuja `telemetry`, `order-status` y `alert`. Tick de 2 s en vuelo (RNF-08).

## Lo que todavía no hay

Entrega con código, espera de 5 minutos, retorno y cuarentena; fallback `reasignado`; módulo `Analytics`; vuelos en curso para el operador; pedidos entrantes de una central; verificar el correo nuevo; editar una central. El detalle de cada uno, con el documento que lo pide, está en [`pendientes-backend.md`](../context/producto/pendientes-backend.md).

## Pruebas

```bash
pnpm test
pnpm test:e2e
```

El e2e usa el mismo `DATABASE_URL`. **No** borra el esquema (no pongas `E2E_DROP_SCHEMA=true` contra la BD del equipo).

`pnpm-workspace.yaml` aquí no es un monorepo de varios paquetes: pnpm 11 guarda ahí la política de scripts de instalación.
