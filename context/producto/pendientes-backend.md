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

## 1. Entrega, retorno y cuarentena — En parte hecho (PR #56, #62, #63, #65, #66, #68, #70, #71)

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

**Falta:**

1. **Cuarentena al volver** (sin hacer): sin alerta de frío y con el
   empaque íntegro, el lote reingresa al inventario de origen; con alerta de
   frío o si el despachador marca el empaque comprometido, no. Depende
   también del punto 9 (temperatura).
2. **Traslado recibido** (sin hacer): el lote entra al inventario de la
   central de destino.
3. **La ruta de regreso no viaja en el pedido.** `assignment.coordinates`
   es solo la ida (el documento de la demo menciona `returnRoute`, pero Nest
   no lo envía); en el regreso la app pinta la misma línea.
4. **El aviso de intentos agotados promete más de lo que pasa.** Dice "El
   dron regresa con el paquete", pero el pedido sigue en `awaiting_delivery`
   hasta que vencen los 5 minutos; recién ahí sale el dron.

**Tests** que pide `AGENTS.md` y faltan: cuarentena con y sin alerta de frío.

**La app lo usará** para: la ruta de regreso en el mapa y la marca del
empaque al recibir un retorno.

## 2. Fallback con estado `reasignado` (RF-18) — Pendiente

**Hoy.** Si ningún dron es elegible, autorizar responde 409 y nada más.

**Debería** ([`../../INDEX.md`](../../INDEX.md), RF-18): sugerir una
alternativa en vez de rechazar (otra central con stock y dron, o esperar), y
dejar el pedido en `reassigned` cuando se acepta.

**La app lo usará** en el detalle del despachador (Fase 7).

## 3. Telemetría para el operador (RU-18, CU-19) — Pendiente

**Hoy.** El operador puede abrir el socket, pero ninguna ruta le dice qué
pedido lleva cada dron, así que la app no tiene desde dónde abrir el mapa.

**Debería:** listar los vuelos en curso de sus centrales (o devolver el
`orderId` activo en cada dron de `GET /fleet/drones`).

**La app lo usará** en la flota del operador (Fase 8).

## 4. Métricas del administrador — Pendiente

**Hoy.** No hay módulo `Analytics`: ningún endpoint de métricas.

**Debería** ([`../app/roles.md`](../app/roles.md): "el administrador … ve
las métricas"; dashboard epidemiológico simple del MVP en
[`../../INDEX.md`](../../INDEX.md)): agregados **sin identificar personas**,
por ejemplo pedidos por estado y por tipo de misión, tiempo medio de
entrega, entregas por central y por municipio, y drones por estado.

**La app lo usará** en el inicio del administrador (Fase 6 deja el espacio
listo con un aviso de "próximamente" hasta que exista).

## 5. Flota de una central para el administrador — Pendiente

**Hoy.** `GET /fleet/drones?hubId=` permite el rol `admin` en el
controlador, pero `FleetService.listDrones` llama `assertAssigned`, y el
administrador no tiene centrales asignadas: siempre responde 403 "Esa
central no está asignada a tu cuenta.".

**Debería:** decidir una de dos y dejarla consistente:

- el administrador ve los drones de cualquier central (saltar
  `assertAssigned` cuando el rol es `admin`), o
- quitar `admin` del `@Roles` de esa ruta.

**La app** hoy no la usa; si se abre, se mostraría en el detalle de una
central.

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

## 7. Cambiar el correo sin verificarlo — Pendiente

**Hoy.** `PATCH /auth/me` cambia el correo de una vez si no está tomado.
El login y la recuperación de contraseña usan ese correo, así que un error
de tipeo deja a la persona sin poder entrar ni recuperar la cuenta.

**Debería** (RNF de seguridad en [`requisitos.md`](requisitos.md)): mandar
un código al correo nuevo y cambiarlo solo cuando se confirme, como en el
registro.

**La app lo usará** en el perfil: al guardar un correo nuevo, la misma
pantalla de seis cajas del registro para confirmarlo.

## 8. Editar una central — Pendiente

**Hoy.** Una central solo se crea y se suspende o reactiva. Si el nombre,
la dirección o el contacto quedan mal escritos (pasó en las pruebas de la
Fase 10), no hay forma de corregirlos: hay que crear otra y suspender la
mala.

**Debería** ([`../app/roles.md`](../app/roles.md): el administrador
gestiona las centrales): `PATCH /hubs/:id` para nombre, tipo, dirección,
ubicación y contacto, con las mismas validaciones del alta.

**La app lo usará** en la tarjeta de cada central del administrador
("Editar"), reusando el formulario de Nueva central.

## 9. Alerta de temperatura fuera de rango (RF-17, HU-32) — Pendiente

**Hoy.** Si el ítem lleva frío, el reloj publica `temperatureC` fija en 5 °C
durante todo el vuelo. Nunca sale de rango y no hay alerta, así que la
cuarentena del punto 1 (cuando exista) no tiene en qué apoyarse.

**Debería** ([`../entregas/productos.md`](../entregas/productos.md),
[`requisitos.md`](requisitos.md) RF-17): comparar la temperatura simulada con
el rango en ida, espera y retorno; fuera de rango, emitir una alerta por el
socket (`alert`) y dejar marcado el pedido para la cuarentena.

**La app lo usará** en la ficha del vuelo y al marcar el empaque.

## 10. Vencimiento del token (`JWT_EXPIRES_IN`) — Pendiente

**Hoy.** `auth.module.ts` fija el token en 8 horas y no lee `JWT_EXPIRES_IN`
(`.env.example` dice `2h`).

**Debería** ([`../../AGENTS.md`](../../AGENTS.md): "JWT con expiración"): leer
la variable, o quitarla de `.env.example` y dejar las 8 horas documentadas.

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
