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

Columnas con tipo PostgreSQL real y longitud coherente (no `varchar(255)` por defecto). IDs `uuid`; instantes `timestamptz`; flags `boolean`; roles/estados `enum`; decimales `numeric`, nunca `float`. El `MaxLength` del DTO coincide con la columna. Referencia: regla `.claude/rules/domain-model.md`.

## Módulos

Nombres alineados al glosario:

`Auth`, `Users`, `Hubs`, `Inventory`, `Fleet`, `Geofences`, `Orders`, `Decision`, `Routing`, `Simulation`, `Telemetry`, `Notifications`, `Analytics`, `Radar`, `Weather`, `Control`, `Airspace`, `Manifests`, `Privacy`. Existe además `Mail` (envío del OTP por Brevo), que no es un dominio de negocio.

`Analytics` (RF-23, RF-26) vive en `analytics/`: el servicio solo carga datos y `analytics.rules.ts` calcula KPI, metas y el dashboard. `FallbackService` (RF-18) vive en `decision/`. `Radar` (`radar/`) solo lee, para la vista web [`../web/`](../web/AGENTS.md): `GET /radar/snapshot` (cada central trae su `queue`: lo que espera su autorización o su carga, más las urgencias que se le ofrecieron), `/radar/hubs/:id` y `/radar/flights/:orderId` (solo `admin`) y la sala `radar` del socket (`subscribe-radar`); no revela a quién va una entrega ni el medicamento de una entrega a una persona.

**Destino de una persona (RU-02, RF-45):** la urgencia y el plan del solicitante llevan `latitude`, `longitude` y una `address` opcional (la referencia; sin ella queda `DEFAULT_REFERENCE`). `assertCoordinates` exige las dos juntas y hasta 6 decimales; `RoutePlannerService.assertDestinationAllowed` rechaza un punto dentro de una geovalla o de una zona legal. No hay chequeo de alcance al crear: si ninguna central llega, `EmergencyDispatchService.start` deja la urgencia en traslado convencional (`NO_HUB_WITHIN_RANGE`).

`Manifests` (`manifests/`, RF-47) emite el manifiesto en `cargo_manifests` dentro de la misma transacción de `confirmLoad`: número `MAN-AAAA-NNNNNN` consecutivo por año (con `pg_advisory_xact_lock`), dron, origen, destino, ítems con lote y vencimiento, peso, frío y quién confirmó (o "Despachador automático"). No lleva datos del paciente. Una carga nueva del mismo pedido anula el anterior. `GET /orders/:id/manifest` lo ven el despachador de origen o destino, el operador de la central y el admin; `/radar/flights/:id` lo trae sin el medicamento si va a una persona.

**Identificación remota (RF-48):** cada tick lleva `remoteId` (`remote-id.rules.ts`): matrícula, operador, tipo, manifiesto vigente y estado (`mission`, `returning`, `link_lost`, `emergency`). Sale en la telemetría y en los vuelos del radar.

`Weather` (`weather/`) guarda las celdas de clima simulado (RF-32): círculos con duración en hora simulada. Las tiene en memoria porque el reloj de vuelo las lee en cada tick, y Postgres (`weather_cells`) las conserva. Las reglas puras están en `weather.rules.ts`:
- `conditionsAt`: viento a lo largo del tramo y lluvia donde va el dron.
- `corridorWeather`: si se puede volar un corredor y sus km equivalentes.
- `stormPolygon`: la tormenta como polígono de 16 lados.

Quién las usa:
- `Routing`: `loadPolygons` suma las tormentas vigentes a las geovallas. `assertDestinationAllowed` mira solo geovallas.
- `Decision`: `HubEvaluationService` evalúa la ida y el regreso, y pasa km equivalentes al motor.
- `Simulation`: `advanceFlight` recibe `weather`. El crucero termina al llegar al final del corredor, no a una hora fija, y avisa `wind_limit` una vez por tramo.

La consola usa `GET`/`POST /control/weather` y `DELETE /control/weather/:id`; una tormenta hace `recheckRoutes()`.

**Geovallas (RF-21, RU-19, RU-36):** una sola tabla `geofences` con `class` (`aerodrome`, `prohibited`, `heliport` = zonas legales; `operational`; `temporary`) y `shape` (`circle` con `centerLatitude`/`centerLongitude`/`radiusM`, o `polygon`); el `polygon` siempre está y es lo que rodean las rutas (`geofence-shape.rules.ts`: radio 50 m–5 km, 3–50 vértices sin lados cruzados). `GET /geofences` (operador y admin) es el catálogo: todas las legales, con `active`, y las operativas vigentes; `GET /geofences/:id` la ficha y `GET /geofences/:id/changes` el historial. El operador crea, edita y borra solo operativas (`POST`/`PATCH`/`DELETE /geofences`, con `category`). Las legales las mantiene el admin con `LegalZonesService` (`/geofences/legal`, `PATCH` y `POST /:id/deactivate|reactivate` con `reason`); no se borran y cada cambio queda en `geofence_changes`. `AirspaceService` siembra las zonas de `regional-airspace.ts` si la tabla no tiene legales y guarda las activas en memoria (`reload()` tras cada cambio).

