# AGENTS.md — backend (NestJS)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/principios-de-diseno.md`](../context/principios-de-diseno.md).

## Qué es este lado

Una API **NestJS** (un proceso). Módulos por dominio, no microservicios.

PostgreSQL + PostGIS para lo persistente. Redis para el snapshot de vuelo. Gateway WebSocket para empujar telemetría.

## Paquetes

- Desarrollo y deploy: **pnpm** (`pnpm-lock.yaml`). En `package.json`: campo `packageManager`.
- Un `package.json` dentro de `backend/`, no un workspace pnpm en la raíz del monorepo. Así `npm install` en esta carpeta no rompe.
- No commitear `package-lock.json`.

## Índices (Postgres)

Cada FK, filtro frecuente (`status`, fechas, `hubId`) y lookup único (email) lleva índice. Geometrías PostGIS: GIST. No indexar columnas que no se consultan.

## Modelo de datos (tipos y tamaños)

Columnas con tipo PostgreSQL real y longitud coherente (no `varchar(255)` por defecto). IDs `uuid`; instantes `timestamptz`; flags `boolean`; roles/estados `enum`; decimales `numeric`, nunca `float`. El `MaxLength` del DTO coincide con la columna. Referencia: regla `.cursor/rules/domain-model.mdc`.

## Módulos sugeridos (cuando exista código)

Nombres alineados al glosario:

`Auth`, `Users`, `Hubs`, `Inventory`, `Fleet`, `Geofences`, `Orders`, `Decision`, `Routing`, `Simulation`, `Telemetry`, `Notifications`, `Analytics`.

Un módulo = controllers + services + entities de **ese** tema. El motor de decisión **no** vive dentro de `Simulation`. El reloj de vuelo **no** autoriza pedidos.

## Patrones permitidos

- Services inyectados por el DI de Nest.
- Guards JWT + roles (RNF-03).
- ValidationPipe + DTOs class-validator.
- TypeORM (o Prisma, si el equipo unifica uno): **una** librería de persistencia.
- `EligibilityService`, `RoutePlannerService`, `FallbackService`, `FlightClockService`, `TelemetryPublisher` como clases concretas.

## Patrones no permitidos en el MVP

- Hexagonal completo, CQRS, outbox, sagas, gRPC interno.
- Repositorio genérico abstracto de 4 niveles.
- Cola Redis para “todo”; Redis es telemetría y, si acaso, cache de OTP.

## Motores (lo que hay que poder dibujar en el tablero)

1. **Decision** — entrada: pedido autorizado + drones candidatos. Salida: dron + ruta, o “nadie” → Fallback. Emergencia gana (RF-11).
2. **Routing** — origen hub, destino pedido, geovallas PostGIS. Corredor a altitud fija. Si no hay camino, el dron no es elegible.
3. **Simulation** — intervalo ≤ 2 s (RNF-08). Fases eVTOL y batería distinta en vertical vs crucero. Temperatura solo si el ítem tiene flag de frío.
4. **Telemetry** — escribe Redis, publica WSS. Al cerrar misión, persiste resumen en Postgres.

Calibración: `DroneModel` tipo Wingcopter 198 ([`../context/arquitectura-tecnologica.md`](../context/arquitectura-tecnologica.md)).

## Seguridad

bcrypt, JWT con expiración, rate limit de login (5 intentos), no SQL concatenado, no loguear datos clínicos. Consentimiento en el registro (RNF-05).

## Pruebas

Unitarias de Decision/Routing/Simulation (casos del documento). Un e2e feliz de auth + crear recurso protegido. No exigir 100 % coverage.
