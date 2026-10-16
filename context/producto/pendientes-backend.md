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

## 1. Entrega, retorno y cuarentena — Pendiente

La pieza más importante: sin ella el ciclo de la sustentación se corta.

**Hoy.** Al aterrizar, el pedido queda en `awaiting_delivery` y el dron en
`in_mission` para siempre. No hay código de entrega ni endpoint para
ingresarlo, y el operador tampoco puede liberar el dron (`FleetService`
responde "No puedes cambiar el estado de un dron en misión.").

**Debería** ([`entregas/persona.md`](../entregas/persona.md),
[`entregas/centrales.md`](../entregas/centrales.md),
[`entregas/productos.md`](../entregas/productos.md)):

1. Al confirmar la carga se genera un **código de un uso** para el pedido.
   Lo ve quien recibe: el solicitante (entrega a persona) o el despachador de
   la central de destino (traslado entre centrales).
2. Un endpoint para ingresar el código en destino. Válido → pedido
   `delivered`, el dron vuelve a su central (tramo de retorno) y al aterrizar
   queda `available`.
3. Si en **5 minutos** no llega un código válido: pedido `returning`, el dron
   vuelve **con el paquete**; al aterrizar, pedido `returned` y dron
   `available`.
4. **Cuarentena** al volver: sin alerta de frío y con el empaque íntegro, el
   lote puede reingresar al inventario de origen; con alerta de frío o si el
   despachador marca el empaque comprometido, no reingresa.
5. En un traslado recibido bien (remisión que coincide y sin alerta de frío),
   el lote entra al inventario de la central de destino.
6. El reloj publica por el socket los estados nuevos (`order-status`) y la
   telemetría del retorno, igual que en la ida.

**Tests** que pide `AGENTS.md`: código a tiempo, timeout de 5 min con
retorno y paquete, cuarentena con y sin alerta de frío.

**La app lo usará** para: mostrar el código al que recibe, la pantalla para
ingresarlo con la cuenta regresiva, la vuelta del dron en el mapa y la
marca del empaque al recibir un retorno.

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

## 6. Lo que una central le pide a otra — Pendiente

**Hoy.** El despachador puede pedir una urgencia a otra central
(`POST /orders/hub-emergencies`), pero después no la encuentra en ninguna
lista: `GET /orders/mine` es solo del solicitante y la cola, los
programados y las bandejas listan lo que sale **de** su central, no lo que
le llega. Solo la ve en el detalle que se abre al crearla. Los
abastecimientos sí aparecen en `GET /orders/plans`.

**Debería** ([`../entregas/centrales.md`](../entregas/centrales.md): la
central de destino recibe el traslado): listar los pedidos cuyo destino es
la central del despachador, con su estado (por ejemplo
`GET /orders/incoming`), para seguirlos hasta que lleguen.

**La app lo usará** en el inicio del despachador: una bandeja "Por recibir"
junto a "Vuelos en curso", y más adelante para ingresar el código de
entrega del traslado (punto 1).