**Geovallas temporales (RF-36):** son filas `temporary` con `expiresAt` (hora simulada). Lo que lee geovallas operativas y temporales filtra las vigentes con `activeGeofenceSql` (`geofences.rules.ts`) y `simClock.now()`: rutas, radar, el mapa de flota y la validación de centrales; las legales salen de `AirspaceService`. Crear una revisa los vuelos en el aire (`recheckRoutes()`) y, como cualquier geovalla, no puede cubrir una central. Un barrido (`simClock.every`) borra las vencidas y publica el evento `geofence` (`created` / `ended`), que llega a la línea de tiempo y a la sala `radar` como `radar-geofence`. La consola usa `GET`/`POST /control/geofences` (5 a 240 min) y `DELETE /control/geofences/:id`, que solo levanta temporales. El reinicio las borra.

**Incidentes (RF-34, RF-35):** `contingency.rules.ts` (`simulation/`) elige el protocolo con `chooseProtocol`: seguir, volver a la central (`RETURN_TO_HUB`) o aterrizar de emergencia en `safeLandingPoint`. En batería crítica el margen es del 5 % (`LANDING_MARGIN_PERCENT`); en los demás, la reserva del 20 %. El aterrizaje de emergencia "según alcance" va al punto seguro de la red que alcance (`nearestSafeSite`: central activa, por corredor); dos motores y el GPS sin respaldo bajan donde van (`safeLandingPoint`). La pérdida de enlace C2 (`linkHold` en `FlightProgress`) espera 30 s simulados en el mismo punto; en la mitad de los casos el enlace vuelve y sigue, si no aplica el protocolo desde donde quedó. `FlightClockService.handleIncident` lo aplica cuando el reloj detecta viento sobre el límite, batería crítica o un reruteo `blocked` o `batteryShort`. El protocolo viaja en `FlightProgress.contingency`, para que un reinicio lo recuerde. `FlightIncidentsService` guarda `flight_incidents` y publica el evento `incident` (`radar-incident` y `hub-incident`, sin el medicamento). También deja el paquete en cuarentena (`QuarantineReason.INCIDENT`) y, con `simClock.every`, rescata a los drones `grounded`: los pasa a mantenimiento con un periodo abierto por el sistema (`openedByUserId` nulo). Cuando el dron toca tierra, el reloj llama `onMissionAborted` e `IncidentRedispatchService` (`decision/`) corre `DecisionService.redispatchAfterIncident`. La urgencia a una persona se vuelve a ofrecer (RU-10); la urgencia entre centrales vuelve a su central; el programado sigue RF-18. Un pedido puede tener varias misiones y varias cuarentenas: la misión vigente es la última (`latestMissionByOrder`). `GET /control/incidents` los lista.

**Catálogo de la consola (RF-34, CU-38):** `POST /control/drones/:droneId/incidents` con un `kind` de `CONSOLE_INCIDENT_KINDS`; si el dron no vuela, o es falla del frío sin carga fría, responde 400. `FlightClockService.launchIncident` aplica primero el efecto (`INCIDENT_EFFECTS`: `burnFactor` y `speedFactor` en `FlightProgress`, que `advanceFlight` usa en cada tick; `linkLost` va en la telemetría) y después el protocolo. `FIXED_PROTOCOLS` no miran el alcance. El choque grave (`CRASH`) cae donde va y, tras el rescate, el dron queda fuera de servicio. El dron perdido (`LOST`) queda fuera de servicio de inmediato. En los dos el paquete se pierde (`losesPackage`, `ReturnOutcome.LOST`). Las KPI `incidentRate` (por cada 100 misiones que despegaron) y `groundings` salen de `flight_incidents`.

