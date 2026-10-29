# Avance del frontend después de auth

Plan por fases del frontend Flutter a partir de la guía 25 (`learning/25-front-pending-despues-de-auth.md`, local y fuera de git). Todo agente que entre al repo lee este archivo para saber en qué fase vamos.

## Dónde está el proyecto hoy (2026-10-19)

| Historias | Estado |
| --- | --- |
| HU-01 a HU-05 (auth), HU-06 a HU-10 (centrales, inventario, cuentas), HU-11 a HU-14 (flota y geovallas) | Backend y frontend hechos |
| HU-15 a HU-20 (pedidos, planes, cola, historial) | Backend y frontend hechos |
| HU-21 a HU-23 (decisión, prioridad, rutas) | Backend y frontend hechos |
| HU-25 a HU-28, HU-35 (simulación, telemetría, mapa, confirmar carga) | Backend y frontend hechos, con el tramo de regreso |
| HU-33, HU-34 (código de entrega, espera de 5 min y retorno con el paquete) | Backend (PR #56, #62, #63, #65, #66) y frontend (Fase 5) hechos; falta la cuarentena |
| HU-29, HU-30 (avisos de estado y batería) | Backend publica `order-status` y `alert` por el socket; no hay push |
| HU-31 (flag de frío) | Hecho; la temperatura simulada es fija (5 °C), sin alerta de rango |
| HU-24 (fallback) | Backend hecho (`feature/fallback-reasignacion`); el frontend todavía trata el 409 "sin dron", que ya no llega (ver punto 2 de pendientes) |
| HU-32 (alerta de frío) | Backend hecho (`feature/alerta-frio`); falta que la app muestre la alerta `cold_chain` y `coldChainAlert` |
| La cuarentena de HU-34 y el inventario de los traslados | Backend hecho (`feature/cuarentena-inventario`); la app debe mandar `remissionMatches` y `sealIntact` al recibir un traslado (hoy da 400) y usar `return-check` |
| HU-36 a HU-38 (histórico de central, dashboard, métricas) | Backend hecho (`feature/metricas-admin`: `/analytics/*` y `GET /orders/history`); el frontend sigue con la tarjeta "PRÓXIMAMENTE" |

Lo que le falta a Nest, con el documento que lo pide, está en [`pendientes-backend.md`](pendientes-backend.md). Las reglas de `context/` describen el MVP completo: donde el código va atrás, manda el contexto y se anota aquí o en esos pendientes, no se reescribe el contexto.

## Cómo se trabaja una fase

1. Se crea una rama nueva desde `develop`. No se trabaja en `develop` ni en `main`.
2. Se siguen los pasos en orden (Fase N · Paso M). Cualquier cambio fuera de los pasos se consulta antes.
3. Al cerrar: se actualiza este archivo y los `.md` que apliquen, se corren `flutter analyze` y `flutter test`, y se entrega el resumen de lo hecho junto con el commit y el título y body del PR. El commit, el push y el PR los hace una persona del equipo.

## Estado

| Fase | Tema | Rama | Estado |
| --- | --- | --- | --- |
| 0 | Preparación y documento de avance | `docs/plan-fases-front` | Hecha (PR #39) |
| 1 | Rediseño de auth con transiciones | `style/rediseno-auth` | Hecha (PR #40) |
| 2 | Autorizar y confirmar carga (HU-21, HU-35) | `feature/autorizar-carga-front` | Hecha (PR #41) |
| 3 | Telemetría y mapa en vivo (HU-26 a HU-28) | `feature/tracking-front` | Hecha (PR #43) |
| 4 | Geovalla sobre el mapa (HU-14) | `feature/geovalla-mapa` | Hecha (PR #45) |
| 5 | Entrega del pedido y retorno del dron | `feature/entrega-fase5`, `fix/entrega-demo` | Hecha (PR #72); ajustes para la demo (PR pendiente) |
| 6 | Revisión y rediseño del administrador | `style/rediseno-admin` | Hecha (PR #47) |
| 7 | Revisión y rediseño del despachador | `style/rediseno-despachador` | Hecha (PR #48) |
| 8 | Revisión y rediseño del solicitante y el operador | `style/rediseno-solicitante-operador` | Hecha (PR #49) |
| 9 | Limpieza antes de la revisión | `refactor/limpieza-front` | Hecha (PR #50) |
| 10 | Cierre y pruebas de punta a punta | `test/flujos-front` | Hecha (PR #51) |
| 11 | Rediseño visual total "Grafito y turquesa" | `style/rediseno-total-temporal` | En revisión (sin PR) |

## Fase 0 — Preparación y documento de avance

- Paso 1: Resolver el cambio pendiente en `frontend/macos/Flutter/GeneratedPluginRegistrant.swift`.
- Paso 2: Crear este archivo.
- Paso 3: Enlazarlo desde `context/index.md`, `INDEX.md` y `frontend/AGENTS.md`.
- Paso 4: Copiar la guía 25 a `learning/`.
- Paso 5: Correr `flutter analyze` y `flutter test` para conocer la base. Resultado (2026-10-15): analyze sin issues, 123 tests en verde.
- Paso 6: Cerrar la fase.

## Fase 1 — Rediseño de auth con transiciones

Referencia visual: canvas "AirDrop · Auth transiciones" en Claude Design (https://claude.ai/artifact/93zRSvo1BoLixvXs9dzjqC). Solo pantallas de `features/auth/presentation/`. No cambia carpetas, rutas ni bodies.

Se trabaja pantalla por pantalla: se termina una, Oscar la prueba en el emulador y aprueba antes de pasar a la siguiente. En cada carpeta que se toca se borra lo que deja de usarse.

Decisiones (2026-10-15): el tema nuevo es global (toda la app pasa al verde azulado y a Plus Jakarta Sans); el login correcto termina en el home real del rol; toque sutil de glassmorfismo (tarjeta del formulario, logo y pastilla de la ciudad); el logo es provisional hasta que el equipo lo defina.

Avance por pantalla:

- [x] Login: splash al abrir la app y al cerrar sesión, morph al encabezado, campos con temblor y error, botón que se vuelve dron, círculo de salida al inicio. Aprobado por Oscar.
- [x] Registro: el encabezado se encoge desde el login, formulario de lado, selector de documento deslizante, consentimiento en tarjeta y botón apagado hasta aceptarlo. Volver al login no repite el splash. Aprobado por Oscar.
- [x] Verificar cuenta: encabezado de paso con volver y "Paso 2 de 2", ícono con rebote, seis cajas sobre un campo invisible, temblor y error, reenvío a los 45 s con barra que se vacía; al verificar, las cajas se juntan en el check y el círculo lleva al inicio. Aprobado por Oscar.
- [x] Recuperar contraseña: el encabezado se encoge desde el login, la llave gira al entrar, correo con temblor y error, el botón se vuelve el dron y regresa como "Ingresar el código" junto a la confirmación de Nest. Aprobado por Oscar.
- [x] Nueva contraseña y contraseña actualizada: código en seis cajas con "Solicitar otro código" a los 45 s, medidor de fuerza por segmentos, check que gira al coincidir y aviso en vivo si no; al actualizar, el círculo cubre la pantalla, el verde se encoge al encabezado y el sello con el check aparece con el dron orbitando.
- [x] Perfil: solo toma el tema nuevo; no tiene diseño propio en el canvas. Sus widgets viejos quedan listados en `frontend/AGENTS.md`.

Pendientes que deja la fase:

- Cambiar la animación de la ruta del splash del login (el trazo que se dibuja): a Oscar no le convence; se define más adelante.
- Definir el logo; hoy va un ícono provisional.
- Rediseñar el perfil y quitar con él `AuthPage`, `LoginGlassCard`, `LoginButton` y `LoginPalette` (los dos últimos pasan de 60 líneas).

- Paso 1: Tokens del diseño en `theme/` (fondo `#F5F6F3`, acento `#0B7A75`, dron `#E8743B`, modo oscuro, Plus Jakarta Sans).
- Paso 2: Widgets animados compartidos en `auth/presentation/widgets/`: encabezado curvo con morph, botón que se encoge a loader con el dron, campo con temblor y error deslizante, escala al tocar.
- Paso 3: Splash como estado inicial del login, que se repite cada vez que se entra a la pantalla; el bloque de color se encoge en el encabezado.
- Paso 4: Login ↔ Registro con morph del encabezado y deslizamiento horizontal.
- Paso 5: Login correcto: revelado circular hacia el inicio del rol.
- Paso 6: Verificar cuenta: las cajas OTP se juntan en el check.
- Paso 7: Recuperar contraseña, Nueva contraseña y Contraseña actualizada.
- Paso 8: Reducir movimiento (`MediaQuery.disableAnimations`), `dispose()` de cada controller, widgets de máximo 60 líneas.
- Paso 9: Ajustar los widget tests (las etiquetas siguen en MAYÚSCULAS).
- Paso 10: Cerrar la fase.

## Fase 2 — Autorizar y confirmar carga (HU-21, HU-35)

- Paso 1: `OrderAssignment` y `loadConfirmedAt` en `Order`, con parseo tolerante.
- Paso 2: `authorize`, `confirmLoad` y `listPendingLoad` en el contrato y en las versiones remote y local.
- Paso 3: Detalle del despachador: Autorizar (con "Verifiqué la fórmula" cuando aplica), Confirmar carga, dron y ruta asignados.
- Paso 4: `pending_load_screen` y tarjeta "Pendiente de carga" en el home.
- Paso 5: Router: ruta, guard y `/orders/pending-load` en `_fixedOrderRoutes`.
- Paso 6: Tests (`order_assignment_test` y los existentes).
- Paso 7: Cerrar la fase.

Resultado (2026-10-15):

- `Order` lee `assignment` (dron y corredor `[lng, lat]`) y `loadConfirmedAt`; `awaitsLoad` dice si falta confirmar la carga.
- `OrderDispatchNotifier` reúne rechazar, autorizar y confirmar carga, y refresca cola, programados, bandeja y detalle.
- Detalle partido en `widgets/order_detail/`; `DispatcherPermissions` decide qué acciones ve el despachador según su central.
- Bandeja `/orders/pending-load` con su tarjeta en el home (apagada con la central suspendida).
- "Ver vuelo" no está todavía: llega en la Fase 3 con `/tracking/:orderId`.
- Limpieza: el historial reusa `OrderTile`; se borró `home_info_card.dart` (sin uso).
- `flutter analyze` sin issues; 139 tests en verde.

## Fase 3 — Telemetría y mapa en vivo (HU-26 a HU-28)

- Paso 1: `socket_io_client`, `flutter_map` y `latlong2` en `pubspec.yaml`.
- Paso 2: `telemetry_models.dart` (vistas map y full) con tests.
- Paso 3: `telemetry_client.dart`: GET inicial y socket (suscripción, reconexión, cierre).
- Paso 4: `tracking_providers.dart`.
- Paso 5: `tracking_screen` con mapa, ruta, ficha y fase de vuelo (`userAgentPackageName` en el `TileLayer`).
- Paso 6: Router: `/tracking/:orderId` en `_parameterizedRole`.
- Paso 7: Botones "Ver vuelo" en historial, detalle y pending-load.
- Paso 8: Cerrar la fase.

Resultado (2026-10-16):

- `features/tracking/` nueva: modelos (`Telemetry`, `FlightVitals`, `FlightPhase`, `FlightAlert`), `TelemetryClient` (GET + socket `/telemetry`, sin Riverpod) y `TrackingNotifier`.
- Ojo con la guía 25: Nest responde `subscribe` con los **eventos** `subscribed` o `error`, no con ack. El cliente escucha esos eventos.
- Mapa `/tracking/:orderId` (solicitante y despachador de origen): ruta del pedido, dron en vivo, ficha y avisos ("El vuelo está por empezar", "El dron llegó…").
- "Ver vuelo" en el detalle, el historial y la bandeja (cuando la carga ya está confirmada). `Order.hasFlight` decide cuándo.
- El operador no abre el mapa: la API no le lista pedidos.
- Pendiente fuera de esta fase: `AndroidManifest.xml` principal no declara `INTERNET`; en builds de *release* el mapa y la API no cargarían.
- Encontrado al probar con Nest (2026-10-16): `TelemetryGateway.handleConnection` valida el token sin que Nest lo espere, así que un `subscribe` inmediato recibe "El pedido no existe.". El cliente reintenta una vez a los 800 ms; el arreglo de fondo es del backend.
- Encontrado al probar: el despachador no tiene lista de vuelos en curso (el pedido sale de la cola y de pending-load al despegar). Por ahora el aviso de "Carga confirmada" lleva "Ver vuelo"; hace falta un endpoint en Nest.
- `flutter analyze` sin issues; 149 tests en verde.

## Fase 4 — Geovalla sobre el mapa (HU-14)

- Paso 1: Modo "dibujar" del mapa, sin socket.
- Paso 2: Polígono con taps, cerrado al enviar.
- Paso 3: Usarlo al crear y editar geovallas.
- Paso 4: Cerrar la fase.

Resultado (2026-10-16):

- `AppMap` (`core/widgets/app_map.dart`): el único mapa de la app (tiles de OpenStreetMap, crédito, centro en Valledupar) y las conversiones `[lng, lat]` ↔ `LatLng`. `FlightMap` lo usa en vez de repetir los tiles.
- Modo dibujar `GeofenceDrawScreen`: pantalla completa, sin socket ni llamadas a Nest. Cada toque pone un vértice numerado; tocar un vértice lo quita; Deshacer y Borrar todo; "Listo" se prende con 3 vértices y devuelve los puntos al formulario.
- El formulario de crear y editar muestra el polígono en una vista previa quieta (`GeofencePolygonPreview`) con "Dibujar en el mapa" / "Editar en el mapa". El anillo se sigue cerrando al guardar (`GeoJsonPolygon.fromVertices`).
- El mapa va a pantalla completa porque, dentro del scroll del formulario, arrastrar el mapa peleaba con el scroll.
- Error encontrado y corregido: `flutter_map` revienta con una línea sin puntos. Le pasaba a `FlightMap` cuando el pedido aún no trae ruta; ahora la línea solo se pinta con 2 puntos o más (test `flight_map_test`).
- Limpieza: se borraron `PolygonPointFields` y `GeofenceVertex` (las filas de longitud y latitud a mano); `GeofenceFormValues` guarda los vértices como lista.
- `flutter analyze` sin issues; 154 tests en verde.

## Fase 5 — Entrega del pedido y retorno del dron

Rama `feature/entrega-fase5`. Se desbloqueó con los PR #56, #62, #63, #65 y
#66 del backend (código de entrega, espera de 5 min, vuelo de regreso,
entrega en la central de destino y traslados entrantes).

Lo que hace la app:

- **`features/delivery/`** (nueva): `DeliveryRepository` (local y remoto)
  con `generate` y `validate`, y `ReceiveOrderScreen` en
  `/delivery/:orderId`. Al abrir pide el código, lo muestra con la cuenta
  regresiva hasta `expiresAt` y ofrece el "teclado del dron" simulado. Con
  el código correcto las cajas se juntan en el check y el pedido queda
  entregado; al vencer avisa que el dron vuelve con el paquete y apaga el
  botón. Los errores de Nest salen tal cual.
- **"Recibir pedido"** en el detalle (solicitante, y despachador de la
  central de destino con `DispatcherPermissions.canReceive`), en Mis
  pedidos, en Traslados entrantes y en el mapa del solicitante cuando el
  dron aterriza.
- **Traslados entrantes** (`/orders/incoming`): bandeja nueva del
  despachador con lo que otras centrales le envían, y tarjeta en su inicio
  con el contador de lo que está por recibir.
- **Regreso en el mapa**: la telemetría lee `leg` (`FlightLeg`), "Ver vuelo"
  sigue disponible en `returning` y el aviso del mapa dice entregado, de
  regreso con el paquete o devuelto según el estado del socket.
- 7 tests nuevos en `test/features/delivery/delivery_test.dart`: código y
  vencimiento, el tramo de regreso no cuenta como llegada, solo la central
  de destino recibe, aviso de retorno, código equivocado y correcto, espera
  vencida y error de Nest al pedir el código.

Probado contra Nest real (con `DELIVERY_WAIT_MS=60000` y datos `PRUEBA-`
que se borraron al terminar):

- **Entrega a tiempo**: el dron aterriza (`awaiting_delivery`); validar sin
  pedir código falla; el código trae 6 dígitos y vencimiento; otra central
  no puede pedirlo (404); el equivocado da 400 con el mensaje de Nest; el
  correcto deja `delivered`; no sirve dos veces; el dron queda disponible.
- **Espera vencida**: a los 60 s pasa a `returning`, la telemetría trae
  `leg: return`, ya no se puede pedir código, al aterrizar queda `returned`
  y el dron disponible.
- **Traslado**: aparece en entrantes de la central de destino, aterriza
  allí, la central de origen no puede recibirlo (404) y la de destino lo
  recibe con el código.

19 comprobaciones en verde. El primer intento falló porque la central de
prueba quedó dentro de la geovalla "Parque de la Leyenda": Nest hizo bien en
no autorizar.

- `flutter analyze` sin issues; 196 tests en verde.

Para el backend (en [`pendientes-backend.md`](pendientes-backend.md)): el
dron no vuela de regreso tras una entrega correcta, el código no tiene
límite de intentos, falta la cuarentena y el ingreso del traslado al
inventario (punto 1), y el seed de pruebas falla por los parámetros de la
limpieza (punto 11, nuevo). El punto 6 (traslados entrantes) quedó hecho.

Falta probar en el emulador: el teclado numérico del teléfono en el
"teclado del dron" y la cuenta regresiva con la app en segundo plano.

### Ajustes para la demo (`fix/entrega-demo`)

Mientras se mezclaba el PR #72, el backend cambió el contrato de la entrega
(PR #68, #70 y #71) y la app quedó desfasada: pedía el código con `POST`, y
Nest ahora lo da con `GET`. Este ajuste sigue el documento de la demo
(`DEMO_01_CAMBIOS_FRONTEND.md`):

- **Código de entrega**: `GET /orders/:id/delivery-code`, visible desde que
  se confirma la carga (`Order.deliveryCodeVisible`). `expiresAt` puede
  llegar `null` (dron en vuelo): la pantalla muestra el código, dice que el
  dron va en camino y lo vuelve a leer cada 10 s; al aterrizar arranca la
  cuenta y aparece el teclado con "Confirmar entrega". El botón dice "Ver
  código de entrega" en vuelo y "Recibir pedido" en tierra.
- **Intentos agotados**: al quinto código equivocado se muestra el mensaje
  de Nest, se esconde el código y se apaga el botón.
- **Regreso tras entregar**: "Ver vuelo" sigue en el detalle de un pedido
  entregado y el mapa dice "Pedido entregado. El dron vuelve a su central".
- **Inventario**: al crear la cantidad mínima es 1 (al editar se permite 0)
  y el vencimiento debe ser posterior a hoy; el calendario empieza mañana.
  Mismos mensajes que Nest.
- Tests: 6 nuevos (código en vuelo y al aterrizar, intentos agotados, código
  sin límite, reglas de inventario) y los de entrega ajustados al contrato.
  `flutter analyze` sin issues; 202 tests en verde.

Probado contra Nest real (`DELIVERY_WAIT_MS=60000`, datos `PRUEBA-`
borrados al terminar), 23 comprobaciones en verde: inventario con cantidad 0
y vencimiento de hoy rechazados; sin carga no hay código; en vuelo el código
llega con `expiresAt: null` y en tierra es el mismo con hora límite;
equivocado da 400 y el correcto entrega; tras entregar el dron sigue en
misión, la telemetría marca `leg: return` con el pedido entregado y al
aterrizar queda disponible; cinco equivocados bloquean (ni el correcto
entrega), vence, vuelve y queda devuelto; el traslado lo ve la central de
destino en vuelo, la de origen no (404), y la de destino lo recibe.

No se cambió: la tarjeta "Traslados entrantes" (el documento la llama "Por
recibir") ni la ruta de regreso en el mapa, porque Nest no envía
`returnRoute` (pendiente 1.3).

## Fases 6 a 8 — Revisión a fondo y rediseño por rol

Muchas pantallas de los roles vienen de una versión anterior y tienen errores
(Oscar encontró varios al probar la Fase 3). Por eso cada una de estas fases
**primero revisa y corrige**, y después rediseña. Mismo lenguaje visual de la
Fase 1: animaciones fluidas y limpias, que se noten sin recargar. Una rama
por rol para que cada PR sea revisable. Se revisa **carpeta por carpeta**
todo lo del rol: errores, código repetido o sin uso, comentarios viejos.

- Paso 1: Revisión rincón por rincón de cada pantalla del rol, contra el
  backend real: cada lista, cada detalle, cada botón y cada mensaje. Anotar
  cada error con cómo reproducirlo.
- Paso 2: Diseño en Claude Design para que Oscar lo vea y lo apruebe antes
  de tocar código.
- Paso 3: Mostrarle a Oscar la lista de errores y acordar cuáles se corrigen
  aquí y cuáles van a [`pendientes-backend.md`](pendientes-backend.md).
- Paso 4: Corregir los errores del frontend, con un test por cada uno cuando
  se pueda.
- Paso 5: Aplicar el diseño a los homes y pantallas del rol, sin cambiar
  rutas ni bodies.
- Paso 6: Partir los widgets de más de 60 líneas y limpiar lo que sobre.
- Paso 7: Actualizar los tests que verifican textos.
- Paso 8: Cerrar la fase (resumen de errores corregidos incluido).

### Fase 6 — Administrador

Alcance: su inicio (`home/presentation/admin_home.dart` y el `HomeShell`
que comparte), centrales (`features/hubs/`, menos `/hubs/me`, que es del
despachador) y cuentas institucionales (`features/users/`).

Diseño aprobado: la **primera versión** del canvas "AirDrop · Administrador"
en Claude Design (https://claude.ai/artifact/98W1NSNrgPAayAVSvXgFyF). Las tres
direcciones de la segunda fila (con Impeccable y Emil Kowalski) se probaron y
Oscar no las eligió.

Resultado (2026-10-16):

- Inicio: encabezado curvo con marca, perfil y salir, pastilla
  "Administrador" y el dron de fondo que se mece; tarjeta de números sobre la
  curva (centrales activas, cuentas activas, suspendidas) que cuentan desde 0;
  accesos con contador y Métricas en "Próximamente" (Nest no tiene el
  módulo). Los números salen de `allHubsProvider` y `allUsersProvider`.
- Centrales: `SectionHeader` con el filtro deslizante montado en la curva,
  tarjetas con ícono por tipo, estado y acción, y la hoja de confirmación.
- Nueva central: la ubicación se toca en el mapa (`HubLocationPicker`, con el
  mismo `AppMap`); ya no se escriben latitud y longitud. Tipo en chips.
- Cuentas: filtro de rol deslizante y chips de estado; tarjetas con iniciales,
  rol y las centrales asignadas.
- Nueva cuenta: tarjetas de rol, campos de auth, medidor de contraseña y
  centrales en chips.

Errores corregidos:

1. Cuenta bloqueada: ofrecía "Activar" y Nest respondía 409; ahora ofrece
   "Suspender" (`UserLabels.canReactivate`).
2. Nueva cuenta decía "Sin él no llegan alertas por SMS" y Nest no manda SMS.
3. Sin centrales activas, Nueva cuenta quedaba con un selector vacío; ahora lo
   dice, ofrece "Crear central" y el botón queda apagado.
4. La lista de cuentas no mostraba sus centrales; ahora las muestra.
5. `assignableHubsProvider` nunca se refrescaba: una central recién creada
   no salía en Nueva cuenta. Ahora sale de `allHubsProvider`.

Limpieza:

- Piezas compartidas nuevas en `core/widgets` (`StatusPill`, `StatusCard`,
  `RowActionButton`, `ChoicePill`, `SlidingSegmented`, `showConfirmSheet`,
  `FormSheetCard`, `MessageView`, `RiseIn`, `PressScale`, `CountUpText`) en
  vez de dos o tres copias por feature. `AuthMorphButton` usa `PressScale`.
- Cerrar sesión salió de `HomeShell` a `signOut`, que comparten los inicios.
- Borrados: `HubFilterTabs`, `HubStatusChip`, `hub_toggle_confirm`,
  `HubCoordinateFields`, `HubLocationFields`, `HubContactFields`,
  `HubFormContent`, `UserFilterTabs`, `UserStatusChip`, `user_toggle_confirm`,
  `UserRoleField` (repetía los nombres de rol de `ProfileLabels`),
  `UserIdentityFields`, `UserFormContent`, `UserFormContentBody`,
  `HubMultiSelect`, `isSelf` de `UserTile` (Nest no lista administradores) y
  `Validators.latitude` / `longitude` con sus tests.
- Imports que subían de más en `hubs/data` y `users/data` puestos a la
  profundidad correcta. Comentarios del plan viejo quitados.
- Pendiente para la Fase 7: `HubDetailContent` (`/hubs/me`, del despachador)
  pasa de 60 líneas.
- `flutter analyze` sin issues; 167 tests en verde.

### Fase 7 — Despachador

Además de la revisión: la bandeja **"Vuelos en curso"** con su tarjeta en
el home (Nest ya tiene `GET /orders/in-flight`, PR #44) y quitar el
reintento de 800 ms de `TelemetryClient`, que sobra desde ese PR.

Diseño: sin canvas propio. Oscar pidió seguir el lenguaje de la Fase 6
(encabezado curvo, tarjetas con estado, hojas inferiores, entrada en
cascada).

Resultado (2026-10-16):

- Inicio: el mismo encabezado del admin (`RoleHero`) con la central y su
  estado; sobre la curva, cuántas urgencias hay en cola, cuántos drones por
  cargar y cuántos en vuelo (`HomeStatsCard`); accesos en tres grupos
  (operación, mi central, pedir a otra central) con contador y candado si la
  central no está activa. Se refresca cada 10 s. "Pedir a otra central" ya
  no abre una hoja: Urgencia y Abastecimiento son dos accesos.
- Bandejas (cola, programados, pendiente de carga, vuelos en curso y mis
  planes) sobre un mismo andamiaje, `OrderTray`: encabezado con cuántas
  hay, tarjetas que entran en cascada, deslizar para recargar y el error
  de Nest centrado.
- Vuelos en curso: `/orders/in-flight` con el dron en naranja, el estado y
  "Ver vuelo".
- Detalle del pedido: el nombre del insumo en el encabezado, las secciones
  en tarjetas con ícono teñido, Autorizar y Confirmar carga con el botón que
  se vuelve dron, "Verifiqué la fórmula" en un chip y Rechazar plegado
  hasta que se abre (el motivo tiembla si falta).
- Urgencia y Abastecimiento a otra central: central de origen e insumo en
  chips (con el stock), cantidad con su máximo, frecuencia en chips y la
  fecha de inicio en el calendario.
- Planes: tarjetas con estado; el detalle muestra el plan, sus entregas
  (tocables) y Extender / Cancelar con la hoja de confirmación.
- Mi central: identidad con estado, el mapa con el pin y el contacto.
- Inventario: tarjetas con vencido / por vencer / vigente y "Eliminar" con
  la hoja de confirmación; el formulario va en la tarjeta sobre la curva,
  con el vencimiento en el calendario y el tipo de venta en chips.

Errores corregidos:

1. Las pantallas viejas no tenían flecha de volver y el mapa quedaba sin
   salida: se abrían con `go`. Ahora las bandejas usan `SectionHeader`, los
   detalles y el mapa se abren con `push` y vuelven con
   `SectionHeader.backOrHome` (test `dispatcher_fixes_test`).
2. Inventario: el interruptor de cadena de frío no se movía al tocarlo
   (guardaba el valor sin repintar). Test `inventory_form_test`.
3. Inventario: el vencimiento se escribía a mano; ahora es un calendario
   (`AuthDateField`).
4. Abastecimiento: la fecha de inicio quedaba fija en hoy; ahora se elige
   (test `hub_request_values_test`).
5. Detalle del plan: cada entrega mostraba el id interno del dron (UUID);
   ahora muestra fecha y estado y abre su detalle.
6. Los errores que no eran de Nest se veían crudos (`FormatException: …`);
   ahora pasan por `ApiException.messageOf`.
7. Urgencia y Abastecimiento guardaban estado tras cerrar la pantalla si
   Nest respondía con error; ahora revisan `mounted`.
8. Código repetido: Urgencia y Abastecimiento copiaban el mismo formulario
   (ahora `HubRequestValues`, `HubRequestFields`, `HubRequestScaffold`);
   las tarjetas de cola y programados estaban armadas dentro de la
   pantalla; `HubDetailContent` pasaba de 60 líneas.
9. Mi central mostraba latitud y longitud sueltas; ahora va el mapa.
10. Para el backend: una central no puede ver las urgencias que le pidió a
    otra. Anotado en [`pendientes-backend.md`](pendientes-backend.md),
    punto 6.

Limpieza:

- Compartidas nuevas: `RoleHero`, `HomeStatsCard` y `HomeAccessCard` (eran
  `AdminHero`, `AdminStatsCard` y `AdminActionCard`; ahora las usan admin y
  despachador), `DetailSection` / `DetailLine` en `core/widgets`,
  `AuthDateField` + `pickIsoDate` y `AuthChoiceGroup` junto a `AuthField`,
  `PillTone.neutral` en `StatusPill`, `routeLine` en `order_format`.
- `OrderStatusChip` y `OrderKindChip` pasan a `StatusPill` (el color dice
  si el pedido va bien, vuela o se cortó).
- Borrados: `DispatcherCards`, `HubDetailRow`, `InventoryFormContent`,
  `InventoryFields`, `InventorySaleTypeField`, `InventoryColdChainSwitch` y
  `inventory_chips.dart`.
- `TelemetryClient` sin el reintento de 800 ms.
- Ojo para la Fase 8: el detalle del pedido y los planes también los usa el
  solicitante, así que ya tienen el diseño nuevo; el historial
  (`OrderTile`), sus formularios y su inicio siguen con el viejo. Las
  pantallas de admin, flota y geovallas todavía muestran `'$error'`: pasarlas a
  `ApiException.messageOf` en la Fase 8 o la 9.
- `flutter analyze` sin issues; 179 tests en verde.

### Fase 8 — Solicitante y operador

Además de la revisión: el **perfil** con diseño propio (y con él se borran
`AuthPage`, `LoginGlassCard`, `LoginButton` y `LoginPalette`), la nueva
animación de la ruta del splash del login y el logo definitivo si el equipo
ya lo tiene. Operador: flota y geovallas.

Sin canvas propio: el mismo lenguaje de las fases 6 y 7. **El splash y el
logo quedan para después** (Oscar, 2026-10-16): siguen pendientes.

Resultado (2026-10-16):

- Inicio del solicitante: `RoleHero` con "Solicitante", números sobre la
  curva (en curso, volando, planes activos) y accesos Pedir urgencia,
  Entrega periódica, Mis pedidos (naranja si hay un dron en camino) y Mis
  planes. Se refresca cada 10 s.
- Urgencia y entrega periódica: tarjeta sobre la curva con el medicamento
  en chips (copo si va en frío), la fórmula con vista previa y el documento
  legible, la dirección y **el punto en el mapa** (`AuthLocationField`),
  más cantidad, frecuencia y calendario en la entrega periódica.
- Mis pedidos: `OrderTray` con tarjetas de estado y "Ver vuelo".
- Inicio del operador: sus centrales en el encabezado, drones disponibles,
  en misión y en taller, y accesos a Flota y Geovallas con contador.
- Flota: centrales en chips bajo el encabezado, tarjetas de dron con el
  dron dibujado, hoja de acciones nueva y el mantenimiento en hoja con
  calendario. Nuevo dron con el formulario nuevo y el modelo en chips.
- Geovallas: tarjetas con sus vértices, hoja de confirmación al eliminar
  y formulario nuevo (el modo dibujar no cambia).
- Perfil: encabezado, tarjeta con las iniciales en el color del rol, "Tus
  datos" editables en una hoja inferior, las centrales por nombre y
  Cerrar sesión con `signOut`.

Errores corregidos:

1. La urgencia y la entrega periódica dejaban la ubicación opcional y Nest
   no autoriza sin coordenadas (`MISSING_DESTINATION`): el despachador
   nunca podía sacar el pedido. Ahora el punto en el mapa es obligatorio
   (test `requester_order_test`).
2. La fórmula mostraba el documento crudo (`citizenship_id …`); ahora
   "Cédula de ciudadanía · …".
3. Errores crudos y `setState` tras cerrar la pantalla en urgencia,
   entrega periódica e historial.
4. Urgencia y entrega periódica copiaban medicamento, fórmula y ubicación:
   ahora comparten `RequesterOrderValues`, sus campos y
   `RequesterOrderState`. `HubRequestScaffold` pasó a `OrderFormScaffold`
   y lo usan las cuatro formas de pedir.
5. Historial y formularios sin flecha de volver.
6. La entrega periódica revisaba un stock que el catálogo del solicitante
   no trae; se quitó.
7. Con la central suspendida, la flota ofrecía gestionar drones (Nest
   responde 403); ahora la tarjeta dice "Sin cambios" (test
   `fleet_fixes_test`).
8. La fecha del mantenimiento se escribía a mano; ahora calendario.
9. Errores crudos en flota, nuevo dron, geovallas y en las pantallas del
   admin (centrales, cuentas, nueva cuenta) y el inicio.
10. Flota y geovallas sin flecha de volver.
11. El botón de notificaciones del perfil no hacía nada; se quitó.
12. El perfil decía "Central operativa vinculada" sin decir cuál; ahora
    nombra las centrales (test `profile_sections_test`).
13. Cerrar sesión desde el perfil repetía su lógica; ahora usa `signOut`.
14. Textos raros del perfil ("Mi cuenta aeromédica", "PROTOCOLO DE
    DESCONEXIÓN") fuera.
15. Encontrado al rediseñar: "Mantenimiento" en la flota pintaba el texto
    del mismo color que su fondo y no se leía; el estado del dron ahora va
    en `StatusPill`.
16. Para el backend: cambiar el correo no pide verificarlo. Anotado en
    [`pendientes-backend.md`](pendientes-backend.md), punto 7.

Limpieza:

- Compartidas nuevas: `AuthLocationField` (era `HubLocationPicker`, ahora
  también del solicitante), `OrderFormScaffold`, `maxLines` en
  `AuthField`. Los inicios de los cuatro roles usan `RoleHero`.
- Borrados: `HomeShell`, `HomeActionCard`, `AuthPage`, `auth_ambience`
  (`AuthGlow`, `AuthEntrance`, `AuthPulsingDot`), `LoginGlassCard`,
  `LoginButton`, `LoginPalette`, `AppTextField`, `PrimaryButton`, los
  widgets viejos del perfil (`ProfileContent`, `ProfileTopBar`,
  `ProfileInfoList`, `ProfileLogoutRow`, `ProfileEditDialog`,
  `ProfileDataSection`, `ProfileStates`), `MaintenanceFormDialog`,
  `DroneFormContent`, `GeofenceFormContent`, `GeofenceFields`,
  `ProfileLabels.organization` / `limitFor`, `parseCoord` e `isoOf`.
- `LoginAlert` toma sus colores del tema.
- `flutter analyze` sin issues; 189 tests en verde.

### Errores ya conocidos

- ~~**Despachador:** pedidos de la cola que al abrirlos se quedan cargando y
  terminan en "El pedido no existe."~~ Corregido en
  `fix/pedido-despachador-404` (PR #46): la cola muestra urgencias
  civiles sin central de origen a toda central con stock, pero
  `GET /orders/:id` solo dejaba leer a la central de origen o destino. Ahora
  esa central también puede abrirlas mientras siguen en recibido. Además, un
  error de Nest ya no se reintenta 10 veces (`retryOnlyWithoutResponse`) y
  la cola, los programados, pending-load y el historial se refrescan solos
  cada 10 s (`AutoRefresh`).
- ~~**Mapa en vivo:** "Ver vuelo" muestra el primer dato pero no se mueve;
  hay que salir y volver.~~ Corregido en la misma rama: era del backend.
  Nest arranca los `onModuleInit` del módulo en paralelo y
  `TelemetryPublisher` se ponía a escuchar Redis antes de que la conexión
  abriera, así que nunca se suscribía al canal y el socket no recibía ni la
  telemetría ni los cambios de estado. Ahora `TelemetryRedis` guarda quién
  escucha y se suscribe al conectar (test `telemetry.redis.spec`).
- ~~**Despachador (Fase 7):** no hay lista de vuelos en curso en el frontend;
  al despegar, el pedido sale de la cola y de pending-load.~~ Corregido en
  la Fase 7 con la bandeja "Vuelos en curso".

## Fase 9 — Limpieza antes de la revisión

Va en su propia rama porque `AGENTS.md` pide no mezclar limpieza con una historia de usuario.

- Paso 1: Buscar otra vez archivos, widgets, clases y paquetes sin uso (las fases 1 a 8 dejan cosas nuevas y viejas). Candidato ya visto: el paquete `cupertino_icons`.
- Paso 2: Mostrarle a Oscar la lista final para que apruebe cada borrado.
- Paso 3: Borrar lo aprobado y quitar los paquetes sin uso.
- Paso 4: Agregar el permiso `INTERNET` al `AndroidManifest.xml` principal (sin él, un APK de release no carga ni el mapa ni la API).
- Paso 5: Imports relativos que suben de más (`../../../../core` desde `data/`): resuelven solo porque Dart ignora los `..` que pasan de la raíz del paquete. Ponerlos a la profundidad correcta en las features que no toquen las fases 6 a 8.
- Paso 6: Regenerar `frontend/docs/ui_inventory.md` con `frontend/tools/ui_inventory.ps1`.
- Paso 7: `flutter analyze` y `flutter test`.
- Paso 8: Cerrar la fase.

Oscar dejó la fase andando sin estar (2026-10-16) y aprobó por adelantado
los borrados del Paso 2: el listado queda abajo para revisarlo en el PR.

Resultado (2026-10-16):

- **Archivos sin uso:** ninguno. Cada `.dart` de `lib/` lo importa otro
  archivo de `lib/` (no solo un test).
- **Borrado por no tener uso:** `Validators.isoDate` y `Validators.otp`
  (con sus tests; las fechas van en calendario y el código en
  `OtpCodeField`), y `FieldLimits.droneModelName`, `prescriptionMime` y
  `droneModelCode`.
- **Paquete quitado:** `cupertino_icons` (nadie usa `CupertinoIcons`).
- **`INTERNET`** en el `AndroidManifest.xml` principal; debug y profile ya
  lo traían.
- **Imports:** 12 imports en `fleet/data`, `geofences/data` e
  `inventory/data` subían un `../` de más; quedaron a la profundidad
  correcta. Ningún otro archivo sale de `lib/`.
- **`frontend/.gitattributes`:** los archivos que regenera `flutter pub
  get` (`generated_plugin*` de Linux y Windows y el `.swift` de macOS) se
  marcan `eol=lf`. Sin esto, en Windows salían como modificados en cada
  fase aunque no cambiaran (el pendiente del Paso 1 de la Fase 0).
- **Código repetido unificado:**
  - `ToneTile` (`core/widgets`): el cuadro de ícono teñido que repetían 7
    tarjetas (centrales, dron, geovalla, inventario, vuelo, bandejas,
    accesos del inicio).
  - `SectionFormPage` / `SectionStatePage` (`home/presentation/widgets`):
    encabezado + tarjeta sobre la curva + botón, que repetían los
    formularios de central, cuenta, inventario, geovalla, dron y los
    cuatro de pedidos.
  - `FormBottomSheet` (`core/widgets`): la hoja con formulario de editar
    perfil y de mantenimiento.
  - `pickFutureDate`: el calendario "de hoy a un año" que repetían
    abastecimiento, entrega periódica y mantenimiento.
- **Widgets de más de 60 líneas partidos** (según `ui_inventory.ps1`, que
  mide la clase entera): `AuthDateField`, `LoginAlert`, `DroneModelField`,
  `DroneStatusSheet`, `MaintenanceSheet`, `ProfileEditSheet`,
  `GeofenceDrawBar`, `DispatcherActions` (sus tarjetas pasaron a
  `dispatcher_cards.dart`), `AuthorizeSection`, `HubRequestFields`,
  `OrderFormScaffold` y `OrderTray`. Solo quedan sobre 60 los
  `*_values.dart` (`InventoryFormValues`, `HubRequestValues`,
  `RequesterOrderValues`, `UserFormValues`): guardan datos y validan, no
  pintan.
- `docs/ui_inventory.md` regenerado: 31 pantallas, 117 archivos de widgets.
- `flutter analyze` sin issues; 186 tests en verde (3 menos: eran de
  `Validators.isoDate`).

## Fase 10 — Cierre y pruebas de punta a punta

- Paso 1: Recorrer con el backend real los flujos de la sección 10 de la guía 25, de punta a punta en los cuatro roles.
- Paso 2: Corregir lo que aparezca.
- Paso 3: Anotar en [`pendientes-backend.md`](pendientes-backend.md) lo que le falta al backend.
- Paso 4: Cerrar la fase.

Resultado (2026-10-16):

Recorrido con Nest real (Oscar dejó el backend corriendo) y la app en web
(`flutter run -d web-server`, viewport de teléfono) en los cuatro roles.
Datos de prueba con sufijo "F10": centrales Hospital Rosario F10 y Clínica
Norte F10; Ana (despachadora del hospital), Luis (de la clínica), Sara
(operadora de las dos) y Carla (solicitante registrada desde la app).

Probado y funcionando:

- **Admin:** inicio con números reales, centrales (lista y Nueva central
  con el mapa), cuentas (Nueva cuenta). Nest rechaza un despachador con dos
  centrales con su mensaje.
- **Operador:** inicio, flota con chips de central, Nuevo dron (validación
  y alta), Gestionar → mantenimiento y disponible; un dron en misión no se
  puede tocar (409). Geovallas: crear dibujando, eliminar con la hoja.
- **Solicitante:** registro completo (datos, código, verificación, inicio),
  urgencia con el punto en el mapa, entrega periódica (8 entregas
  semanales), Mis pedidos y el mapa sin batería ni carga.
- **Despachador:** cola, fórmula (visor con la imagen y lista), autorizar
  (con y sin dron: el 409 "Ningún dron…" se muestra), rechazar con motivo,
  confirmar carga, mapa en vivo (fase, velocidad, altitud, batería, carga y
  latencia se actualizan), Vuelos en curso.
- **Reglas de Nest verificadas** (guía, sección 10): la Morfina no se
  ofrece; fórmula con otro documento y venta libre con foto se rechazan;
  sin "Verifiqué la fórmula" no se autoriza; una urgencia le quita el dron
  al programado y la ocurrencia vuelve a Recibido; un programado futuro no
  se autoriza; entre centrales: la propia no es origen, Luis no autoriza
  (403), el pedido llega a la cola de Ana y pedir más que el stock da 400.

Errores encontrados y corregidos:

1. **Datos de la cuenta anterior al cambiar de sesión** (el más serio): los
   providers no se limpiaban al cerrar sesión; quien entraba después veía un
   rato la cola, la central o los pedidos del anterior. Ahora
   `sessionUserIdProvider` (en `auth_controller.dart`) lo miran los seis
   repositorios: otra cuenta, todo se vuelve a pedir.
2. **Pantallas en blanco al recargar**: los `switch` sobre `AsyncValue`
   trataban la recarga (cada 10 s en las bandejas) como "cargando". Ahora
   `AsyncValue(hasValue: true, hasError: false, …)` sigue mostrando lo que
   había; un error sí se muestra. Números y subtítulos usan `.value` (el
   último conocido) y ya no parpadean a "—".
3. **Morado de Material**: el botón flotante, "Ver vuelo" y las hojas
   salían en el morado por defecto. El esquema sale ahora de
   `ColorScheme.fromSeed` con el verde de marca y el botón flotante tiene
   tema propio.
4. **Detalle desactualizado**: seguía en "Pendiente de carga" con el dron
   volando. Se refresca cada 10 s; al rechazar se vuelve a la lista (la
   central ya no puede abrir el pedido).
5. **Nueva cuenta sin las centrales recientes**: ahora pide las centrales
   al abrirse.
6. **Calendario en 2021**: sin fecha, el de vencimiento abría en la primera
   permitida; ahora abre en hoy. Elegir la fecha borra su aviso.
7. **Mapa del vuelo sin encuadre**: se creaba antes de llegar la ruta;
   ahora se vuelve a montar al llegar y muestra el pin del destino.
8. **Fórmula ilegible**: el visor mostraba el error técnico; ahora explica
   qué hacer.
9. **Textos**: "Te avisamos cuando despegue" (no hay notificaciones) pasó a
   "Síguela en Mis pedidos"; subtítulo de Nueva central que se cortaba.
10. **Pequeños**: con un solo modelo de dron viene elegido; la pastilla de
    ayuda del mapa ya no tapa el crédito de OpenStreetMap.

Lo que no se pudo probar aquí (va a la lista de Oscar en el emulador): el
botón físico de volver de Android, el teclado del teléfono, adjuntar una
foto desde la galería y la app de release con el permiso `INTERNET`.

Para el backend (en [`pendientes-backend.md`](pendientes-backend.md)): el
dron se queda "en misión" para siempre tras llegar (punto 1, ya anotado) y
el administrador no puede editar una central (punto 8, nuevo).

- `flutter analyze` sin issues; 189 tests en verde (3 nuevos en
  `fase10_fixes_test`).

## Fase 11 — Rediseño visual total "Grafito y turquesa"

Rama temporal `style/rediseno-total-temporal` desde `develop`. Solo apariencia: no cambian `data/`, rutas de API, bodies ni `appDataSource`. Propuesta aprobada por Oscar en el lienzo <https://claude.ai/artifact/Ay5RAswEtqiuxruk6Lzioi> (paleta medida de un póster de dron: grafito, turquesa y cielo).

Hecho (2026-10-28):

- Base: `AppPalette` (`context.palette`), Space Grotesk con cifras fijas, `AppBackdrop` (degradado con velos) y transición entre pantallas que sube y se funde, `AppMotion` (curvas y "reducir movimiento"). Modo claro derivado de los mismos tokens; todo pasa AA.
- Navegación: `RoleShell` + `FloatingNavBar` con botón central por rol (ver `frontend/AGENTS.md`, "Navegación por rol"). La barra se esconde al bajar y en detalles y formularios. Nueva pantalla "Más" del despachador y hoja de crear del administrador.
- Inicios de los cuatro roles: encabezado con contexto, cifra principal con el dron (`DroneArt`), cifras en cuadrícula (`MetricTile`, `BarSpark`, `RingGauge`) y accesos en cuadrícula (`QuickTile`) en vez de la lista de menú.
- Mapa: `AppMap` con tiles de OpenStreetMap teñidos (`AppMapStyle`), controles de vidrio, cámara suave, seguir al dron y Mapbox opcional por `--dart-define`. Vuelo, selector de ubicación y dibujo de geovallas a pantalla completa con hoja abajo (`MapSheetScaffold`), al estilo de una app de transporte.
- Auth: el bloque de marca pasa al degradado turquesa con luz y filo; el botón principal toma el degradado con halo. Se conservan el splash, el morph, el botón que se vuelve dron y las entradas en cascada.
- Listas, detalles y formularios heredan el vidrio (`GlassCard`, `StatusPill` con punto, `SectionHeader` sin curva).
- Ajustes tras la primera prueba de Oscar: editar una geovalla dejaba la vista previa del mapa en negro (el margen del encuadre era el de pantalla completa; `AppMap` ahora lo recorta al tamaño del mapa). El medicamento del solicitante y del despachador, y la central de origen, pasan de chips a `AuthPickerField` con buscador, para que 50 opciones no llenen la pantalla.
- Segunda ronda (2026-10-29): el filtro de color del mapa pasa a uno solo para toda la capa y la transición entre pantallas usa transiciones compuestas (causa probable de los cierres en Chrome); la cámara del mapa no se mueve antes del primer cuadro. Cuadrícula pareja `BalancedGrid` (telemetría e inicios). El solicitante ya no ve el regreso del dron. El operador tiene "Vuelos en curso" (`GET /fleet/flights`) y abre el mapa de cada dron en misión.
- Pendiente del backend: (1) rechazar un pedido cuyo destino cae dentro de una geovalla con un mensaje de zona prohibida, en vez de aplicar el fallback de reasignación (hoy sale "Reasignado" y además cuenta como en curso); (2) dejar que el operador lea `GET /orders/:id` (o mandar la ruta en `/fleet/flights`) para dibujarle el corredor. En el frontend sigue pendiente leer `fallbackKind`/`fallbackReason` (HU-24).
- Borrado: `RoleHero`, `HomeStatsCard`, `HomeAccessCard`, `AdminMetricsCard`, `DispatcherActions` y las tarjetas de `dispatcher_cards.dart`.
- `flutter analyze` sin issues y `flutter test` en verde (202). `docs/ui_inventory.md` regenerado: solo los `*_values` pasan de 60 líneas.

Pendiente:

- El render 3D del dron (imagen) reemplaza a `DroneArt` al final.
- La pantalla de agenda (`GET /orders/agenda`): hoy "Agenda" abre los programados.
- Métricas del administrador: Nest ya tiene `/analytics/*`, falta su capa `data/` en el frontend (la tarjeta queda con candado).
- Probar en el emulador y en Windows con el backend real (la telemetría del mapa necesita el socket).

## Pruebas de la Segunda Parte (parte de Oscar)

Guía: `GUIA_EJECUCION_PRUEBAS.md` (la comparte el equipo; no está en git).
Las capturas no se suben al repositorio; solo los archivos de prueba, en
ramas `test/...`.

| Fase | Qué | Estado |
| --- | --- | --- |
| T1 | Unitarias Jest: CU-20 (`fleet.cu20.spec.ts`, CP-20-01 a 10) y CU-10 (`orders.cu10.spec.ts`, CP-10-01 a 11) | Hecha, rama `test/unitarias-cu20-cu10` |
| T2 | Cypress (instalar) e integración descendente CD-06 a CD-10 | Hecha, rama `test/integracion-descendente` |
| T3 | Hilos de entrega CH-04 a CH-08 | Hecha, rama `test/integracion-hilos` |
| T4 | Aceptación con Swagger (CA005, CA006, CA009, CA010), Lighthouse, LambdaTest y ambiente | Hecha (manual, sin código) |

T1: 19 casos en verde y 2 en rojo **a propósito** (sección 8.1 de la guía):
CP-20-10 (mantenimiento sin motivo se acepta) y CP-10-11 (medicamento vacío
no da «El medicamento es obligatorio.»). No se corrigen hasta tener todas las
capturas. CU-10 fija el reloj en 2026-10-16 para que las fechas del documento
no cambien de resultado con los días.

T2: Cypress 16 en `backend/` (`pnpm test:int`); los casos van por la API
con `cy.request` y cada uno arranca con `seed:test` (task de Node, porque
Cypress 16 quitó `cy.exec`). 14 de 15 pasos en verde; CD-10 paso 2 sale
**Fallido**: una imagen de 3 MB recibe 413 (límite de 3 MB del JSON en
`main.ts`, la imagen en base64 pesa ~4 MB) y no el 400 «La imagen de la
fórmula debe pesar hasta 2 MB.». El paso 3 de CD-09 (Redis caído) se corre
aparte con el servidor sin Redis (`REDIS_CAIDO=1`).
Hallazgo de datos: la central A de `seed:test` (10.4631, -73.2532) queda
dentro de la geovalla de la demo «Zona de eventos Parque de la Leyenda», así
que nada sale de ahí; los despachos de las pruebas salen de la central B.

T3: CH-04 a CH-07 en Cypress (`cypress/e2e/ch-*.cy.js`) recorren el flujo
real hasta «en espera de entrega» (vuelo de ~2 min, necesita Redis) con
`DELIVERY_WAIT_MS=10000` al iniciar el servidor. CH-08 es Jest + supertest
(`orders.ch08.spec.ts`) con la caída de la base simulada (el `save` lanza
error): responde 500 y no queda pedido. 16 de 16 pasos en verde.

T4: sin código. Los cuatro casos de aceptación se probaron contra la API
real antes de capturarlos; CA005 usa WG-198-003 porque `seed:test` ya crea
WG-198-001 (responde 409). Lighthouse se corre sobre la compilación release
(`flutter run -d web-server --release --web-port 8080`): en modo depuración
sale NO_FCP. Accesibilidad 100; Rendimiento sin puntaje porque Flutter web
pinta en un lienzo. LambdaTest usa la misma dirección.

**Parte de Oscar cerrada.** Lo que falta (Josheph y Sebastián) y las
correcciones de la guía están en la versión actualizada de
`GUIA_EJECUCION_PRUEBAS.md`, que se comparte por fuera del repositorio.

## Pendiente del backend

Vive en [`pendientes-backend.md`](pendientes-backend.md), para que la persona
del backend lo encuentre en un solo lugar. Cada fase lo va llenando.

## Arreglos del backend hechos por nosotros

- PR #44 (`fix/socket-y-vuelos-en-curso`): carrera en `TelemetryGateway` (`subscribe` espera la validación del token) y `GET /orders/in-flight` para el despachador.
- PR #46 (`fix/pedido-despachador-404`): `canRead` deja abrir las urgencias de la cola (`isWaitingForHub`) y `TelemetryRedis` se suscribe al canal al conectar.
