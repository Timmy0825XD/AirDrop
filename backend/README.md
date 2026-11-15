# Backend

API NestJS de AirDrop. Convenciones: [AGENTS.md](AGENTS.md). La regla de negocio está en [`../context/index.md`](../context/index.md).

Las tablas de rutas de abajo salen de los controladores de `src/`. Lo que el contexto pide y todavía no existe está en [`../context/historial/pendientes-backend.md`](../context/historial/pendientes-backend.md).

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
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Bucket privado `prescriptions` (la fórmula: un PDF o hasta 3 fotos). La clave `service_role` solo vive aquí |
| `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME` | Envío del OTP por correo |
| `REDIS_URL` | Snapshot de telemetría y pub/sub hacia el socket |
| `DELIVERY_WAIT_MS` | Espera del código de entrega en milisegundos (por defecto 300000 = 5 min). Solo para acortarla en pruebas |
| `DRONE_RECHARGE_PERCENT_PER_MIN` | Recarga de un dron en tierra, en % por minuto (por defecto 1.5). Súbela para que la demo no espere una hora |
| `CORS_ORIGINS` | Orígenes de navegador permitidos, separados por comas. Sin ella: localhost en desarrollo y ninguno en producción |

No subas `.env` a GitHub. Compártelo por un canal privado del equipo.

## Arranque

```bash
cd backend
pnpm install
pnpm start:dev
```

La API queda en `http://localhost:3000`. El primer arranque crea tablas (`synchronize` en desarrollo), activa PostGIS, crea el bucket de fórmulas, siembra el `DroneModel` y un admin.

El OTP viaja por correo (Brevo). Si Brevo no está configurado y el ambiente no es producción, el código se imprime en el log.

## Esquema de la base

El MVP no usa migraciones de TypeORM (decisión del 2026-11-10). El esquema sale de dos piezas:

- **`synchronize`** ([`typeorm.config.ts`](src/database/typeorm.config.ts)): con `NODE_ENV` distinto de `production`, TypeORM crea y ajusta las tablas y columnas según las entidades. En `production` está apagado.
- **[`align-sprint-schema.ts`](src/database/align-sprint-schema.ts)**: corre en cada arranque, antes de conectar, y solo si ya existe `users`. Arregla lo que `synchronize` no puede: valores nuevos de enums, enums que ya tienen datos, columnas e índices viejos. No crea tablas ni todas las columnas nuevas.

**Base nueva de producción.** Arranca la API **una vez** con `NODE_ENV=development` contra la base vacía y sin tráfico. Espera a que suba (crea las tablas, PostGIS, el bucket, el `DroneModel` y el admin), apágala y desde ahí arráncala con `NODE_ENV=production`. Esa única vez la API acepta `localhost` en CORS e imprime el OTP en el log si Brevo no está configurado. Por eso va sin usuarios conectados.

**Base de producción que ya existe.** Si una rama agrega tablas o columnas, `production` no las crea, y `align-sprint-schema.ts` tampoco cubre `flight_incidents`, `weather_cells`, `users.simulated`, `orders.autoDispatched`, el tamizaje y el paciente a cargo (`orders.redFlags`, `patientGroup`, `pregnant`, `symptoms`, `symptomOnset`, `symptomSeverity`, `allergies`, `patient*`; `delivery_plans.patient*`; `users.allergies`). Saca una copia de seguridad y repite el arranque único en `development`. `synchronize` también **borra** las columnas que ya no están en las entidades: revisa el diff de las entidades antes.

Si algún día hay despliegue continuo, toca pasar a migraciones de TypeORM.

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

La central la crea el administrador y nace `active`; no hay estado de aprobación pendiente. Lleva `networkRole` (RF-06): `node` tiene drones y despega; `ese` recibe reabastecimiento y no tiene drones. Un nodo no se crea en zona urbana, en el anillo del aeropuerto ni en una zona prohibida o coordinada; una ESE puede quedar en una coordinada (es el sitio pactado). El origen de un traslado y la central de un dron son siempre un nodo, y el operador de flota solo se asigna a nodos.

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
| PATCH | `/fleet/drones/:id/cold-compartment` | operador |
| POST | `/fleet/drones/:id/maintenance` | operador |

Al arrancar se siembran los tres tipos de RF-49 (`src/fleet/drone-types.ts`): Colibrí (`rapid`, 2 kg, 140 km/h, 120 km), Garza (`balanced`, 5 kg, 110 km/h, 90 km) y Cóndor (`cargo`, 15 kg, 60 km/h, 30 km), con techo, velocidad vertical, masa, batería y límite de viento. Si queda el modelo comercial de antes, sus drones pasan a Garza y el modelo se borra. El dron nace en `available` y puede llevar `coldCompartment` (resta 1 kg de carga útil); `PATCH /fleet/drones/:id/cold-compartment` lo pone o lo quita con el dron en tierra. Identificador máximo 32 caracteres. Un dron en misión no cambia de estado.

