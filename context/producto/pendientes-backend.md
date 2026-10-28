# Pendientes del backend

Lo que el frontend necesita de Nest y que todavía no existe o no funciona
como dice el contexto. Lo mantiene el equipo de frontend: cada fase de
[`avance.md`](avance.md) agrega lo que encuentre al revisar su rol, y quien
trabaje el backend marca lo que resuelva.

Cada punto dice **qué pasa hoy**, **qué debería pasar** (con el documento de
`context/` que lo pide) y **cómo lo usará la app**. Los mensajes de error los
define Nest; el frontend los muestra tal cual.

Estado: `Pendiente` · `En curso (rama)` · `Hecho (PR)`.

---

## 1. Entrega, retorno y cuarentena — En parte hecho (PR #56, #62, #63, #65, #66, #68, #70, #71, rama `feature/cuarentena-inventario`)

**Ya funciona** (probado de punta a punta con la app): el código de un uso
(`GET /orders/:id/delivery-code`) existe desde que se confirma la carga y es
siempre el mismo; `expiresAt` llega `null` en vuelo y con la hora límite al
aterrizar. `POST .../validate` entrega el pedido y el dron vuelve solo a su
central (`leg: 'return'`, el pedido sigue `delivered`) y queda `available`
al aterrizar. A los 5 códigos equivocados se bloquea. Sin código en 5 min
(`DELIVERY_WAIT_MS` la acorta en pruebas) el pedido pasa a `returning`,
vuelve con el paquete y queda `returned`. Recibe el solicitante o el
despachador de la central de destino; los traslados se listan en
`GET /orders/incoming`.

**Hecho en `feature/cuarentena-inventario`:**

- **El lote se descuenta al confirmar la carga** (antes no se descontaba).
  El pedido guarda el registro de salida: `dispatchedLot` y
  `dispatchedLotExpiresOn`. Si el lote ya no alcanza, `confirm-load` responde
  400 "No hay un lote vigente con la cantidad del pedido." y no despega.
- **Cuarentena al volver:** `POST /orders/:id/return-check` con
  `{ packagingIntact: boolean }` (despachador de la central de origen, pedido
  `returned`, una sola vez). Sin alerta de frío, con el empaque íntegro y sin
  sello roto en destino, el lote vuelve al mismo ítem (o se recrea).
  Si no, queda en cuarentena y no vuelve al stock. El pedido trae
  `returnCheckedAt` y `returnOutcome` (`restocked | quarantined`).
  `GET /inventory/quarantine` lista la cuarentena de la central.
