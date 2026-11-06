# AGENTS.md — backend (NestJS)

Reglas de esta carpeta. Autoridad de negocio: [`../context/index.md`](../context/index.md). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/diseno/principios.md`](../context/diseno/principios.md).

## Qué es este lado

Una API **NestJS** (un proceso). Módulos por dominio, no microservicios.

PostgreSQL + PostGIS para lo persistente. La foto de la fórmula va a un bucket privado de Supabase Storage (`prescriptions`); Postgres guarda la clave del objeto, no los bytes. Redis para el snapshot de vuelo. Gateway WebSocket para empujar telemetría.

## Contrato

El contrato que el frontend ya consume está verificado contra esta API en el
código (`backend/src/<módulo>`). Si un endpoint se cambia, se actualiza el
frontend en el mismo PR: el frontend muestra los mensajes de error que Nest
define y no los sustituye.

## Paquetes

- Desarrollo y deploy: **pnpm** (`pnpm-lock.yaml`). En `package.json`: campo `packageManager`.
- Un `package.json` dentro de `backend/`, no un workspace pnpm en la raíz del monorepo. Así `npm install` en esta carpeta no rompe.
- No commitear `package-lock.json`.

## Índices (Postgres)

Cada FK, filtro frecuente (`status`, fechas, `hubId`) y lookup único (email) lleva índice. Geometrías PostGIS: GIST. No indexar columnas que no se consultan.

## Modelo de datos (tipos y tamaños)

Columnas con tipo PostgreSQL real y longitud coherente (no `varchar(255)` por defecto). IDs `uuid`; instantes `timestamptz`; flags `boolean`; roles/estados `enum`; decimales `numeric`, nunca `float`. El `MaxLength` del DTO coincide con la columna. Referencia: regla `.cursor/rules/domain-model.mdc`.

## Módulos

Nombres alineados al glosario:

`Auth`, `Users`, `Hubs`, `Inventory`, `Fleet`, `Geofences`, `Orders`, `Decision`, `Routing`, `Simulation`, `Telemetry`, `Notifications`, `Analytics`, `Radar`, `Weather`, `Control`. Existe además `Mail` (envío del OTP por Brevo), que no es un dominio de negocio.

`Analytics` (RF-23, RF-26) vive en `analytics/`: el servicio solo carga datos y `analytics.rules.ts` calcula KPI, metas y el dashboard. `FallbackService` (RF-18) vive en `decision/`. `Radar` (`radar/`) solo lee, para la vista web [`../web/`](../web/AGENTS.md): `GET /radar/snapshot`, `/radar/hubs/:id` y `/radar/flights/:orderId` (solo `admin`) y la sala `radar` del socket (`subscribe-radar`); no revela a quién va una entrega ni el medicamento de una entrega a una persona.

`Weather` (`weather/`) guarda las celdas de clima simulado (RF-32): círculos con duración en hora simulada. Las tiene en memoria porque el reloj de vuelo las lee en cada tick, y Postgres (`weather_cells`) las conserva. Las reglas puras están en `weather.rules.ts`:
- `conditionsAt`: viento a lo largo del tramo y lluvia donde va el dron.
- `corridorWeather`: si se puede volar un corredor y sus km equivalentes.
- `stormPolygon`: la tormenta como polígono de 16 lados.

Quién las usa:
- `Routing`: `loadPolygons` suma las tormentas vigentes a las geovallas. `assertDestinationAllowed` mira solo geovallas.
- `Decision`: `HubEvaluationService` evalúa la ida y el regreso, y pasa km equivalentes al motor.
- `Simulation`: `advanceFlight` recibe `weather`. El crucero termina al llegar al final del corredor, no a una hora fija, y avisa `wind_limit` una vez por tramo.

La consola usa `GET`/`POST /control/weather` y `DELETE /control/weather/:id`; una tormenta hace `recheckRoutes()`.

**Geovallas temporales (RF-36):** son filas de `geofences` con `expiresAt` (hora simulada); las del operador lo tienen en `null` y no vencen. Todo lo que lee geovallas filtra las vigentes con `activeGeofenceSql` (`geofences.rules.ts`) y `simClock.now()`: rutas, radar, la lista del operador y la validación de centrales. Crear una revisa los vuelos en el aire (`recheckRoutes()`) y, como cualquier geovalla, no puede cubrir una central. Un barrido (`simClock.every`) borra las vencidas y publica el evento `geofence` (`created` / `ended`), que llega a la línea de tiempo y a la sala `radar` como `radar-geofence`. La consola usa `GET`/`POST /control/geofences` (5 a 240 min) y `DELETE /control/geofences/:id`, que solo levanta temporales. El reinicio las borra.

**Incidentes (RF-34, RF-35):** `contingency.rules.ts` (`simulation/`) elige el protocolo con `chooseProtocol`: seguir, volver a la central (`RETURN_TO_HUB`) o aterrizar de emergencia en `safeLandingPoint`. En batería crítica el margen es del 5 % (`LANDING_MARGIN_PERCENT`); en los demás, la reserva del 20 %. `FlightClockService.handleIncident` lo aplica cuando el reloj detecta viento sobre el límite, batería crítica o un reruteo `blocked` o `batteryShort`. El protocolo viaja en `FlightProgress.contingency`, para que un reinicio lo recuerde. `FlightIncidentsService` guarda `flight_incidents` y publica el evento `incident` (`radar-incident` y `hub-incident`, sin el medicamento). También deja el paquete en cuarentena (`QuarantineReason.INCIDENT`) y, con `simClock.every`, rescata a los drones `grounded`: los pasa a mantenimiento con un periodo abierto por el sistema (`openedByUserId` nulo). Cuando el dron toca tierra, el reloj llama `onMissionAborted` e `IncidentRedispatchService` (`decision/`) corre `DecisionService.redispatchAfterIncident`. La urgencia a una persona se vuelve a ofrecer (RU-10); la urgencia entre centrales vuelve a su central; el programado sigue RF-18. Un pedido puede tener varias misiones y varias cuarentenas: la misión vigente es la última (`latestMissionByOrder`). `GET /control/incidents` los lista.

**Catálogo de la consola (RF-34, CU-38):** `POST /control/drones/:droneId/incidents` con un `kind` de `CONSOLE_INCIDENT_KINDS`; si el dron no vuela, o es falla del frío sin carga fría, responde 400. `FlightClockService.launchIncident` aplica primero el efecto (`INCIDENT_EFFECTS`: `burnFactor` y `speedFactor` en `FlightProgress`, que `advanceFlight` usa en cada tick; `linkLost` va en la telemetría) y después el protocolo. `FIXED_PROTOCOLS` no miran el alcance. El choque grave (`CRASH`) cae donde va y, tras el rescate, el dron queda fuera de servicio. El dron perdido (`LOST`) queda fuera de servicio de inmediato. En los dos el paquete se pierde (`losesPackage`, `ReturnOutcome.LOST`). Las KPI `incidentRate` (por cada 100 misiones que despegaron) y `groundings` salen de `flight_incidents`.

`Control` (`control/`) es la consola de simulación de la web (RF-31 a RF-40): reloj simulado, eventos, actores simulados, modo caos, línea de tiempo y reinicio del escenario. Sus endpoints `/control/*` son solo `admin` y existen solo con `CONTROL_ENABLED=true`. `Control` no tiene reglas de negocio propias: los actores simulados llaman a los mismos servicios que una persona (`OrdersService`, la confirmación de carga, la validación del código) y los eventos los aplican `Weather`, `Geofences`, `Hubs` y `Simulation`.

**Reloj:** toda regla que dependa de la hora usa `simClock.now()` / `simClock.nowMs()` (`common/clock/sim-clock.ts`, RF-31), nunca `new Date()` ni `Date.now()`. Es un solo objeto en el proceso, no un servicio inyectado, porque también lo leen las validaciones de los DTO. Un barrido periódico usa `simClock.every(ms, tarea)` (ms simulados), no `setInterval`. Las fechas de creación (`@CreateDateColumn`) toman la hora simulada por `SimTimeSubscriber`. Excepción: auth (JWT, OTP, límite de intentos de login) y el consentimiento siguen en hora real. La velocidad la cambia `PUT /control/clock` (admin, `CONTROL_ENABLED`), se guarda en Redis y llega por el socket como el evento `clock` (`{ now, speed, paused }`), también al conectar.

**Línea de tiempo (RF-39):** `TimelineService` escucha los eventos que ya publica `NotificationsService` (estado, cola, alerta) y el reloj, los cuenta en español sin datos de personas, los guarda en Redis (`control:timeline`, tope 200) y los manda a la sala `radar` como `radar-timeline`. `GET /control/timeline?limit=` los lee y `GET /control/alerts` lista las alertas de vuelo abiertas (misión sin `returnedAt`) con la posición del dron. Por eso todo cambio de estado de un pedido pasa por `NotificationsService.statusChanged` (CU-29): si un servicio cambia un estado sin anunciarlo, la consola no lo ve.

**Reinicio (RF-40, CU-41):** `POST /control/reset` (`ScenarioResetService`) devuelve el escenario de `pnpm seed:demo` a su estado inicial, sin crear ni borrar centrales ni cuentas. Si no encuentra las centrales de la semilla responde 409. Pone el reloj en hora real y borra **todo** pedido que sale, llega o está ofrecido a una central de la demo (también los de personas reales), con sus códigos, rutas, misiones, avisos, cuarentenas y planes. Deja los drones en su central con la batería llena y el estado de la semilla, el stock y las geovallas de la semilla, y las centrales activas. También limpia la telemetría y la línea de tiempo, y avisa al radar con `radar-reset`. Los datos de la semilla viven en `control/demo-scenario.ts`; el script y el reinicio leen el mismo archivo. Las fotos de fórmula quedan en el bucket, igual que con el script.

Un módulo = controllers + services + entities de **ese** tema. El motor de decisión **no** vive dentro de `Simulation`. El reloj de vuelo **no** autoriza pedidos ni asume la carga a bordo.

## Patrones permitidos

- Services inyectados por el DI de Nest.
- Guards JWT + roles (RNF-03).
- ValidationPipe + DTOs class-validator.
- TypeORM (o Prisma, si el equipo unifica uno): **una** librería de persistencia.
- `EligibilityService`, `RoutePlannerService`, `FlightClockService`, `TelemetryPublisher`, `FallbackService` como clases concretas.

## Patrones no permitidos en el MVP

- Hexagonal completo, CQRS, outbox, sagas, gRPC interno.
- Repositorio genérico abstracto de 4 niveles.
- Cola Redis para “todo”; Redis es telemetría, el estado del reloj simulado, la línea de tiempo con tope (RF-39) y, si acaso, cache de OTP.

## Motores (lo que hay que poder dibujar en el tablero)

1. **Decision** — entrada: pedido **autorizado** + drones candidatos. Salida: dron + ruta **pendiente de carga**, o “nadie” → Fallback. **No** arranca el reloj. Emergencia gana (RF-11).
2. **Routing** — origen hub, destino pedido, geovallas PostGIS. Corredor a altitud fija (ida; retorno si timeout). Si no hay camino, el dron no es elegible. En vuelo (RF-33), `rerouteFromPosition` corta el corredor donde va el dron y, si el tramo que falta cruza una zona, pega lo volado con un tramo nuevo. El dron sigue en el mismo km y no salta. `FlightClockService.recheckRoutes()` lo aplica a los vuelos activos y lo llama quien cambia las zonas: hoy `GeofencesService` al crear o mover una geovalla. La ruta de antes queda en `mission_routes."previousPath"` (`GET /radar/flights/:id` la devuelve como `previousRoute`). Si no hay camino, avisa `blocked` y el protocolo es de RF-34.
3. **Simulation** — arranca **solo** tras confirmar carga (RF-28). Intervalo ≤ 2 s **reales** en vuelo (RNF-08); cada tick avanza el tiempo simulado que toque según la velocidad del reloj (RF-31). Si una zona nueva cruza el tramo que falta, cambia la ruta en el aire (RF-33). Ante un incidente aplica el protocolo de `contingency.rules.ts` (RF-34): un servicio de contingencia decide y el reloj de vuelo ejecuta; el reloj no decide. En destino espera 5 min el código (RF-29); si no, vuelo de retorno con el paquete (RF-30) y la cuarentena de [`../context/entregas/productos.md`](../context/entregas/productos.md). Fases eVTOL y batería distinta en vertical vs crucero. Temperatura solo si el ítem tiene flag de frío. Un traslado entre centrales, al recibirse bien, ingresa el lote en la central de destino ([`../context/entregas/centrales.md`](../context/entregas/centrales.md)).
4. **Telemetry** — escribe Redis, publica WSS. Al cerrar misión (entregado o devuelto), persiste resumen en Postgres.

Calibración: `DroneModel` tipo Wingcopter 198 ([`../context/diseno/arquitectura.md`](../context/diseno/arquitectura.md)).

## Seguridad

bcrypt, JWT con expiración, rate limit de login (5 intentos), no SQL concatenado, no loguear datos clínicos. Consentimiento en el registro (RNF-05).

## Pruebas

Unitarias de Decision/Routing/Simulation (casos del documento: sin despegue al autorizar, espera de código, retorno). También del reloj simulado (a x2 el vuelo dura la mitad, la pausa congela, el login no se acelera) y de cada protocolo de contingencia. Un e2e feliz de auth + crear recurso protegido. No exigir 100 % coverage.