**Central sin energía (RF-36, CU-45):** `hubs.powerOutageUntil` (hora simulada) y `isPowered` (`hub-power.rules.ts`), sin tocar `status`. `HubOutageService` (`hubs/`) la apaga, la devuelve al vencer con `simClock.every`, publica `hub-outage` (`radar-hub-outage`) y avisa a los despachadores (`hub_outage`, `hub_power_restored`). `onOutageStarted` llama a `HubOutageRelocationService` (`decision/`): `EmergencyDispatchService.withdrawHub` la saca de las ofertas abiertas, `DecisionService.evacuateHub` suelta lo autorizado sin cargar y, por último, se vuelven a ofrecer las urgencias a una persona. `authorize` y `confirmLoad` responden 409 sin energía. La oferta escalonada y el fallback no consideran centrales sin energía, y el reintento automático las trata como suspendidas. Consola: `GET /control/hubs/outages`, `POST`/`DELETE /control/hubs/:hubId/outage`.

**Actores simulados (RF-37, CU-39):** viven en `control/` y no tienen atajos. `SimActorsService` guarda los interruptores en Redis (`control:actors`: `autoDispatcher` y `orderFlow`, apagados por defecto), los publica como `actors` (`radar-actors`) y cuenta cada cambio en la línea de tiempo. `AutoDispatcherService` barre cada 5 s simulados: autoriza 10 s después de que le toca a una central (`turnStartedAt`: la oferta, la reasignación o la apertura de la franja) con `DecisionService.autoAuthorize`, y confirma la carga 20 s después con `autoConfirmLoad`; son `authorize` y `confirmLoad` sin el usuario, con las mismas reglas (energía, franja, lote, telemetría). Da la fórmula por verificada y marca `orders.autoDispatched`, que sale en el pedido y en la línea de tiempo. Si el motor dice que no, espera 60 s simulados. `OrderGeneratorService` crea urgencias (con `EmergencyDispatchService.start`, RU-10) y programados (la primera franja a más de 2 h) con `OrdersService`, desde las cuentas `users.simulated` (`simulatedRequesters` de `demo-scenario.ts`, sin documento ni celular, correo `.invalid`; se crean la primera vez que hacen falta). Solo pide insumos de venta libre en stock, hacia un lugar de la demo (`simulatedDestinations`, de `DEMO_PLACES` en `airspace/regional-network.ts`) con un desvío de 0,4 km (`scatterAround`); si el punto cae en una geovalla, prueba otro (hasta 4). El pico usa puntos al azar dentro del círculo. El flujo continuo saca un pedido cada 3 min simulados (70 % urgencias), y el pico de urgencias (RF-36) crea de 2 a 15 dentro de un círculo. `SimulatedReceiverService` mira los pedidos de solicitantes simulados en `awaiting_delivery`: en el 85 % lee el código con `DeliveryService.show` y lo ingresa con `validate` entre 20 s y 2 min después del aterrizaje; en el resto deja correr RF-30. Consola: `GET`/`PUT /control/actors`, `POST /control/actors/orders` (`kind`) y `POST /control/actors/surge`. El reinicio apaga los actores antes de borrar.

**Dron no identificado (RF-36, RF-48):** `UnidentifiedContactsService` (`control/`) guarda en memoria los contactos sin identificación: cruzan en línea recta de 5 a 30 min simulados, por el corredor de un dron en el aire si hay uno. Cada 5 s simulados publica `unidentified` (`radar-unidentified`) y, a menos de 1 km de un corredor activo, deja una alerta en la línea de tiempo una vez por corredor. No actúa contra él. Consola: `GET`/`POST /control/unidentified`; el caos lo saca en la familia de entorno. El reinicio lo borra.

**Modo caos (RF-38, CU-40):** `ChaosService` (`control/`) guarda `{ enabled, intensity }` y quién lo encendió en Redis (`control:chaos`), lo publica como `chaos` (`radar-chaos`) y barre cada 10 s simulados. Cuando toca (`nextChaosAt`: ~15, ~8 o ~4 min según baja, media o alta), `chaos.rules.ts` elige familia y evento por peso (`pickFamily`, `pickEvent`), y el servicio lo aplica con `ConsoleEventsService` (clima, geovalla temporal, apagón, incidente), `OrderGeneratorService.surge` o `SimulatedReceiverService.markNoShow`; los eventos quedan a nombre del admin que lo encendió. La falla elige el dron más gastado (`pickWornDrone`, `flightsSinceMaintenance`) de `FlightClockService.airborne()`. Los graves solo en `high`. Si el dominio rechaza el evento, no se cuenta. Cada evento sale en la línea de tiempo con `source: 'chaos'` (`recordChaos`). Consola: `GET`/`PUT /control/chaos`. El reinicio lo apaga.