El motor descarta por estado, carga (unidades × `unitWeightG` del lote), frío, batería, viento del tipo y corredor; entre los que quedan, la urgencia elige el de menor tiempo de llegada y el programado el de menor energía (Wh). El pedido guarda `payloadKg` al reservar el lote. El inventario exige `unitWeightG` y admite `dangerousGoods`: la mercancía peligrosa no se ofrece ni vuela.

### Geovallas (HU-14)

Todas del operador de flota.

| Método | Ruta |
| --- | --- |
| POST | `/geofences` |
| GET | `/geofences` |
| PATCH | `/geofences/:id` |
| DELETE | `/geofences/:id` |

### Espacio aéreo (RF-43, HU-60)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/airspace/zones` | cualquier sesión |
| GET | `/airspace/daylight` | cualquier sesión |

Las zonas legales del RAC 100 viven en `src/airspace/regional-airspace.ts` (no en la base) y no se editan: aeródromo (anillo de 9 km de SKVP), prohibidas con 2 km de margen, helipuerto, urbana, coordinadas (policía municipal y resguardos, con entrada pactada) y de precaución (pistas privadas, no bloquean). El planificador rodea las bloqueantes y las coordinadas; a un sitio pactado entra por su entrada. El radar las trae en `airspace`. La red (nodos, ESE y puntos) está en `src/airspace/regional-network.ts`.

**Terreno (RF-46).** `src/airspace/terrain-grid.json` es una malla de 189×189 celdas de ~500 m con la elevación máxima de cada una, sacada de SRTM (mosaicos Terrain Tiles de AWS). Se regenera con `python scripts/build-terrain-grid.py <carpeta-cache>` (PIL y numpy) y `nest build` la copia a `dist`. El dron despega a 90 m AGL y en crucero mantiene la altitud entre 60 y 120 m AGL; sube antes de una ladera según su velocidad vertical. La decisión descarta un tipo si el punto más alto supera su techo o si la batería no alcanza ida, regreso, subida y reserva; el vuelo cobra cada metro ganado. La telemetría trae `altitudeM` (AGL) y `altitudeMslM`.

**Solo de día (RF-44).** `src/airspace/daylight.rules.ts` calcula la salida y la puesta del sol con las ecuaciones de la NOAA (sin API) para la fecha simulada. Un dron se descarta si su misión (ida, 5 min de espera y regreso, con su crucero) no termina antes de la puesta en su nodo. Una urgencia creada de noche no entra a ninguna cola: pasa de una vez a traslado convencional con el motivo. Las franjas de los programados van de 07:00 a 16:00 (la última cierra a las 17:00). `GET /airspace/daylight` devuelve la salida, la puesta y si ahora es de día.

### Puntos de entrega (RF-45)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/delivery-points?latitude=&longitude=&medicationName=` | cualquier sesión |
| PATCH | `/delivery-points/:id` (`{ active }`) | administrador |

Los puntos son lugares del escenario (`delivery_points`, tomados de `regional-network.ts`), no cuentas. Se crean al arrancar y `pnpm seed:demo` y el reinicio los enlazan con su nodo y los dejan activos. Con el GPS, `GET` los ordena por distancia y trae `nearestPointId` (el disponible más cercano). Un punto está disponible si está activo y su nodo también; el solicitante solo ve esos y el administrador ve todos, con `available`. Si el GPS cae en la ciudad (zona urbana o anillo de SKVP), `coverage` es `urban`; si no hay punto disponible, `no_point`. En los dos casos llega `message` y, con `medicationName`, `alternatives`: hasta tres centrales con el insumo para recogerlo por tierra (RF-18). Un punto en zona coordinada trae `corridor` (zona y entrada pactada).

La urgencia y el plan del solicitante van a un punto: `deliveryPointId` reemplaza a `latitude`, `longitude` y `address`, que ahora salen del punto. `requesterLocation` (`{ latitude, longitude }`, opcional, no se guarda) hace que el pedido no se cree si el solicitante está en la ciudad. El pedido y el plan traen `deliveryPointId` (nulo entre centrales).

### Datos personales (RF-50, RF-51)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/privacy/policy` | pública |
| GET | `/privacy/me` | cualquier sesión |
| POST | `/privacy/me/accept` (`{ version }`) | cualquier sesión |
| POST | `/privacy/me/revoke` (`{ password }`) | solicitante |
| POST | `/privacy/me/delete` (`{ password }`) | solicitante |
| GET | `/privacy/prescription-access?orderId=&userId=&from=&to=` | administrador |

El usuario (login y `/auth/me`) trae `policyVersion` y `mustAcceptPolicy`; con `mustAcceptPolicy` la urgencia y el plan responden 403. Revocar deja la cuenta inactiva (el login responde 403) y cancela lo que no tiene dron. Suprimir responde 409 con un pedido en curso; si no, libera el correo y el celular y anonimiza los pedidos. Las rutas de la fórmula aceptan `?purpose=authorize|history|claim` y cada apertura queda en el registro.

