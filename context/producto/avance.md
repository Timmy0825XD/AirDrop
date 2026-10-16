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
| 4 | Geovalla sobre el mapa (HU-14) | `feature/geovalla-mapa` | Hecha (PR pendiente) |
| 5 | Revisión y rediseño del administrador | `style/rediseno-admin` | Pendiente |
| 6 | Revisión y rediseño del despachador | `style/rediseno-despachador` | Pendiente |
| 7 | Revisión y rediseño del solicitante y el operador | `style/rediseno-solicitante-operador` | Pendiente |
| 8 | Limpieza antes de la revisión | `refactor/limpieza-front` | Pendiente |
| 9 | Cierre y pruebas de punta a punta | `test/flujos-front` | Pendiente |

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

## Fases 5 a 7 — Revisión a fondo y rediseño por rol

Muchas pantallas de los roles vienen de una versión anterior y tienen errores
(Oscar encontró varios al probar la Fase 3). Por eso cada una de estas fases
**primero revisa y corrige**, y después rediseña. Mismo lenguaje visual de la
Fase 1. Una rama por rol para que cada PR sea revisable.

- Paso 1: Revisión rincón por rincón de cada pantalla del rol, contra el
  backend real: cada lista, cada detalle, cada botón y cada mensaje. Anotar
  cada error con cómo reproducirlo.
- Paso 2: Mostrarle a Oscar la lista de errores y acordar cuáles se corrigen
  aquí y cuáles son del backend.
- Paso 3: Corregir los errores del frontend, con un test por cada uno cuando
  se pueda.
- Paso 4: Aplicar el diseño a los homes y pantallas del rol, sin cambiar
  rutas ni bodies.
- Paso 5: Partir los widgets de más de 60 líneas.
- Paso 6: Actualizar los tests que verifican textos.
- Paso 7: Cerrar la fase (resumen de errores corregidos incluido).

### Errores ya conocidos (para la revisión)

- ~~**Despachador:** pedidos de la cola que al abrirlos se quedan cargando y
  terminan en "El pedido no existe."~~ Corregido en
  `fix/pedido-despachador-404` (2026-10-16): la cola muestra urgencias
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
- **Despachador:** no hay lista de vuelos en curso en el frontend; al
  despegar, el pedido sale de la cola y de pending-load. Nest ya tiene
  `GET /orders/in-flight` (rama `fix/socket-y-vuelos-en-curso`); falta la
  bandeja con su tarjeta en el home.

## Fase 8 — Limpieza antes de la revisión

Va en su propia rama porque `AGENTS.md` pide no mezclar limpieza con una historia de usuario.

- Paso 1: Buscar otra vez archivos, widgets, clases y paquetes sin uso (las fases 1 a 7 dejan cosas nuevas y viejas). Candidato ya visto: el paquete `cupertino_icons`.
- Paso 2: Mostrarle a Oscar la lista final para que apruebe cada borrado.
- Paso 3: Borrar lo aprobado y quitar los paquetes sin uso.
- Paso 4: Regenerar `frontend/docs/ui_inventory.md` con `frontend/tools/ui_inventory.ps1`.
- Paso 5: `flutter analyze` y `flutter test`.
- Paso 6: Cerrar la fase.

## Fase 9 — Cierre y pruebas de punta a punta

- Paso 1: Recorrer con el backend real los flujos de la sección 10 de la guía 25.
- Paso 2: Corregir lo que aparezca.
- Paso 3: Anotar aquí lo que le falta al backend.
- Paso 4: Cerrar la fase.

## Pendiente del backend (no lo resuelve el frontend)

- Fallback con estado `reasignado` (RF-18); hoy solo responde 409.
- Código de entrega, espera de 5 min, retorno y cuarentena (Sprint 6).
- Bandeja de telemetría del operador (RU-18, CU-19): la API no le dice qué pedido lleva su dron.
## Arreglos del backend hechos por nosotros (`fix/socket-y-vuelos-en-curso`, 2026-10-16)

- Carrera en `TelemetryGateway`: `handleConnection` guarda la validación del token como promesa (`ready`) y `subscribe` la espera, así que un `subscribe` inmediato ya no responde "El pedido no existe.". El reintento de 800 ms del frontend (`TelemetryClient.retryDelay`) queda sobrando; se quita en la revisión del frontend.
- `GET /orders/in-flight` (solo despachador): pedidos de su central en `in_flight` o `awaiting_delivery`, con `assignment`, del más reciente al más viejo. La bandeja del frontend llega en la Fase 6.