`Control` (`control/`) es la consola de simulación de la web (RF-31 a RF-40): reloj simulado, eventos, actores simulados, modo caos, línea de tiempo y reinicio del escenario. Sus endpoints `/control/*` son solo `admin` y existen solo con `CONTROL_ENABLED=true`. `Control` no tiene reglas de negocio propias: los actores simulados llaman a los mismos servicios que una persona (`OrdersService`, la confirmación de carga, la validación del código) y los eventos los aplican `Weather`, `Geofences`, `Hubs` y `Simulation`.

**Reloj:** toda regla que dependa de la hora usa `simClock.now()` / `simClock.nowMs()` (`common/clock/sim-clock.ts`, RF-31), nunca `new Date()` ni `Date.now()`. Es un solo objeto en el proceso, no un servicio inyectado, porque también lo leen las validaciones de los DTO. Un barrido periódico usa `simClock.every(ms, tarea)` (ms simulados), no `setInterval`. Las fechas de creación (`@CreateDateColumn`) toman la hora simulada por `SimTimeSubscriber`. Excepción: auth (JWT, OTP, límite de intentos de login), el consentimiento y el registro de acceso a fórmulas siguen en hora real. La velocidad la cambia `PUT /control/clock` (admin, `CONTROL_ENABLED`), se guarda en Redis y llega por el socket como el evento `clock` (`{ now, speed, paused }`), también al conectar.

**Línea de tiempo (RF-39):** `TimelineService` escucha los eventos que ya publica `NotificationsService` (estado, cola, alerta) y el reloj, los cuenta en español sin datos de personas, los guarda en Redis (`control:timeline`, tope 200) y los manda a la sala `radar` como `radar-timeline`. `GET /control/timeline?limit=` los lee y `GET /control/alerts` lista las alertas de vuelo abiertas (misión sin `returnedAt`) con la posición del dron. Por eso todo cambio de estado de un pedido pasa por `NotificationsService.statusChanged` (CU-29): si un servicio cambia un estado sin anunciarlo, la consola no lo ve.

**Reinicio (RF-40, CU-41):** `POST /control/reset` (`ScenarioResetService`) deja la base **exactamente** como `pnpm seed:demo`. Si no encuentra las centrales de la semilla responde 409. `ScenarioNetworkService` borra las centrales que no son del plan y crea las que faltan (`sync`); dentro de la transacción, `restore` devuelve cada central a sus datos y a su flota exacta (borra drones de más, crea los que faltan, devuelve los movidos). `ScenarioAccountsService` borra toda cuenta que no sea del escenario ni admin (`scenario-accounts.rules.ts`) y devuelve las 35 a sus datos, `Password123` (un solo hash), estado activo y sus centrales. Pone el reloj en hora real y borra **todos** los pedidos, planes, códigos, rutas, misiones, incidentes, avisos, manifiestos, cuarentenas, OTP y el historial de taller. Deja los drones con la batería llena y el estado de la semilla, el stock de la semilla y solo sus geovallas. También limpia la telemetría y la línea de tiempo, y avisa al radar con `radar-reset`. Los datos de la semilla viven en `control/demo-scenario.ts`; el script y el reinicio leen el mismo archivo. Las fotos de fórmula quedan en el bucket, igual que con el script.

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

**Datos personales (RF-50, RF-51):** `Privacy` (`privacy/`) sirve la política versionada (`privacy-policy.ts`; responsable y contacto por `PRIVACY_CONTROLLER_NAME` y `PRIVACY_CONTACT_EMAIL`). `users.consentPolicyVersion` guarda la versión aceptada; si es anterior a `SUBSTANTIAL_POLICY_VERSION`, `mustAcceptPolicy` sale en el usuario y crear un pedido responde 403 hasta `POST /privacy/me/accept`. Revocar (`POST /privacy/me/revoke`, con contraseña) cancela lo que no tiene dron y deja la cuenta `revoked`: no entra ni recibe correos. Suprimir (`POST /privacy/me/delete`) responde 409 con un pedido en curso; si no, borra correo, celular, documento, contraseña, avisos y códigos, deja la cuenta `deleted` y reemplaza el nombre y el documento del paciente por un identificador `ANON-…`, sin tocar medicamento, lote, fecha ni punto. Cada apertura de una fórmula (`GET /orders/:id/prescription[/:index]`, `?purpose=`) deja una fila en `prescription_access_logs`, que ningún endpoint edita; el admin la lee en `GET /privacy/prescription-access` sin ver la fórmula.

## Pruebas

Unitarias de Decision/Routing/Simulation (casos del documento: sin despegue al autorizar, espera de código, retorno). También del reloj simulado (a x2 el vuelo dura la mitad, la pausa congela, el login no se acelera) y de cada protocolo de contingencia. Un e2e feliz de auth + crear recurso protegido. No exigir 100 % coverage.