### Manifiesto e identificación (RF-47, RF-48)

| Método | Ruta | Auth |
| --- | --- | --- |
| GET | `/orders/:id/manifest` | despachador de origen o destino, operador del nodo, administrador |
| GET | `/control/unidentified` | administrador (`CONTROL_ENABLED`) |
| POST | `/control/unidentified` (`{ durationMin, from?, to? }`) | administrador (`CONTROL_ENABLED`) |

`confirm-load` emite el manifiesto en la misma transacción y responde `manifestNumber`. El manifiesto (`MAN-2026-000123`) trae dron, origen, destino, ítems con lote y vencimiento, peso, frío y quién confirmó; `previous` lista los anulados por una carga nueva. La telemetría y los vuelos del radar traen `remoteId` (matrícula, operador, tipo, manifiesto y estado). `radar-unidentified` (`started`, `moved`, `ended`) mueve en la consola un dron no identificado.

**Niebla (RF-32, VMC).** El clima admite `fog`: como la tormenta, es zona no volable que las rutas rodean, con su propio motivo. El modo caos la saca más de 05:00 a 08:00.

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
| GET | `/orders/incoming` | despachador (traslados cuyo destino es su central) |
| POST | `/orders/emergencies` | solicitante |
| POST | `/orders/hub-emergencies` | despachador |
| POST | `/orders/plans` | solicitante |
| POST | `/orders/hub-plans` | despachador |
| GET | `/orders/plans` | solicitante o despachador |
| GET | `/orders/plans/:id` | solicitante o despachador |
| POST | `/orders/plans/:id/extend` | solicitante o despachador |
| POST | `/orders/plans/:id/cancel` | solicitante o despachador |
| GET | `/orders/:id` | solicitante o despachador |
| GET | `/orders/:id/prescription` | despachador (la primera hoja) |
| GET | `/orders/:id/prescription/files` | despachador |
| GET | `/orders/:id/prescription/:index` | despachador |
| POST | `/orders/:id/authorize` | despachador (motor de decisión: reserva dron y ruta, no despega) |
| POST | `/orders/:id/confirm-load` | despachador (arranca la simulación) |
| POST | `/orders/:id/reject` | despachador |
| GET | `/orders/:id/delivery-code` | quien recibe: solicitante, o despachador de la central de destino (el código existe desde confirmar la carga) |
| POST | `/orders/:id/delivery-code/validate` | quien recibe (entrega el pedido; 5 intentos) |

### Telemetría (HU-26 a HU-28)

| Canal | Ruta | Auth |
| --- | --- | --- |
| GET | `/telemetry/orders/:id` | solicitante, despachador u operador |
| WebSocket | namespace `/telemetry`, mensaje `subscribe` | JWT en `auth.token` |

El gateway responde `subscribe` con los eventos `subscribed` o `error` (no con ack) y empuja `telemetry`, `order-status` y `alert`. Tick de 2 s en vuelo (RNF-08).

## Entrega y retorno

El código de entrega existe desde que se confirma la carga y lo ve quien recibe. Al aterrizar el dron hay **5 minutos** (`DELIVERY_WAIT_MS` los acorta en pruebas) para ingresarlo: válido → `delivered`, y el dron vuela de regreso a su central. Sin código → `returning`, el dron vuelve con el paquete y al aterrizar el pedido queda `returned`. Cada pedido admite 5 códigos equivocados.

## Lo que todavía no hay

Cuarentena al volver el paquete e ingreso del lote al inventario de destino; fallback `reasignado`; módulo `Analytics`; vuelos en curso para el operador; verificar el correo nuevo; editar una central. El detalle de cada uno, con el documento que lo pide, está en [`pendientes-backend.md`](../context/historial/pendientes-backend.md).

## Documentación interactiva

Con el servidor arriba, Swagger está en `http://localhost:3000/api` (usa **Authorize** con el token del login) y la definición OpenAPI en `/api-json`.

## Pruebas

```bash
pnpm test
pnpm test:e2e
pnpm lint:check   # ESLint sin modificar archivos
```

Datos de ejemplo (usan `DATABASE_URL`, así que apúntalo a una base de pruebas):

```bash
pnpm seed:test    # cuentas @prueba.co, centrales PRUEBA-, inventario y drones
pnpm seed:clean
pnpm seed:demo    # 3 centrales, 15 drones, cuentas, inventario y geovallas de Valledupar para una demostración
pnpm seed:demo:clean
```

El e2e usa el mismo `DATABASE_URL`. **No** borra el esquema (no pongas `E2E_DROP_SCHEMA=true` contra la BD del equipo).

`pnpm-workspace.yaml` aquí no es un monorepo de varios paquetes: pnpm 11 guarda ahí la política de scripts de instalación.
