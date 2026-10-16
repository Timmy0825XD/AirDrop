# Avance del frontend después de auth

Plan por fases del frontend Flutter a partir de la guía 25 (`learning/25-front-pending-despues-de-auth.md`, local y fuera de git). Todo agente que entre al repo lee este archivo para saber en qué fase vamos.

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
| 5 | Entrega del pedido y retorno del dron | — | Bloqueada (backend) |
| 6 | Revisión y rediseño del administrador | `style/rediseno-admin` | Hecha (PR #47) |
| 7 | Revisión y rediseño del despachador | `style/rediseno-despachador` | Hecha (PR #48) |
| 8 | Revisión y rediseño del solicitante y el operador | `style/rediseno-solicitante-operador` | Hecha (PR pendiente) |
| 9 | Limpieza antes de la revisión | `refactor/limpieza-front` | Pendiente |
| 10 | Cierre y pruebas de punta a punta | `test/flujos-front` | Pendiente |

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

Bloqueada: todo es del backend y lo hace otra persona del equipo. El detalle
de lo que falta está en [`pendientes-backend.md`](pendientes-backend.md)
(punto 1). Cuando Nest lo tenga, esta fase hace la parte de la app: el código
para el que recibe, la pantalla para ingresarlo con la cuenta regresiva de
5 min, la vuelta del dron en el mapa y la marca del empaque al recibir un
retorno.

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

## Fase 10 — Cierre y pruebas de punta a punta

- Paso 1: Recorrer con el backend real los flujos de la sección 10 de la guía 25, de punta a punta en los cuatro roles.
- Paso 2: Corregir lo que aparezca.
- Paso 3: Anotar en [`pendientes-backend.md`](pendientes-backend.md) lo que le falta al backend.
- Paso 4: Cerrar la fase.

## Pendiente del backend

Vive en [`pendientes-backend.md`](pendientes-backend.md), para que la persona
del backend lo encuentre en un solo lugar. Cada fase lo va llenando.

## Arreglos del backend hechos por nosotros

- PR #44 (`fix/socket-y-vuelos-en-curso`): carrera en `TelemetryGateway` (`subscribe` espera la validación del token) y `GET /orders/in-flight` para el despachador.
- PR #46 (`fix/pedido-despachador-404`): `canRead` deja abrir las urgencias de la cola (`isWaitingForHub`) y `TelemetryRedis` se suscribe al canal al conectar.
