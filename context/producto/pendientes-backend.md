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

## 12. Entregas programadas con calendario, franja y confirmación (RU-30) — Hecho

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

**Hecho en `feature/plan-confirmacion-avisos`:**

- **Estados nuevos de un pedido:** `scheduled` (agendado), `awaiting_confirmation`
  (por confirmar) y `skipped` (omitido).
- **Con qué estado nacen las entregas de un plan con franja:**
  - a más de 24 h, `scheduled`;
  - a 24 h o menos, `received` ya confirmadas, porque quien arma el plan
    las acaba de elegir.

  Los planes con `frequency` siguen naciendo en `received`, como antes.
- **T-24 h:** a una persona se le pasa a `awaiting_confirmation` y le llega
  el aviso «Confirma tu entrega programada». Un abastecimiento a una central
  pasa solo a `received` y avisa a los despachadores de destino y de origen.
  Si hoy no alcanza el stock, llega además un aviso de stock.
- **T-2 h:** lo que sigue sin confirmar pasa a `skipped` ("No se confirmó 2
  horas antes de la franja.") y se avisa.
- **Quien recibe** (la persona, o el despachador de la central de destino),
  hasta 2 h antes y sin dron:
  - `POST /orders/:id/confirm`;
  - `POST /orders/:id/skip`;
  - `POST /orders/:id/reschedule { date, time }`, al mismo día o al
    siguiente. Mover la entrega cuenta como confirmarla.
- **Pausar un plan:** `POST /orders/plans/:id/pause` y `/resume`. En pausa no
  hay avisos, y a T-2 h se omite todo lo que no tenga dron. El plan trae
  `paused`.
- **Bandeja:**
  - `GET /notifications?unread=true`, `PATCH /notifications/:id/read` y
    `POST /notifications/read-all`, para cualquier rol;
  - cada aviso también va al correo (Brevo). Los textos no nombran el
    medicamento;
  - cada pedido trae `confirmedAt`.
- **Al cancelar un plan** también pasan a `cancelled` las entregas en
  `scheduled` y `awaiting_confirmation`.

**Hecho en `feature/plan-agenda-despacho`:**

- `GET /orders/agenda?date=AAAA-MM-DD` (despachador de la central):
  `{ date, drones, slots: [{ time, deliveries, overCapacity, orders }] }`.
  Cada pedido trae lo de siempre más `time`, `confirmed`, `stockOk`,
  `prescriptionValid` (`null` si no pide fórmula), `departBefore` (ISO, o
  `null` si no hay corredor) y `availableQuantity`. `departBefore` es el
  cierre de la franja menos el ETA de la ida.
- Autorizar y confirmar la carga de un programado solo entre 2 horas antes
  de la franja y su cierre. Fuera de eso: «Esta entrega se despacha desde 2
  horas antes de la franja.» o «La franja de esta entrega ya cerró.»
  Una entrega reasignada a otra central ya no usa esa franja.
- Al cerrar la franja sin despegue: suelta el dron si estaba reservado,
  queda `expired` si no hay central de origen, y si la hay aplica RF-18
  (otra central o traslado convencional) con motivo «La franja cerró sin
  despegue.» El reintento de 15 min solo cabe si el siguiente intento sigue
  dentro de la franja.
- Al despegar, aviso «Tu entrega programada salió» / «Salió un
  abastecimiento programado», con la hora estimada de llegada. No nombra
  el medicamento.
- Al crear o cambiar el calendario de un plan con central de origen, la
  respuesta trae `busySlots: [{ date, time, deliveries, drones }]`. No
  bloquea el alta.

**La app lo usará** en el formulario del plan (días, hora, fin, vista
previa y el aviso de franja llena), en el detalle del plan (cambiar el
calendario) y en el detalle de cada entrega (la franja, y los botones de
confirmar, omitir y mover), en la agenda del despachador y en una bandeja
de avisos. Mientras no use `schedule`, la app sigue funcionando con
`frequency`. Los estados nuevos ya no rompen el parseo (`scheduled`,
`awaiting_confirmation`, `skipped`, `expired`); la agenda y los botones de
la franja todavía no están en las pantallas.

## 13. Urgencia escalonada por cercanía (RU-10) — Hecho (rama `feature/decision-despacho-escalonado`)

**Qué pasaba:** la urgencia de un solicitante aparecía en la cola de todas
las centrales con stock y la autorizaba la primera que la viera, aunque
estuviera dos o tres veces más lejos. Además cualquiera de ellas podía
rechazarla y la cerraba para todas.

**Qué hace ahora** ([`requisitos.md`](requisitos.md) RU-10):

- Al crearla, entra solo a la cola de la central que llega antes (primero
  las que tienen dron elegible). Si no la autoriza a tiempo (lo que ahorra
  frente a la siguiente, entre 1 y 3 min), entra también a la cola de la
  siguiente. La autoriza la primera que lo haga. El socket avisa a cada
  central cuando le llega (`queue-changed`).
- `GET /orders/queue`, `GET /orders/:id` y `GET /orders/:id/prescription`
  solo la muestran a las centrales a las que ya se ofreció. Autorizar desde
  otra central responde 403 «Esta urgencia todavía no está en la cola de tu
  central.»
- **Nuevo:** `POST /orders/:id/decline`, rol despachador, body opcional
  `{ "reason": "Sin dron disponible" }` (hasta 160 caracteres). Responde el
  pedido. La urgencia sale de la cola de esa central y entra en ese instante
  a la de la siguiente. Errores: 400 «Solo se declina una urgencia recibida
  que todavía no tiene central.», 403 «Esta urgencia todavía no está en la
  cola de tu central.» o «Tu central ya declinó esta urgencia.»
- Si ninguna central con el insumo tiene un dron que alcance el destino, la
  urgencia queda `reassigned` con `fallback.kind = conventional` al crearla.
  Si todas declinan, igual. La respuesta de `POST /orders/emergencies` ya
  trae ese estado.
- `POST /orders/:id/reject` queda para la fórmula que no cumple: cierra el
  pedido.
- El fallback al autorizar sin dron elige la central que llega antes por su
  corredor, no la más cercana en línea recta.

**La app lo usará** en la cola del despachador: un botón «No puedo
atenderla» junto a autorizar y rechazar, que llama a `decline` y quita la
fila. El solicitante no ve nada nuevo: su urgencia sigue `received` hasta
que una central la autoriza, o pasa a `reassigned` con las centrales del
traslado convencional.

## 14. Por qué el motor eligió ese dron — Hecho (rama `feature/decision-traza`)

**Qué pasaba:** el motor calculaba por qué descartaba cada dron y lo botaba.
El despachador veía `reasignado` sin saber si fue por carga, batería,
mantenimiento o geovalla.

**Qué hace ahora:** cada autorización, reasignación, reintento, traslado
convencional, rechazo por geovalla o vencimiento guarda la traza en el
pedido.

- **Nuevo:** `GET /orders/:id/decision`, rol despachador. La ve la central
  que puede abrir el pedido (origen, destino, quien lo creó o a la que se
  le ofreció la urgencia); otra central recibe 404.

```json
{
  "orderId": "…",
  "trace": {
    "at": "2026-11-02T15:01:00.000Z",
    "outcome": "assigned | reassigned | retry | conventional | rejected | expired",
    "reason": null,
    "hubs": [{
      "hubId": "…", "name": "Hospital Rosario", "lot": true,
      "corridorKm": 11, "etaMin": 5.4, "batteryNeededPercent": 56,
      "inRange": true, "note": null,
      "drones": [
        { "identifier": "WC-01", "status": "discarded", "reason": "El dron está en mantenimiento.", "preempts": false },
        { "identifier": "WC-02", "status": "chosen", "reason": null, "preempts": false }
      ]
    }]
  },
  "offers": [{ "hubId": "…", "name": "…", "etaMin": 6, "ready": true,
               "offeredAt": "…", "declinedAt": null, "declineReason": null }]
}
```

`trace` es `null` en pedidos que el motor todavía no evaluó o que se
decidieron antes de esta rama. `offers` es `null` salvo en urgencias de un
solicitante (RU-10). `note` explica una central sin drones evaluados («No
tiene un lote vigente con la cantidad.», «No hay un corredor libre de
geovallas.», «La central está suspendida.» o «Solo se revisó el stock: ya
intentó o es la central que pidió.»).

**La app lo usará** en el detalle del pedido del despachador: un bloque
«¿Por qué este dron?» con cada central y el veredicto de sus drones, y en
una urgencia la escalera de centrales a las que se ofreció.

## 15. Batería por dron y rotación de la flota — Hecho (rama `feature/fleet-rotacion-bateria`)

**Qué pasaba:** cada vuelo salía con la batería al 100 % y, dentro de una
central, el motor elegía siempre el mismo dron (el primero por
identificador).

**Qué hace ahora** ([`requisitos.md`](requisitos.md) RF-11):

- Al volver a la central, el dron guarda con cuánta batería llegó. En tierra
  recarga 1,5 % por minuto (`DRONE_RECHARGE_PERCENT_PER_MIN` la cambia para
  la demo). El siguiente vuelo sale con esa batería.
- Si no alcanza para ida, regreso y reserva, el dron se descarta con «La
  batería no alcanza para la ida, el regreso y la reserva del 20 %.» y sale
  otro.
- Entre los que sirven sale el que lleva más tiempo en tierra; el que nunca
  ha volado, primero. Con varias urgencias seguidas, los drones se alternan.
- `GET /fleet/drones` (y la respuesta de alta, estado y mantenimiento) y el radar (`/radar/hubs/:id`) traen
  `batteryPercent` (ahora, con la recarga) y `lastFlightEndedAt` (`null` si
  nunca ha volado). En `GET /orders/:id/decision`, cada dron de la traza trae
  `batteryPercent`.

**La app lo usará** en la flota del operador (batería de cada dron en tierra
y cuándo volvió) y en «¿Por qué este dron?».

## 16. El operador de flota completo — Hecho (PR #113 a #117 y `feature/fleet-dashboard`)

Plan acordado el 2026-11-05 para cerrar el rol del operador en Nest:
`refactor/fleet-codigo-muerto` (PR #113), `bugfix/validaciones-flota`,
`feature/fleet-vuelos-ruta`, `feature/fleet-mapa-operador`,
`feature/fleet-mantenimiento` y `feature/fleet-dashboard`. El operador solo
recibe lo que sirve para su trabajo: nada de inventario, cola, contactos,
solicitante, medicamento ni fórmula.

**Hecho en `refactor/fleet-codigo-muerto`:** una cuenta no activa recibe 401
del guard (`JwtStrategy`) antes de llegar a la flota o a las geovallas; el 403
«Tu cuenta debe estar activa…» no salía nunca y se quitó.

**Hecho en `bugfix/validaciones-flota`:**

- `POST /fleet/drones/:id/maintenance` y `PATCH /fleet/drones/:id/status`:
  - una fecha que no existe (`2026-02-31`) responde 400 «La fecha estimada no
    es una fecha válida.» (antes, 500);
  - una fecha anterior a hoy (día de Colombia) responde 400 «La fecha
    estimada no puede ser anterior a hoy.»; hoy sí vale;
  - el motivo del mantenimiento en blanco responde 400 «El motivo es
    obligatorio.».
- `POST /geofences`: nombre o motivo en blanco responden 400 «El nombre es
  obligatorio.» / «El motivo es obligatorio.». `PATCH /geofences/:id`: si
  vienen, no pueden ir en blanco («El nombre no puede quedar vacío.» / «El
  motivo no puede quedar vacío.»).
- Crear una geovalla, o mover su polígono, con una central dentro (activa o
  suspendida) responde 400 «La geovalla no puede cubrir una central: <nombre>
  queda dentro.». Una central fuera del polígono pero cerca del borde sí se
  permite: el corredor puede salir de ahí.

**La app lo usará** en el formulario de mantenimiento (el calendario ya
empieza hoy) y en el dibujo de geovallas, mostrando el mensaje de Nest.

**Hecho en `feature/fleet-vuelos-ruta`:** cada vuelo de `GET /fleet/flights`
trae además (los datos en vivo son `null` sin Redis; la ruta no depende de
Redis):

- `altitudeM`, `speedKmh`, `payloadKg` y `latencyMs`, que con los que ya
  venían completan el paquete de RU-18;
- `route` (la ida) y `returnRoute` (`null` hasta que el dron empieza a
  volver), con la forma de `assignment.route`: `{ altitudeM, distanceKm,
  coordinates: [[lng, lat], …] }`;
- `destination: { kind: 'person' | 'hub', hubId, latitude, longitude }`: el
  final del corredor de ida (o el punto del pedido si aún no hay corredor).
  `hubId` solo en un traslado. Es `null` si no hay ninguno.

Sigue sin traer nada de quién recibe ni qué lleva (solicitante, dirección,
medicamento, fórmula). Por eso el operador no necesita `GET /orders/:id`.

**La app lo usará** en "Vuelos en curso" del operador para dibujar el
corredor de ida y de regreso y el punto de llegada.

**Hecho en `feature/fleet-mapa-operador`:** el mapa del operador, como el
radar web pero solo con lo de su trabajo.

- `GET /fleet/map?hubId=` (operador; sin `hubId`, todas sus centrales; una
  central ajena, 403):

```json
{
  "hubs": [{ "id": "…", "name": "Hospital Rosario Pumarejo",
             "type": "hospital", "status": "active",
             "latitude": 10.46314, "longitude": -73.25322,
             "fleet": { "available": 1, "inMission": 1, "maintenance": 1,
                        "outOfService": 0, "total": 3 } }],
  "geofences": [{ "id": "…", "name": "…", "reason": "…",
                  "polygon": { "type": "Polygon", "coordinates": [] } }],
  "flights": ["…lo mismo que GET /fleet/flights…"]
}
```

  De la central no viajan dirección, contactos, inventario, cola ni quién la
  creó.

- Socket `/telemetry`, después de `subscribe-hub { hubId }` (solo el
  operador recibe esto; el despachador en la misma sala, no):
  - `hub-telemetry`: cada tick de cada vuelo de la central, `{ hubId,
    orderId, droneId, identifier, latitude, longitude, altitudeM, speedKmh,
    phase, leg, status, etaSeconds, batteryPercent, payloadKg, temperatureC,
    latencyMs }`;
  - `hub-flight-status { hubId, orderId, status }`: cuando un pedido toma un
    dron (`pending_load`), despega, aterriza, se entrega, vuelve, queda
    devuelto o suelta el dron antes de despegar (por ejemplo `reassigned`);
  - `hub-flight-ended { hubId, orderId, droneId }`: el dron aterrizó de vuelta
    en su central y el vuelo sale del mapa;
  - `alert`, como ya llegaba.

  Un `hub-telemetry` de un `orderId` que el mapa no tiene es un vuelo nuevo:
  la app pide `GET /fleet/map` (o `/fleet/flights`) para traer su ruta. Con
  `hub-flight-status` o `hub-flight-ended`, vuelve a pedirlo si quiere los
  conteos de la flota al día.

**La app lo usará** en una pantalla de mapa del operador: sus centrales, las
geovallas y cada dron moviéndose con sus métricas.

**Hecho en `feature/fleet-mantenimiento`** (CU-16, CU-17):

- **Dos estados distintos.** `maintenance` es temporal, con fecha estimada
  de fin; `out_of_service` es indefinido y no guarda fecha (si llega
  `estimatedEndDate`, se ignora).
- **Cambio de contrato:** `POST /fleet/drones/:id/maintenance` deja el dron
  en `maintenance`, ya no en `out_of_service`. La app dice hoy «dron fuera de
  servicio» al registrarlo: cambiar el texto.
- **Historial:** cada salida de la flota abre un periodo y volver a
  `available` lo cierra; entre mantenimiento y fuera de servicio se cierra
  uno y se abre otro. `GET /fleet/drones/:id/maintenance` (operador de esa
  central; administrador en lectura) devuelve, del más reciente al más
  viejo, `[{ id, kind: 'maintenance' | 'out_of_service', reason,
  estimatedEndDate, flightsAtStart, startedAt, closedAt }]`.
- **Preventivo:** cada vuelo que vuelve a la central suma uno. Cada dron
  (en `GET /fleet/drones` y en las respuestas de alta y de estado) trae
  `flightsSinceMaintenance`, `maintenanceCycles` (50 por defecto;
  `DRONE_MAINTENANCE_CYCLES` lo cambia) y `maintenanceDue`. Cerrar un
  **mantenimiento** pone los vuelos en 0; volver de fuera de servicio no.
  `maintenanceDue` no saca al dron de la flota.
- **Vencido:** `maintenanceOverdue` es `true` si el dron sigue en
  mantenimiento y su fecha estimada es anterior a hoy (día de Colombia). No
  se libera solo: lo libera el técnico o mueve la fecha.
- **Avisos al operador** (bandeja y correo, a los operadores activos de la
  central, una sola vez; se revisa cada 10 min): `maintenance_overdue`
  «Mantenimiento vencido» y `maintenance_due` «Le toca revisión a un dron».
  Mover la fecha vuelve a habilitar el de vencido; cerrar un mantenimiento,
  el de revisión.
- **Esquema:** tabla `drone_maintenances`, el enum `drone_maintenance_kind`,
  tres columnas en `drones` y dos valores nuevos en `notification_kind`. Se
  crean con `synchronize` (fuera de `production`).

**La app lo usará** en la flota del operador: el contador de vuelos con la
marca de revisión, la marca de vencido, el historial de cada dron y los
avisos nuevos en la campana.

**Hecho en `feature/fleet-dashboard`** (CU-20 para el operador): `GET
/fleet/dashboard?from=AAAA-MM-DD&to=AAAA-MM-DD&hubId=` (operador; mismas
fechas y errores que `/analytics`, por defecto 30 días; sin `hubId`, todas
sus centrales; una ajena, 403). Solo lo que sirve para cuidar la flota: no
nombra medicamentos ni personas.

```json
{
  "period": { "from": "2026-10-07", "to": "2026-11-05" },
  "usage": {
    "flights": 18, "km": 86.4,
    "inMissionPercent": 12.5, "inShopPercent": 4, "availablePercent": 83.5,
    "byDrone": [{ "droneId": "…", "identifier": "WG-198-001", "hubId": "…",
                  "flights": 9, "km": 43.2, "inMissionPercent": 13,
                  "inShopPercent": 0, "availablePercent": 87 }]
  },
  "health": {
    "landingBattery": { "average": 61.2, "min": 38, "samples": 18 },
    "maintenanceDue": 1, "maintenanceOverdue": 0,
    "byDrone": [{ "droneId": "…", "identifier": "WG-198-001", "hubId": "…",
                  "status": "available", "batteryPercent": 92,
                  "flightsSinceMaintenance": 50, "maintenanceCycles": 50,
                  "maintenanceDue": true, "maintenanceOverdue": false,
                  "landingBattery": { "average": 60, "min": 38, "samples": 9 } }]
  },
  "incidents": {
    "battery": 1, "failure": 0, "coldChain": 2, "returnedWithPackage": 1,
    "byDrone": [{ "droneId": "…", "identifier": "…", "battery": 1,
                  "failure": 0, "coldChain": 1, "returnedWithPackage": 0 }],
    "byDay": [{ "date": "2026-11-04", "flights": 3, "battery": 0,
                "failure": 0, "coldChain": 1, "returnedWithPackage": 0 }]
  },
  "zones": {
    "flights": [{ "latitude": 10.485, "longitude": -73.245, "count": 5 }],
    "geofenceBlocks": { "total": 4, "zones": [] }
  }
}
```

- **Tiempo:** en misión va de despegar a volver a la central; en taller,
  los periodos de `drone_maintenances`; un dron dado de alta a mitad del
  periodo cuenta desde su alta. `byDrone` de incidentes solo trae drones con
  alguno.
- **Batería al volver:** se guarda desde esta rama
  (`missions.landingBatteryPercent`); los vuelos anteriores no cuentan
  (`samples`).
- **Zonas:** celdas de ~1 km donde termina la ida; una celda sale solo con 3
  vuelos o más, como en `/analytics`. `geofenceBlocks.total` cuenta los
  pedidos que una geovalla dejó sin corredor en sus centrales (o cuyo
  destino cayó dentro de una), según la traza del motor.
- **Esquema:** una columna nueva en `missions` (con `synchronize` fuera de
  `production`).

**La app lo usará** en una pestaña "Tablero" del operador.

## 17. La consola de simulación: lo que cambia para la app — Hecho (PR #120 a #134)

La web pasó a ser la consola de simulación del administrador (RU-32, RF-31 a
RF-40). La app no gana pantallas obligatorias y no se quitó ningún endpoint,
pero cambian la hora, algunos estados y llegan avisos nuevos. Todo lo de
abajo está en el código de `backend/src`; los mensajes son los de Nest.

### Para todos los roles

- **Hora simulada (RF-31).** Al conectar al socket `/telemetry`, y cada vez
  que el administrador la cambia, llega `clock` a **todos**:
  `{ now: "2026-11-06T15:04:10.000Z", speed: 1 | 2 | 4 | 8, paused: boolean }`.
  La hora de la app es `now + (ahora_real − hora_de_llegada) × speed` (sin
  avanzar si `paused`). Las cuentas regresivas van con esa hora: los 5 min
  del código (`expiresAt`), la ETA, las franjas de los programados y los
  vencimientos. A x8, los 5 min del código son 37,5 s reales. Las fechas que
  manda Nest (`createdAt`, `expiresAt`, `scheduledAt`…) ya vienen en hora
  simulada. JWT, OTP y el límite de intentos de login siguen en hora real.
  Sin `CONTROL_ENABLED` el reloj es el real a x1.
- **Más `order-status`.** Ahora también se anuncian por el socket: crear una
  urgencia o una urgencia entre centrales (`received`), rechazar
  (`rejected`), autorizar (`pending_load`, también desde HTTP) y vencer
  (`expired`). Si la app recargaba la lista a mano en esos casos, ya puede
  esperar el aviso.
- **`linkLost`** en `telemetry` y `hub-telemetry`: sin enlace, la posición
  es estimada hasta que el dron aterriza en su central. Mostrarla con otro
  aspecto ("Sin enlace").

### Solicitante

- **Incidente en vuelo (RF-34, RF-35).** Si el dron de una urgencia aterriza
  de emergencia o cae, el pedido vuelve de `in_flight` a `received` con
  `statusReason` «El dron tuvo un incidente en vuelo; el pedido vuelve a
  despacharse.» y entra otra vez a la oferta de las centrales. Otro dron lo
  lleva: pasa de nuevo por `pending_load` → `in_flight`. **El código de
  entrega cambia** al confirmar la carga otra vez (sale de `loadConfirmedAt`):
  hay que volver a pedir `GET /orders/:id/delivery-code` y no mostrar el
  anterior. Un programado con incidente sigue RF-18 (reintento o
  `reassigned`).
- **Paquete perdido:** con choque grave o dron perdido, `returnOutcome` puede
  ser `lost` (además de `restocked` y `quarantined`).

### Despachador

- **Central sin energía (RF-36, CU-45).** `powerOutageUntil` en la central
  (`null` con energía). Mientras dure, `POST /orders/:id/authorize` y
  `POST /orders/:id/confirm-load` responden **409** «La central está sin
  energía: no puede autorizar ni confirmar cargas hasta que vuelva.». Las
  urgencias pasan a otra central; lo autorizado sin cargar suelta el dron con
  `statusReason` «La central se quedó sin energía; el pedido pasa a otra
  central o se reintenta.». Avisos nuevos en la bandeja: `hub_outage` y
  `hub_power_restored`.
- **Vuelos en curso.** `GET /orders/in-flight` incluye los pedidos
  `delivered` cuyo dron todavía vuelve vacío a la central. Mostrarlos como
  "Volviendo a la central", no como "Entregado".
- **Despachador automático (RF-37).** Si la consola lo enciende, autoriza y
  confirma la carga en cualquier central. El pedido trae `autoDispatched:
  true`; mostrar "Autorizado por el despachador automático". Un despachador
  real puede seguir trabajando a la vez: lo que el automático ya tomó
  responde los errores de siempre (ya autorizado, ya cargado).
- **Incidentes.** Una urgencia entre centrales con incidente vuelve a la cola
  de su central de origen (`received`, con el `statusReason` de arriba) y se
  autoriza y carga otra vez. Un pedido puede tener varias misiones; la
  vigente es la última. El paquete que vuelve tras un aterrizaje de
  emergencia entra a la cuarentena con el motivo `incident` (además de
  `cold_chain` y `packaging`).
- **Traza del motor.** Una central sin energía sale con la nota «La central
  está sin energía.».

### Operador de flota

- **Estado nuevo del dron: `grounded`.** Aterrizó de emergencia fuera de su
  central y espera el rescate. Al rescatarlo pasa a `maintenance` con un
  periodo que abrió el sistema (`openedByUserId` nulo). Tras un choque grave
  queda `out_of_service`; un dron perdido, `out_of_service` de inmediato.
  Los conteos de `GET /fleet/map` traen `grounded` junto a los demás.
- **Socket `hub-incident`** en la sala de la central (`subscribe-hub`, el
  operador): `{ id, orderId, droneId, hubId, kind, severity, leg, protocol,
  outcome, latitude, longitude, batteryPercent, landingLatitude,
  landingLongitude, rescueDueAt, packageOnBoard, packageLost, occurredAt,
  resolvedAt }`. No trae el medicamento.
  - `protocol`: `continue`, `return_to_hub`, `emergency_landing`, `crash`
    o `lost`.
  - `outcome`: `continued`, `returning`, `returned`, `landing`, `grounded`,
    `rescued` o `lost`.
  - `kind`: los de `IncidentKind` (`battery_critical`, `wind_limit`,
    `route_blocked`, `battery_short`, `battery_degraded`, `motor_failure`,
    `dual_motor_failure`, `gps_loss_minor`, `gps_loss_major`, `link_loss`,
    `cooling_failure`, `collision_minor`, `collision_major`, `drone_lost`).
  - Con `landingLatitude`/`landingLongitude` se dibuja dónde bajó el dron.
- **Alerta nueva:** `alert` con `kind: 'wind_limit'` (el viento pasa del
  límite del Wingcopter donde va el dron).
- **Geovallas temporales (RF-36).** `GET /geofences` trae `expiresAt`: con
  fecha es temporal (la puso la consola y vence sola); `null`, del operador.
  Mostrarlas distinto y con la hora de vencimiento.
- **Ruta cambiada en el aire (RF-33).** `GET /fleet/flights` y
  `GET /fleet/map` traen la ruta nueva; el aviso llega por `hub-reroute`
  (§18.2).

### Administrador

- **KPI nuevas** en `/analytics`: `incidentRate` (incidentes por cada 100
  misiones que despegaron; meta verde ≤ 2, ámbar ≤ 5) y `groundings`
  (drones que no volvieron a su central: aterrizaje de emergencia, choque
  grave o dron perdido; verde 0, ámbar 1).
- **Solicitantes simulados.** Los pedidos que genera la consola salen de
  cuentas `simulated` («Solicitante simulado 1» … 4, correo `.invalid`, sin
  documento ni celular). Nadie inicia sesión con ellas.

**La app lo usará** para que las cuentas regresivas coincidan con la TV
durante la demostración, para no mostrar un código viejo después de un
incidente y para que el operador y el despachador vean incidentes, apagones
y drones en tierra con sus estados reales.

## 18. Huecos entre backend, web y app (`learning/32`)

Lo que cambia el contrato al cerrar los huecos del 2026-11-10. Cada punto
sale en su propia rama.

### 18.1 Incidentes abiertos en `GET /fleet/map` — Hecho (rama `feature/fleet-incidentes-en-mapa`)

Antes los incidentes solo llegaban por `hub-incident`: si el operador abría
el mapa después, no los veía. Ahora el mapa los trae al abrirse.

- **Campo nuevo `incidents`** junto a `hubs`, `geofences` y `flights`: los
  incidentes **sin resolver** (`resolvedAt` nulo) de las centrales del
  operador, o solo de `hubId` si viene en la consulta. Primero el más
  reciente.
- **Misma forma que `hub-incident`** (§17): `{ id, orderId, droneId, hubId,
  kind, severity, leg, protocol, outcome, latitude, longitude,
  batteryPercent, landingLatitude, landingLongitude, rescueDueAt,
  packageOnBoard, packageLost, occurredAt, resolvedAt }`. No trae el
  medicamento, el lote ni la cantidad (RNF-05).
- **Abiertos** son los que siguen en `returning`, `landing` o `grounded`.
  Los `continued` y `lost` nacen resueltos y no salen; un `returned` o
  `rescued` deja de salir al cerrarse.
- Un `hubId` que no es suyo sigue respondiendo **403**.

**La app lo usará** para pintar el incidente al abrir el mapa (F2) y dejar
que `hub-incident` solo lo actualice.

### 18.2 Aviso de reruteo al operador: `hub-reroute` — Hecho (rama `feature/aviso-reruteo-operador`)

Antes el cambio de ruta en el aire (RF-33) solo llegaba a la consola web
(`radar-reroute`). Ahora también va a la sala de la central del vuelo, por
socket y sin aviso guardado en la bandeja (decisión D1).

- **Evento `hub-reroute`** para quien está en la sala con `subscribe-hub` y
  recibe vuelos (el operador de flota, como `hub-telemetry`). El
  despachador no lo recibe.
- **Cuerpo:** `{ hubId, orderId, droneId, outcome, addedKm, crossesGeofence,
  batteryShort }`.
  - `outcome: 'rerouted'`: hay ruta nueva; `addedKm` dice cuánto se alarga.
    Recargar el vuelo con `GET /fleet/flights` para dibujarla.
  - `outcome: 'blocked'`: no hay camino seguro (`addedKm: null`,
    `crossesGeofence: true`). Sigue el protocolo de RF-34 y llega su
    `hub-incident` (`route_blocked`).
  - `batteryShort: true`: la ruta nueva no alcanza con la reserva; llega
    también un `hub-incident` (`battery_short`).
- La central es la de origen del pedido, la misma de `hub-telemetry`.

**La app lo usa** (rama `feature/aviso-reruteo-app`): el mapa del operador
muestra "Ruta cambiada (+X km)" con "Ver vuelo" y vuelve a pedir
`/fleet/map` para dibujar la ruta nueva; en ámbar con `blocked` o
`batteryShort`. Con un desvío de menos de 50 m (`addedKm` 0) dice solo
"Ruta cambiada".

## 19. Solicitud de urgencia (`learning/33`)

Lo que cambia el contrato al rehacer la urgencia (RU-02, RF-41, RF-42).

### 19.1 Tamizaje, paciente a cargo y alergias — Hecho (rama `feature/urgencia-triage`)

`POST /orders/emergencies` acepta campos nuevos. Todo es compatible con la
app anterior: sin `triage`, la `description` sigue siendo obligatoria.

- **`triage`** (RF-41): `{ redFlags: RedFlag[], patientGroup, pregnant?,
  symptoms: Symptom[] (al menos 1), onset, severity }`.
  - `redFlags`: `breathing_difficulty`, `chest_pain`, `seizure`,
    `uncontrolled_bleeding`, `fainting`, `severe_allergy`. Vacío es
    "Ninguno".
  - `patientGroup`: `baby`, `child`, `adult`, `older_adult`. Un bebé no
    puede ir con `pregnant: true` (400).
  - `symptoms`: `fever`, `pain`, `breathing`, `allergy`, `blood_sugar`,
    `blood_pressure`, `infection`, `stomach`, `other`.
  - `onset`: `hours`, `today`, `days`. `severity`: `mild`, `moderate`,
    `severe`.
- **`description`**: la nota corta; opcional con `triage`.
- **`allergies`** (texto, hasta 200): vacío es "ninguna"; sin el campo, no
  se preguntó. Si el paciente es el titular, se guarda en la cuenta y
  `GET /auth/me` la devuelve en `allergies` para llenar la siguiente urgencia.
- **`patient`** (RF-42), opcional: `{ fullName (3–80), documentType,
  documentNumber, relation }`.
  - `documentType`: `civil_registry`, `identity_card`, `citizenship_id`,
    `foreigner_id`, `ppt`. `relation`: `child`, `parent`, `partner`,
    `relative`, `dependent`.
  - Bajo fórmula con `patient`, la fórmula es de esa persona: no se mandan
    `patientDocumentType` ni `patientDocumentNumber` (400 si vienen). Sin
    `patient`, siguen siendo el documento de la cuenta, como antes.
  - El titular no puede ponerse a sí mismo como persona a cargo (400).
- **`address`** pasa a ser la referencia opcional (hasta 160); sin ella
  queda "Punto marcado en el mapa". **`latitude` y `longitude`** son
  obligatorias.

`POST /orders/plans` también acepta `patient` y la referencia opcional, y
exige el punto. Cada entrega del plan copia al paciente.

El pedido (`GET /orders/:id`, la cola y las listas) trae `triage` (o
`null`), `allergies` y `patient` (o `null` si es el titular).
`GET /orders/queue` ordena primero lo reasignado, después las urgencias con
un signo de alarma y luego por llegada. El tamizaje y las alergias no van
a logs, métricas ni radar.

Las urgencias del generador de la consola traen un tamizaje de venta libre;
1 de cada 10 con un signo de alarma.

**La app ya usa** la referencia opcional en vez de la dirección, con "Usar
mi ubicación" (F1, rama `feature/ubicacion-gps`). **Ya manda** el tamizaje, las
alergias y el paciente a cargo (F4, rama `feature/urgencia-por-pasos`): la
urgencia va en 3 pasos (qué pasa, qué necesitas, dónde), la entrega
periódica pregunta para quién es, el despachador ve la tarjeta "Tamizaje" y
la cola marca en rojo las urgencias con un signo de alarma.

### 19.2 Fórmula en PDF o hasta 3 fotos — Hecho (rama `feature/formula-pdf`)

- **Envío** (`POST /orders/emergencies` y `POST /orders/plans`): campo nuevo
  `prescriptions: [{ mime, base64 }]`, con un solo PDF o de 1 a 3 fotos JPG o
  PNG, sin mezclarlos. Cada archivo pesa hasta **5 MB** y el backend revisa
  sus primeros bytes (un JPG renombrado a PDF responde 400). Los campos
  `prescriptionMime` y `prescriptionImageBase64` siguen sirviendo para un
  solo archivo (la app anterior). El cuerpo admite hasta 22 MB.
- **Mensajes 400:** "La fórmula va en un solo PDF o en 1 a 3 fotos, sin
  mezclarlos.", "La fórmula debe ser un PDF o una foto JPG o PNG.", "Cada
  archivo de la fórmula debe pesar hasta 5 MB.", "El archivo de la fórmula
  no es válido." y, sin archivos, "La venta bajo fórmula exige la fórmula:
  un PDF o de 1 a 3 fotos."
- **Lectura** (solo despachador):
  - `GET /orders/:id/prescription/files` → `{ files: [{ index, mime,
    filename }] }`.
  - `GET /orders/:id/prescription/:index` → el archivo, con
    `Content-Disposition: inline; filename="formula-1a2b3c4d-2.jpg"` y
    `Cache-Control: no-store`. Una hoja que no existe responde 404.
  - `GET /orders/:id/prescription` sigue devolviendo la primera hoja.
- **Quién la ve:** la central que tiene el pedido en su cola o su agenda
  (ahora también los programados, no solo las urgencias) y, después de
  autorizar, la central que lo autorizó, en cualquier estado, desde su
  histórico. A las demás les responde 404, como si el pedido no existiera.
- **Base:** `prescription_images` gana `position` y el único pasa a
  `(orderId, position)`; la clave del objeto llega a 48 caracteres
  (`{uuid}-2.jpg`, `{uuid}.pdf`). Lo hace `ensure-prescription-bucket.ts`
  al arrancar, también en producción, y el bucket acepta PDF hasta 5 MB.

**La app ya manda** `prescriptions` (F2, rama `feature/formula-pdf-camara`):
"Tomar foto" con la cámara y "Subir archivo" para un PDF o fotos, con la
miniatura y la X de cada uno. **Ya lee** las hojas en el visor del despachador (F3, rama
`feature/visor-formula`): zoom, PDF por páginas, "Abrir con…" desde una
copia temporal y "Ver fórmula" en un pedido que su central ya autorizó.