- **Traslado recibido:** `POST .../delivery-code/validate` de un traslado
  exige además `{ remissionMatches, sealIntact }` (400 "Confirma si la
  remisión coincide y si el sello llegó intacto." si faltan). Todo bien y sin
  alerta de frío: `delivered` y el lote entra en la central de destino. Si
  no: el pedido pasa a `returning`, el dron vuelve con el paquete y
  `receiptRejectedReason` dice por qué.

**Falta:**

1. ~~**La ruta de regreso no viaja en el pedido.**~~ Hecho en
   `feature/ruta-regreso`: `assignment.returnRoute` (misma forma que
   `assignment.route`) llega en los pedidos del despachador y del
   solicitante. Es `null` hasta que el dron empieza a volver; el reloj la
   calcula en ese momento con las geovallas vigentes, y si una la bloquea,
   es la ida al revés.
2. ~~**El aviso de intentos agotados promete más de lo que pasa.**~~ Hecho
   en `bugfix/intentos-y-retiro`: con el quinto código equivocado el pedido
   pasa a `returning` y el dron vuelve en ese momento con el paquete; los
   intentos siguientes responden "bloqueado". Además, tras un código correcto
   el dron espera 1 minuto en destino con la fase `unloading` (telemetría)
   antes de despegar (`PICKUP_WAIT_MS`).

**La app lo usará** para: la ruta de regreso en el mapa, la revisión del
empaque al recibir un retorno (`return-check`) y el checklist de remisión y
sello al recibir un traslado. **Sin ese checklist, la app ya no puede recibir
un traslado.**

## 2. Fallback con estado `reasignado` (RF-18) — Hecho (rama `feature/fallback-reasignacion`)

**Antes.** Si ningún dron era elegible, autorizar respondía 409 y nada más.

**Ahora** (reglas en RF-18 de [`requisitos.md`](requisitos.md)): autorizar
responde **200** con el pedido y `fallback: { kind, reason, options,
retryAfter, reassignedAt }`, y `assignment: null`.

- `kind: 'hub'`: el pedido queda `reassigned` con `originHubId` en la central
  nueva y aparece primero en su cola (`GET /orders/queue` o
  `/orders/scheduled`). Esa central lo autoriza o lo rechaza como uno recibido.
- `kind: 'conventional'`: `reassigned` final; `options` trae hasta tres
  centrales con el insumo (`hubId`, `name`, `address`, `contactPhone`,
  `contactEmail`, `distanceKm`).
- `kind: 'retry'` (solo programados): sigue `received` y Nest lo reintenta
  solo (`SCHEDULED_RETRY_MS`, 15 min por defecto).
- Todo pedido trae `fallback` (o `null`) y `reassignedFromHubId`.
- Socket: `subscribe-hub { hubId }` (despachador u operador de esa central)
  y el evento `queue-changed { hubId, orderId }`; el pedido publica
  `order-status: reassigned`.

**La app lo usará** en el detalle del despachador y del solicitante (CU-05):
dejar de tratar el 409 como "sin dron" y mostrar `fallback`.

## 3. Telemetría para el operador (RU-18, CU-19) — Hecho (rama `feature/telemetria-operador`)

**Antes.** El operador podía abrir el socket, pero ninguna ruta le decía qué
pedido llevaba cada dron.

**Ahora:**

- `GET /fleet/drones` trae `activeOrderId` y `phase` en cada dron en misión
  (`null` en los demás). Tras una entrega, el regreso vacío sigue mostrando
  ese pedido.
- `GET /fleet/flights?hubId=` (operador) lista los vuelos en curso de sus
  centrales: dron, pedido, estado, fase, tramo, posición, batería,
  temperatura, ETA y `alerts { battery, failure, coldChain }`. Sin Redis el
  vuelo sigue en la lista, sin fase ni posición.
- Socket: con `subscribe-hub { hubId }` el operador recibe las `alert` de
  todos los vuelos de esa central (batería, falla y frío), una sola vez
  aunque además siga el pedido. El despachador en esa sala no las recibe.
- Con `subscribe { orderId }` el operador ya veía el vuelo completo con
  alertas.

**La app lo usará** en la flota del operador (Fase 8).

## 4. Métricas del administrador — Hecho (rama `feature/metricas-admin`)

**Antes.** No había módulo `Analytics` ni endpoints de métricas.

**Ahora** (metas en RF-26 de [`requisitos.md`](requisitos.md)). Las tres
rutas son solo del `admin` y aceptan `?from=AAAA-MM-DD&to=AAAA-MM-DD`; por
defecto cubren los últimos 30 días. Ninguna devuelve nombres, documentos ni
direcciones.

- `GET /analytics/kpis?hubId=`: `groups` (resultados, oportunidades, fallas
  y deficiencias). Cada KPI trae `{ key, label, value, unit, target, status,
  previous, delta }`, y la respuesta suma `byMissionType` y `byStatus`.
- `GET /analytics/demand`: `topMedications`, `byDestinationHub`, `zones`
  (celdas de ~1 km con al menos 3 pedidos) y `byDay`.
- `GET /analytics/hubs`: ranking por central de origen (misiones, éxito,
  retornos, tiempo de urgencia, frío, uso de la flota y drones).
- HU-36: `GET /orders/history?from&to&status&page&pageSize` (despachador).
  Devuelve lo cerrado que despachó su central: `{ items, total, page,
  pageSize }`.

El pedido trae además `authorizedAt`; la misión guarda `returnedAt`.

**La app lo usará** en el inicio del administrador, en lugar de la tarjeta
"PRÓXIMAMENTE", y en el histórico del despachador.

## 5. Flota de una central para el administrador — Hecho (rama `bugfix/flota-admin`)

**Antes.** `GET /fleet/drones?hubId=` permitía el rol `admin` en el
controlador, pero `FleetService.listDrones` llamaba `assertAssigned` y el
administrador, sin centrales asignadas, siempre recibía 403.

**Ahora:** el administrador consulta los drones de cualquier central, solo en
lectura. Una central que no existe responde 404. El operador sigue limitado
a sus centrales, y crear o gestionar drones sigue siendo solo suyo.

**La app** puede mostrarlos en el detalle de una central del administrador.

## 6. Lo que una central le pide a otra — Hecho (PR #66)

**Hoy.** El despachador puede pedir una urgencia a otra central
(`POST /orders/hub-emergencies`), pero después no la encuentra en ninguna
lista: `GET /orders/mine` es solo del solicitante y la cola, los
programados y las bandejas listan lo que sale **de** su central, no lo que
le llega. Solo la ve en el detalle que se abre al crearla. Los
abastecimientos sí aparecen en `GET /orders/plans`.

`GET /orders/incoming` (despachador) lista los pedidos cuyo destino es su
central, del más nuevo al más viejo, con su estado y la asignación del dron.
Con el punto 1, el despachador que pidió el traslado ve el código y lo
ingresa al llegar.

**La app lo usará** en el inicio del despachador: una bandeja "Por recibir"
junto a "Vuelos en curso".

**Hecho.** `GET /orders/incoming` lista los traslados hacia la central del
despachador. La app los muestra en "Traslados entrantes" (Fase 5), con
"Recibir pedido" cuando el dron aterriza.

## 7. Cambiar el correo sin verificarlo — Hecho (rama `feature/confirmar-correo`)

**Antes.** `PATCH /auth/me` cambiaba el correo de una vez si no estaba
tomado; un error de tipeo dejaba a la persona sin poder entrar.

**Ahora** (RNF-04 en [`requisitos.md`](requisitos.md)):

1. `PATCH /auth/me` con un `email` distinto exige `currentPassword`.
   - Sin ella: 400 "Para cambiar el correo escribe tu contraseña actual.".
   - Con una equivocada: 400 "La contraseña actual no es correcta.". Es
     400 y no 401 para que la app no cierre la sesión.
   - El correo **no cambia**: queda en `pendingEmail` (la respuesta lo
     trae) y llega un código de 6 dígitos al correo nuevo, que vence en
     10 min. El resto de campos se guarda como siempre.
2. `POST /auth/me/email/confirm { code }` cambia el correo, limpia
   `pendingEmail` y manda un aviso al correo anterior, con el nuevo
   enmascarado. Si otra cuenta lo tomó entre tanto, responde 409.
3. `POST /auth/me/email/resend` reenvía el código (5 por minuto).
4. `DELETE /auth/me/email/pending` cancela el cambio.

Mientras tanto, el login y la recuperación siguen con el correo actual.
`GET /auth/me` trae `pendingEmail` (o `null`).

**La app lo usará** en el perfil: al guardar un correo nuevo, pedir la
contraseña y mostrar la pantalla de seis cajas del registro. **Hasta que lo
haga, guardar un correo nuevo responde 400** (falta `currentPassword`).

## 8. Editar una central — Hecho (rama `feature/editar-central`)

**Antes.** Una central solo se creaba y se suspendía o reactivaba; un dato
mal escrito obligaba a crear otra.

**Ahora:** `PATCH /hubs/:id` (admin) acepta cualquier campo del alta (nombre,
tipo, dirección, latitud y longitud, celular y correo de contacto), con las
mismas validaciones.

- Un body vacío responde 400 "Debes enviar al menos un campo para
  actualizar.".
- La latitud y la longitud van juntas.
- Mover la ubicación responde 409 "No se puede mover una central con vuelos
  o pedidos en curso." si la central tiene drones en misión o pedidos
  asignados, en carga, en vuelo, en espera, de regreso o reasignados a ella.
- Si el punto nuevo queda dentro de una geovalla, responde 400 "La nueva
  ubicación queda dentro de una geovalla.".
- Enviar las mismas coordenadas no cuenta como mover.

**La app lo usará** en la tarjeta de cada central del administrador
("Editar"), reusando el formulario de Nueva central.

## 9. Alerta de temperatura fuera de rango (RF-17, HU-32) — Hecho (rama `feature/alerta-frio`)

**Antes.** Si el ítem llevaba frío, el reloj publicaba `temperatureC` fija en
5 °C durante todo el vuelo. Nunca salía de rango y no había alerta.

**Ahora** (reglas en RF-17 de [`requisitos.md`](requisitos.md)):
`temperatureC` varía en la telemetría de ida, espera y retorno con paquete.
Con una falla, el socket manda una vez `alert` con `kind: 'cold_chain'` y el
mensaje "La temperatura de la carga salió del rango de 2 a 8 °C." (solo al
operador, como las de batería). El pedido trae `coldChainAlert` y
`coldChainAlertAt`, que la cuarentena del punto 1 usará.
`COLD_CHAIN_FAILURE_RATE=1` fuerza la falla para la demo.

**La app lo usará** en la ficha del vuelo (aviso de frío) y al marcar el
empaque de un retorno.

## 10. Vencimiento del token (`JWT_EXPIRES_IN`) — Hecho (rama `bugfix/jwt-expiracion`)

**Antes.** `auth.module.ts` fijaba el token en 8 horas y no leía
`JWT_EXPIRES_IN` (`.env.example` decía `2h`).

**Ahora:** se lee `JWT_EXPIRES_IN` en segundos o con unidad (`8h`, `30m`,
`1d`). Sin la variable son 8 horas, y `.env.example` queda en `8h`. Un valor
mal escrito detiene el arranque con un mensaje, para que nadie quede con
sesiones de duración inesperada. Quien tenga `2h` en su `.env` local tendrá
sesiones de 2 horas.

**La app** no depende del valor: ante un `401` cierra sesión.

## 11. El seed de pruebas no corre (`pnpm seed:test`) — Hecho (`seed-shared.ts`, renumera los parámetros)

**Hoy.** `cleanTestData` en `backend/scripts/seed-test.ts` manda los dos
parámetros (`$1` prefijo de central, `$2` dominio de correo) a todas las
consultas, pero varias usan solo uno (`inventory_items`, `drones`, `hubs`,
`one_time_codes`, `users`). Postgres responde `bind message supplies 2
parameters, but prepared statement "" requires 1` y fallan tanto
`seed:test` como `seed:clean`.

**Debería**: pasar a cada consulta solo los parámetros que usa (por ejemplo
`[params[0]]` para las de centrales y `[params[1]]` para las de usuarios).

**La app** lo necesita para probar contra datos conocidos sin tocar los de
la demostración.

## 12. Entregas programadas con calendario, franja y confirmación (RU-30) — En curso

Rediseño en tres ramas (detalle en `learning/28-rediseno-entregas-programadas.md`).

**Hecho en `feature/plan-recurrencia`:**

- `POST /orders/plans` y `POST /orders/hub-plans` aceptan `schedule`:
  `{ kind: 'weekly' | 'monthly' | 'dates', startDate?, endDate? | count?,
  daysOfWeek? (1=lunes…7=domingo), everyWeeks? (1–4), dayOfMonth?, dates?,
  time: 'HH:00' }`.
  - La franja es de 1 hora, de 07:00 a 17:00.
  - El plan dura como máximo 3 meses.
  - Las entregas que empezarían en menos de 2 horas no se agendan.
  - Bajo fórmula (plan civil) se pide `prescriptionValidUntil`, y el plan no
    pasa de esa fecha.
- **Compatibilidad:** sin `schedule`, siguen valiendo `frequency` y
  `startDate`. Dan las mismas 8 semanas de antes, la franja es todo el día y
  el plan se puede extender.
- `POST /orders/plans/preview { schedule, prescriptionValidUntil? }`
  devuelve `occurrences [{ date, scheduledAt, windowEndsAt }]` y `tooSoon`
  sin guardar nada.
- `PATCH /orders/plans/:id/schedule { schedule }` cambia el calendario o la
  hora.
  - Las entregas en recibido, sin dron y a más de 2 horas, pasan a
    `cancelled` ("Se cambió el calendario del plan.") y se rehacen.
  - Las demás no cambian y su fecha no se repite.
- Cada entrega trae `scheduledAt` y `windowEndsAt`. El plan trae
  `schedule`, `windowMinutes` y `prescriptionValidUntil`.
- Un plan con calendario no se extiende: responde 400 "Para alargar este
  plan cambia su calendario.".

**Falta:**

1. `feature/plan-confirmacion-avisos`: bandeja de avisos
   (`GET /notifications`), correo por Brevo, confirmar, omitir y mover una
   entrega, la tarea de T-24 h (aviso y revisión de stock y fórmula) y la de
   T-2 h (sin confirmar se omite). Estados nuevos: `agendado`,
   `por confirmar`, `omitido`.
2. `feature/plan-agenda-despacho`: `GET /orders/agenda?date=`, autorizar
   solo desde 2 horas antes hasta el cierre de la franja, la entrega
   `vencida` al cerrar sin despegar (con RF-18) y el aviso de despegue con
   ETA.

**La app lo usará** en el formulario del plan (días, hora, fin y vista
previa), en el detalle del plan (cambiar el calendario) y en el detalle de
cada entrega (la franja). Mientras no lo use, la app sigue funcionando con
`frequency`.
