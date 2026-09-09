# Backend

API NestJS de AirDrop. Convenciones: [AGENTS.md](AGENTS.md).

Postgres vive en **Supabase** (una BD para el equipo). No usamos Docker.

## Requisitos

- Node.js 22+
- pnpm (`corepack enable`)
- Proyecto en [supabase.com](https://supabase.com) (gratis)

## Credenciales (una vez)

1. En Supabase: **Project Settings → Database**.
2. Copia la URI de **Session pooler, puerto 5432** (no uses Transaction pooler / 6543: TypeORM no se lleva bien con ese modo).
3. En esta carpeta:

```bash
cd backend
cp .env.example .env
```

4. En `.env`, pega la URI en `DATABASE_URL` (usuario, clave y host los trae esa URI). Cambia `JWT_SECRET`.

No subas `.env` a GitHub. Compártelo por un canal privado del equipo.

## Arranque

```bash
cd backend
pnpm install
pnpm start:dev
```

La API queda en `http://localhost:3000`. El primer arranque crea tablas (`synchronize` en desarrollo) y un admin (`ADMIN_EMAIL` / `ADMIN_PASSWORD`).

Cuando usen geovallas: en el SQL Editor de Supabase, `CREATE EXTENSION IF NOT EXISTS postgis;`.

## Auth (HU-01 a HU-05)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/auth/register` | no |
| POST | `/auth/verify-otp` | no |
| POST | `/auth/resend-otp` | no |
| POST | `/auth/login` | no |
| POST | `/auth/logout` | JWT |
| POST | `/auth/forgot-password` | no |
| POST | `/auth/reset-password` | no |
| GET | `/auth/me` | JWT |

En desarrollo el OTP se imprime en el log. Nombre máximo 40, correo 50, celular **10 dígitos** colombianos.

## Centrales (HU-06)

| Método | Ruta | Auth |
| --- | --- | --- |
| POST | `/hubs` | JWT despachador |
| GET | `/hubs/me` | JWT despachador |

La central queda en `pending_approval`. El admin no aprueba todavía (HU-07). En desarrollo el aviso al admin se imprime en el log.

## Flota (HU-11)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/fleet/models` | JWT operador o admin |
| POST | `/fleet/drones` | JWT operador |
| GET | `/fleet/drones?hubId=` | JWT operador o admin |

Al arrancar se siembra el `DroneModel` Wingcopter 198 (150 km/h, 6 kg, 110 km). El dron nace en `available`. Identificador máximo 32 caracteres.

## Pruebas

```bash
pnpm test
pnpm test:e2e
```

El e2e usa el mismo `DATABASE_URL`. **No** borra el esquema (no pongas `E2E_DROP_SCHEMA=true` contra la BD del equipo).

`pnpm-workspace.yaml` aquí no es un monorepo de varios paquetes: pnpm 11 guarda ahí la política de scripts de instalación.
