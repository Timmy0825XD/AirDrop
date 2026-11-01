# AGENTS.md — frontend (Flutter)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/diseno/principios.md`](../context/diseno/principios.md).

## Qué es este lado

Una **sola** aplicación Flutter. Tras autenticarse, el usuario ve el flujo de **su rol**. No hay app web ni un segundo proyecto Flutter.

## Contexto de negocio que el frontend no debe perder

AirDrop simula logística aérea médica para Valledupar y zonas cercanas. El frontend representa cuatro roles: **solicitante** (persona civil, único registro público), **despachador** (una central, lo crea el admin), **operador de flota** (una o varias centrales, lo crea el admin) y **administrador**. La central no es un rol. No existe un rol receptor: la entrega se confirma con un código de un uso. La definición vigente está en [`../context/app/roles.md`](../context/app/roles.md). El contrato de `/auth` de abajo ya refleja ese registro solo del solicitante.

Flujo central que las pantallas deben respetar:

```text
pedido → autorización → decisión y ruta → confirmación de carga → vuelo simulado → código o retorno
```

Reglas de negocio que no deben contradecirse:

- Autorizar reserva/selecciona un dron, pero **no inicia el vuelo**.
- La simulación empieza únicamente después de que el despachador confirma la carga.
- Emergencia tiene prioridad sobre un pedido programado.
- La ruta debe evitar geovallas y trabajar a altitud/corredor fijo.
- En destino se esperan 5 minutos por el código; sin código, el paquete vuelve a la central. El reingreso al inventario sigue la cuarentena de [`../context/entregas/productos.md`](../context/entregas/productos.md).
- Si no hay dron elegible, se muestra fallback; no se rechaza ciegamente.
- Una urgencia o un plan puede pedirlo un civil (destino: su ubicación) o el despachador de otra central (destino: su central). Quien autoriza y carga es siempre el despachador de la central que tiene el insumo.
- El frontend no debe inventar hardware real, clima real, 3D, multi-ciudad ni un rol receptor.

La autoridad completa de negocio está en [`../context/index.md`](../context/index.md). Este resumen sirve para no perder el contexto durante una sesión de implementación.

## Avance por fases

Antes de empezar, leer [`../context/producto/avance.md`](../context/producto/avance.md): dice en qué fase vamos, su rama y sus pasos. Cada fase va en su propia rama desde `develop` y al cerrarla se actualiza ese archivo.

## Organización

Feature-first, alineado a dominios del backend:

```
lib/
  app/           # MaterialApp, rutas, inyección simple
  theme/         # ThemeData, colores, tipografía (única fuente de estilo)
  core/          # HTTP, storage, data source, validadores, widgets compartidos
  features/
    auth/
    hubs/
    inventory/
    fleet/
    geofences/
    users/
    orders/
    home/        # inicios por rol y andamiaje compartido (solo presentation/)
    tracking/    # mapa + telemetría en vivo (solicitante, despachador y operador)
    delivery/    # recibir el pedido con el código de un uso (sin rol receptor)
    analytics/   # métricas del administrador: KPI, demanda y ranking (`/analytics/*`)
    notifications/ # bandeja de avisos (`/notifications`), cualquier rol
```

No Clean Architecture de tres capas por feature “porque sí”. Suficiente:

- `data/` — modelos, repositorio (local|remote) y providers
- `presentation/` — pantallas, widgets y un controller/notifier (Riverpod: **uno** para todo el proyecto)

Elegir un gestor de estado y no mezclar tres.

### Estructura de `presentation/`

Cada feature sigue el mismo patrón, y vale repetirlo en todas:

```
presentation/
  <screen>_screen.dart      # estado, llamadas y armado del scaffold
  widgets/
    <subcarpeta>/           # un folder por pantalla
      <screen>_content.dart # el cuerpo visual, sin estado
      <screen>_fields.dart  # los campos del formulario
```

La regla: la pantalla tiene el `State` y los callbacks; los widgets solo pintan y
reciben datos por constructor. Ningún widget importa Riverpod salvo el
controller de la feature.

## UI

- Español de Colombia (RNF-15). Identificadores en inglés.
- Contraste y tamaños legibles (RNF-10).
- Reutilizar widgets. Ningún widget supera **60 líneas**; si pasa, se descompone. Se mide la clase entera con `tools/ui_inventory.ps1` (escribe `docs/ui_inventory.md`); los `*_values.dart` guardan datos y validan, no pintan, y no entran en la regla.
- `dart format` solo sobre los archivos que se tocaron: sobre carpetas enteras reformatea archivos ajenos y ensucia el PR.
- Tema solo en `lib/theme/`. Las pantallas leen `Theme.of(context)`.
- El mapa y el socket de telemetría se implementan **una vez** en `core` o `features/tracking` y se reutilizan.

### Sistema de diseño de Auth

Las pantallas de auth tienen identidad propia y **comparten andamiaje**. Antes de
armar una pantalla nueva, reusar lo que ya existe.

El rediseño de la Fase 13 (ver `../context/producto/avance.md`) cambió el
bloque de marca por **el espacio aéreo vivo**: un plano de la ciudad con las
centrales conectadas y drones de adorno, que se inclina en 3D. Es solo
decoración: no muestra datos ni contadores (nada de "drones en vuelo" ni
"entregas hoy" inventados). Sirve igual en claro y en oscuro; todos los
colores salen del tema. Piezas (en `widgets/` y `widgets/airspace/`):

| Widget | Para qué |
| --- | --- |
| `AirspaceMap` | El plano vivo (grilla, río, calles, centrales con la cruz médica, vuelos con estela y anillo al llegar). Lo mueven `network` (enciende la red), `traffic` (suelta los drones), `tilt` (lo inclina) y `dive` (la cámara se lanza adentro). Ya inclinado, se ladea un poco hacia el puntero. Con "reducir movimiento" queda quieto y sin drones. El dibujo vive en `AirspacePainter` y los vuelos en `AirspaceTraffic`. |
| `DroneMark` (`core/widgets`) | El dron de la marca visto desde arriba (lo usan también los inicios, el mapa y los pedidos): ala, largueros, cuatro hélices girando y luces de navegación (roja y verde) que destellan. Grafito en claro, claro en oscuro. `halo` dibuja su anillo en la entrada. |
| `AuthCurvedHeader` | El `AirspaceMap` recortado con las esquinas de abajo redondeadas y un velo arriba para leer el logo. Altura y curva se animan desde afuera (entrada → encabezado); el mapa no se deforma, solo cambia el recorte. |
| `AuthHeaderMetrics` | Alturas del encabezado: alto (login, `tallOf`), de paso (`stepOf`) y compacto (registro). El alto y el de paso crecen con la pantalla para que en un teléfono largo la hoja no quede vacía. Con ellas una pantalla arranca con la forma de la anterior. |
| `AuthBrandBar` / `AuthLogoTile` / `AuthPill` | Logo (`DroneMark`), nombre y pastilla de vidrio (con ícono opcional) en la esquina del encabezado. El logo es provisional. |
| `AuthFormSheet` | La hoja del formulario: sube desde abajo pegada a los bordes, con las esquinas de arriba redondeadas, scroll propio y su animación de entrada (desde abajo o de lado). |
| `AuthField` | Label en mayúsculas (con nota o `AuthFieldBadge` opcional a la derecha), caja de 56 px, temblor y mensaje deslizante cuando la pantalla pasa `errorText`. Dentro de la hoja los campos toman borde visible e ícono que se enciende al enfocar (tema local de `AuthSheetPanel`); fuera de auth no cambian. |
| `AuthMorphButton` | `ElevatedButton` que se encoge a círculo con el dron girando mientras carga; con `isDone` se pone verde y dibuja el check; los bordes son del todo redondos en toda la app (`pill: false` vuelve al radio 16); con `onPressed` en `null` queda apagado. |
| `AuthGlass` / `AuthChrome` / `AuthSheetPanel` | Vidrio esmerilado; el vidrio de las piezas sobre el mapa (pastilla, volver); la hoja del formulario, que en oscuro baja de grafito a casi negro y en claro de blanco a un cielo suave. Los títulos usan `authTitleStyle` (32, tracking cerrado). |
| `AirspaceReveal` | La salida al inicio: desde el botón se abre un círculo con el espacio aéreo, la cámara se lanza en picada y todo se funde en el fondo de la app. Con `dive: false` solo abre el mapa (lo usa la nueva contraseña). |
| `DroneGlyph` / `SpinningDrone` | El dron de líneas; quieto o girando como indicador de carga. |
| `AuthStepScaffold` | Pantallas de paso (código, recuperación, nueva contraseña): el mapa arriba con `AuthBackButton` y pastilla opcional, el `DroneMark` que baja trayendo el ícono del paso en una insignia del acento (flota; `turnIcon` lo endereza, como la llave) y la hoja con el contenido y la acción al fondo. `fromTall` cuando se llega desde el login y `fromStep` desde otra pantalla de paso. |
| `RegisterFlightPlan` | El avance del registro como plan de vuelo: tres puntos (identidad, contacto, acceso) que se encienden cuando cada grupo queda bien, y el dron avanza. Solo pinta; la validación al enviar no cambió. |
| `PasswordAltimeter` | La fuerza de la contraseña del registro como altímetro (barras, metros y "Crucero · Segura"), con `PasswordScore`. |
| `AuthTextLink` | "Pregunta + acción" centrados (¿No tienes cuenta? Regístrate). |
| `OtpCodeField` | Un campo invisible (acepta el autocompletado del código) y seis cajas que lo muestran; al verificar, las cajas se juntan en el check (`OtpSuccessCheck`). |
| `CheckMarkPainter` | Check que se dibuja de punta a punta; lo usan el consentimiento, el botón y el código. |

El login arma su coreografía con un solo `AnimationController` y tramos
`Interval` (`widgets/login/login_timeline.dart`): se enciende la red, llega
el dron, el nombre entra letra por letra de borroso a nítido y, en el morph,
el mapa se encoge e inclina, el dron viaja a la esquina como logo y sube la
hoja. Tocar salta al morph. Las curvas propias son `authSettle` (sin
rebote) y `authEmphasized`. Con "reducir movimiento" del sistema
(`MediaQuery.disableAnimationsOf`) se salta la entrada, no vuelan drones y
no hay salida animada.

`/login`, `/register`, `/verify-otp`, `/forgot-password` y `/reset-password`
usan `NoTransitionPage`: cada pantalla anima su propia entrada partiendo de
la forma del encabezado de la anterior (`AuthHeaderMetrics`). Volver al login
desde registro, código o recuperación usa
`extra: LoginScreen.returnExtra`: el encabezado crece y no se repite la
entrada, que sale solo al abrir la app y al cerrar sesión.

Verificar el código abre la sesión (Nest devuelve `AuthSession`), así que tras
el check se abre el espacio aéreo (`AirspaceReveal`) y se va a `/home`. El
reenvío se habilita a los 45 s (espera solo de la app; el código dura 10 min).

El router escucha `authControllerProvider` y, apenas hay sesión, saca al
usuario de las pantallas públicas hacia `/home`. Por eso el login y el código
llaman `login(..., announce: false)` / `verifyOtp(..., announce: false)`:
guardan el token sin avisar, terminan su animación de salida y recién ahí
llaman `announce(session)`. Así la pantalla no se cierra a mitad de la salida.

Recuperar contraseña ya no salta sola a la siguiente pantalla: al enviar
muestra el mensaje de Nest (que no dice si la cuenta existe) y el botón pasa
a "Ingresar el código", que lleva a `/reset-password`.

Nueva contraseña reusa `OtpCodeField` para el código, mide la clave con
`PasswordScore` (solo orienta; lo que se exige es `Validators.password`) y
avisa en vivo si la confirmación no coincide. Al actualizar, desde el botón
se abre el mapa y aparece `ResetSuccessView` (el dron de la marca orbita el
sello); la sesión no se abre y el botón vuelve al login.

`LoginAlert` / `AuthFormAlert` (en `widgets/login/`) son el aviso de error
o de éxito del login y el registro; `AuthFormAlert` ya maneja el caso
`null` sin ocupar espacio. Las piezas del perfil viejo (`AuthPage`,
`LoginGlassCard`, `LoginButton`, `LoginPalette`) se borraron en la Fase 8:
el perfil usa las pantallas de trabajo de abajo.

Colores siempre con `Theme.of(context)` y `withValues(alpha: ...)` para lo
translúcido. Nunca hex dentro de una feature.

Convenciones que ya están en el código:

- Los labels de campo van en mayúsculas con `letterSpacing`. Los assert de los
  tests buscan el texto en mayúsculas.
- El registro y el login no piden rol. El registro es solo del solicitante y
  usa `DocumentTypeTabs` para el tipo de documento. El login pide correo y
  contraseña.
- Login y registro validan en la pantalla con `Validators` y pasan el error a
  cada `AuthField`. El registro nombra sus campos con `RegisterInput` y agrupa
  lo que comparten en `RegisterFormData`, para no pasar parámetros uno por uno.
- En el registro, "Crear cuenta" queda apagado hasta aceptar el
  consentimiento (RNF-05).

## Paleta y tokens visuales

Rediseño "Grafito y turquesa" (rama `style/rediseno-total-temporal`; propuesta en el lienzo <https://claude.ai/artifact/Ay5RAswEtqiuxruk6Lzioi>). Colores medidos de la referencia (póster de dron): turquesa `#50B9C6`–`#5FC3CF`, grafito casi negro y cielo `#BFD2E2`.

La fuente de verdad ejecutable está en `lib/theme/`: [`app_theme.dart`](lib/theme/app_theme.dart) (`ThemeData`), [`app_palette.dart`](lib/theme/app_palette.dart) (`AppPalette`, la extensión con lo que `ColorScheme` no trae; se lee con `context.palette`), [`app_backdrop.dart`](lib/theme/app_backdrop.dart) (el fondo y la transición entre pantallas), [`app_motion.dart`](lib/theme/app_motion.dart) (tiempos y curvas) y [`app_map_style.dart`](lib/theme/app_map_style.dart) (el tinte de los tiles). No crear una segunda paleta ni escribir colores hardcodeados en las pantallas.

### `ColorScheme`

| Token | Oscuro | Claro | Uso |
| --- | --- | --- | --- |
| `primary` / `onPrimary` | `#4FC3C9` / `#071214` | `#0B6470` / `#FFFFFF` | Marca, enlaces, foco, destino activo de la barra |
| `secondary` | `#FBBF6A` | `#9A4A06` | Atención (por cargar, pendientes) |
| `tertiary` | `#4ADE80` | `#116632` | Éxito (en vuelo, entregado) |
| `error` | `#FF8FA3` | `#A82D24` | Errores, rechazo, geovallas |
| `surface` | `#1A2126` | `#FFFFFF` | Hojas inferiores y diálogos (opacos) |
| `onSurface` / `onSurfaceVariant` | `#EEF3F5` / `#A6B4BA` | `#12171A` / `#4D5B63` | Texto principal y secundario |
| `outline` | `#2C363C` | `#C9D6DE` | Líneas |

### `AppPalette` (`context.palette`)

| Token | Oscuro | Claro | Uso |
| --- | --- | --- | --- |
| `backdrop` | `#1F2A30` → `#14191D` → `#0B0E10` | `#F7FAFC` → `#E3EDF4` → `#CFDFEB` | Degradado de fondo de toda la app |
| `accentGlow` / `skyGlow` | turquesa 20 % / cielo 12 % | turquesa 30 % / cielo 32 % | Velos del fondo |
| `accentGradient` / `onAccent` | `#6ED6D9` → `#3FA9C0` / `#071214` | `#137C8A` → `#0B6470` / `#FFFFFF` | Botón central, botón principal, chips activos |
| `glass` / `glassBorder` | blanco 7 % / 10 % | blanco 62 % / 95 % | Tarjetas de vidrio |
| `bar` | `#161C20` al 90 % | blanco 88 % | Barra flotante y paneles sobre el mapa |
| `success` · `warning` · `danger` · `info` | `#4ADE80` · `#FBBF6A` · `#FF8FA3` · `#A9C8E6` | `#116632` · `#9A4A06` · `#A82D24` · `#2F5F8A` | Semáforo (`StatusPill.colorOf`) |
| `droneShell` / `droneMetal` | grafito | grafito | El dron dibujado (`DroneArt`) |

Contraste medido (AA): sobre el fondo medio el texto da 15,8:1 y el suave 8,3:1; sobre vidrio el peor caso (error) da 5,3:1; el texto sobre el degradado del acento, 11,1:1 a 6,9:1. En claro el verde de éxito baja a `#116632` (6,0:1).

- Tipografía única: **Space Grotesk** (`google_fonts`). Cifras con `FontFeature.tabularFigures()` para que los contadores no bailen. Escala: `displayLarge` 64, `displayMedium` 48 (cifras de los inicios), `headlineLarge` 32, `headlineMedium` 24, `titleLarge` 20, cuerpo 15–16; `labelSmall` 11 px w600 con `letterSpacing` 1,6 para las etiquetas en mayúsculas.
- Radios: campos 16; botones, chips y barra en píldora; tarjetas 22–28; hojas 32.
- Superficies de formulario en [`app_surfaces.dart`](lib/theme/app_surfaces.dart): `AppSurfaces.sheet` (grafito que baja a casi negro en oscuro, blanco a cielo en claro) y `AppSurfaces.fields` (campos con borde visible e ícono que se enciende al enfocar). Las usan la hoja del auth y `FormSheetCard`.
- El scaffold es transparente: el degradado lo pinta `AppBackdrop` (en `MaterialApp.builder` y en cada ruta con `AppPageTransitionsBuilder`).
- `themeMode`: `ThemeMode.system`; el modo oscuro es el principal.
- Curvas: nunca `Curves.linear` ni `Curves.ease`. `AppMotion.enterCurve` (`fastOutSlowIn`), `AppMotion.bounceCurve` (`easeOutBack`) y `AppMotion.pageCurve` (`easeInOutCubic`). Se anima con `Transform`, `Opacity`, escalas y recortes. `AppMotion.of(context, d)` devuelve cero con "reducir movimiento"; un rebote que encoge no anima anchos (pasa de 0): se anima la escala.

## Navegación por rol (`lib/app/role_shell.dart`)

Todas las rutas con sesión viven dentro de un `ShellRoute` con `RoleShell`: la pantalla y, encima, `FloatingNavBar` (cuatro destinos y el botón central levantado). Los destinos y la acción de cada rol están en [`role_tabs.dart`](lib/app/role_tabs.dart):

| Rol | Destinos | Botón central |
| --- | --- | --- |
| Solicitante | Inicio · Pedidos (`/orders/mine`) · Planes (`/orders/plans`) · Perfil | Pedir urgencia (`push /orders/emergency`) |
| Despachador | Inicio · Agenda (`/orders/agenda`) · Inventario · Más (`/more`) | Cola de urgencias (`go /orders/queue`, con contador) |
| Operador de flota | Inicio · Flota · Geovallas · Perfil | Vuelos en curso (`go /fleet/flights`, con contador); "Nuevo dron" queda en Flota |
| Administrador | Resumen · Centrales · Cuentas · Perfil | Hoja para crear central o cuenta (`showAdminCreateSheet`) |

- En un destino la barra se ve; en un detalle o formulario se desliza hacia abajo y se encoge, igual que al bajar en una lista (`UserScrollNotification`). Al subir vuelve.
- `RoleShell` suma el alto de la barra a `padding` y `viewPadding` de `MediaQuery`: las listas y los botones flotantes quedan por encima sin cálculos en cada pantalla.
- `NavScope.isTabRootOf(context)` dice si la pantalla es un destino: `SectionHeader` no muestra "volver" ahí.
- "Agenda" abre `GET /orders/agenda` (franjas del día, "despegar antes de"); los programados, el histórico (`/orders/history`) y la cuarentena (`/inventory/quarantine`) están en "Más".
- Los cuatro inicios tienen la campana de avisos (`NoticeBell`) con los sin leer; abre `/notifications`.

## Telemetría y mapa (`features/tracking/`)

- `TelemetryClient` hace el `GET /telemetry/orders/:id` para el primer dibujo
  y abre el socket `/telemetry` (token crudo en `auth.token`). Un socket por
  pantalla: se cierra al salir; no hay socket global.
- Nest contesta `subscribe` con los eventos `subscribed` o `error` (no con
  ack). Con `error` se muestra el mensaje y no se reintenta.
- El 404 `Todavía no hay vuelo para este pedido.` no es un error: la pantalla
  dice "El vuelo está por empezar".
- El mapa base es **uno**: `AppMap` en `lib/core/widgets/app_map.dart`.
  Tiles de OpenStreetMap (con `userAgentPackageName`) teñidos con
  `AppMapStyle` con **un solo** `ColorFiltered` sobre toda la capa (filtrar
  cada tile creaba una capa por tile y cerraba la app en el navegador): grafito con velo turquesa en oscuro, desaturados y fríos
  en claro, sin clave de API (CARTO ya exige clave, por eso no se usa).
  Con `--dart-define=MAPBOX_TOKEN=pk...` (y opcional `MAPBOX_STYLE`) usa
  un estilo de Mapbox; el token no se sube al repositorio. Trae controles
  de vidrio (acercar, alejar, recentrar y, con `follow`, seguir al dron),
  cámara con movimiento suave, sin rotación accidental, `fit` /
  `fitPadding`, `controlsPadding` y `onCameraMove` / `onCameraIdle`.
  El zoom va de `AppMap.minZoom` (9, unos 120 km) a `AppMap.maxZoom` (18,
  nivel de calle): sin límite, alejar o acercar de más rompía el cálculo
  de tiles de `flutter_map` y la app se congelaba.
  Centro por defecto: Valledupar. Cada pantalla le pasa sus capas; no se
  crea otro `FlutterMap`.
- Las pantallas donde el mapa es el centro (el vuelo, elegir un punto,
  dibujar una geovalla) usan `MapSheetScaffold`
  (`core/widgets/map_sheet.dart`): mapa a pantalla completa, volver y
  título en vidrio arriba y una hoja que se arrastra abajo.
- `FlightMap` pinta la ruta en dos tramos (lo recorrido sólido en el
  degradado, lo que falta punteado), `PlacePin` en la central y el
  destino, y `DroneMarker` (halo que late), que la cámara sigue.
  Sobre los tiles va `MapHudOverlay`; la ruta lleva un corredor tenue y
  brillo en lo recorrido; el dron (`DroneMarker`) apunta al rumbo del tramo
  (`routeHeading`). Arriba, `FlightLiveBar` ("En vivo", el dron y, para la
  central de origen, la latencia) y `FlightHud` (altitud y rumbo). En la
  hoja, `FlightCard` (fase, minutos en grande, anillo de batería si llega,
  barra de avance por la ruta y datos) y `FlightTimeline` (autorizado,
  carga, vuelo y entrega con las horas del pedido). Con datos locales
  (`DataSource.local`) `trackingProvider` no le pide nada al servidor: el
  vuelo queda "por empezar".
- GeoJSON viene `[lng, lat]`: se convierte con `latLngFromGeoJson` y
  `geoJsonFromLatLng` (6 decimales), también en `app_map.dart`.
- `flutter_map` revienta con una `Polyline` sin puntos: la línea solo se
  agrega con 2 puntos o más.
- "Ver vuelo" (`WatchFlightButton`) aparece cuando `Order.hasFlight`: carga
  confirmada, en vuelo, esperando la entrega o de regreso con el paquete. El
  despachador solo si su central es el origen.
- **El regreso del dron no se le muestra al solicitante** (regla del
  profesor): sin "Ver vuelo" en pedidos de regreso o entregados, y en el
  mapa, con `leg: return` o el pedido entregado, devuelto o de regreso, no
  se pinta el dron ni la telemetría; solo el aviso (`FlightNotice` con
  `showReturn: false`). El despachador y el operador sí lo ven.
- El operador ve el mapa de sus drones en misión desde "Vuelos en curso"
  (`FleetFlightsScreen`, `GET /fleet/flights?hubId=`, `fleetFlightsProvider`).
  Nest no le deja leer `GET /orders/:id`, así que su mapa sigue al dron sin
  la ruta dibujada (pendiente del backend). Esa pantalla abre un socket con
  `subscribe-hub` (`TelemetryClient.watchHub`, `hubAlertsProvider`) por
  cada central: cada alerta de batería, falla o frío sale en un aviso con
  "Ver vuelo". La lista, el contador de la barra y el inicio del operador
  (`operatorDronesProvider`) suman **todas** sus centrales (una consulta por
  central), no solo la elegida en Flota.
- La telemetría trae `leg`: `outbound` (ida) o `return` (`FlightLeg.back`,
  el regreso a su central: con el paquete si nadie recibió, o vacío tras
  entregar).
  `Telemetry.arrived` es solo la ida en tierra. Tras entregar, el dron
  espera un minuto en destino con `phase: unloading` ("Retiro del
  medicamento"); una fase que la app no conozca cae en `FlightPhase.unknown`
  y el mapa sigue. `FlightNotice` avisa entregado, retiro, de regreso y
  devuelto según el `order-status` del socket.
- En el regreso, si el pedido ya trae `assignment.returnRoute` (Nest la
  calcula cuando el dron empieza a volver; la pantalla relee el pedido en
  ese momento), el mapa pinta **esa** ruta en el color de información; si
  no, la de ida.
- La temperatura (solo vista `full`) se pinta en rojo fuera de 2 a 8 °C
  (`isColdChainBreach`); con `coldChainAlert` o una alerta `cold_chain`
  sale el aviso "Alerta de frío" (`ColdChainBanner`).

## Entrega (`features/delivery/`)

- `GET /orders/:id/delivery-code` da `{ code, expiresAt }` desde que se
  confirma la carga (`Order.deliveryCodeVisible`) y siempre es el mismo.
  `expiresAt` llega `null` mientras el dron vuela; al aterrizar trae la
  hora límite (aterrizaje + 5 min). El código solo vive en memoria.
- `POST /orders/:id/delivery-code/validate` con `{ code }` deja el pedido
  `delivered` y el dron vuelve solo a su central (el pedido sigue
  entregado; la telemetría marca `leg: return`). Al quinto código
  equivocado Nest responde `ReceiveOrderScreen.lockedMessage` y el pedido
  ya no se entrega. Errores de Nest tal cual.
- Recibe el solicitante (persona) o el despachador de la central de
  destino (traslado, `DispatcherPermissions.canReceive`); a cualquier otro
  Nest responde 404.
- En un traslado, después del código se responden "¿La remisión coincide?"
  y "¿El sello llegó intacto?" (`TransferChecklist`, con `YesNoQuestion`);
  sin las dos respuestas "Confirmar entrega" queda apagado y viajan
  `remissionMatches` y `sealIntact`. Si algo no cuadra, Nest responde el
  pedido en `returning` con `receiptRejectedReason` (no es un error): se
  muestra el motivo y el dron vuelve con el paquete.
- `ReceiveOrderScreen` (`/delivery/:orderId`, con `push`) lee el código al
  abrir. En vuelo lo muestra y lo vuelve a leer cada 10 s hasta que llega
  `expiresAt`; en tierra cuenta cada segundo y abre el "teclado del dron"
  simulado (`OtpCodeField`) con "Confirmar entrega". Al vencer o agotar
  intentos esconde el código y apaga el botón; al entregar, las cajas se
  juntan en el check y vuelve a la pantalla anterior.
- `ReceiveOrderButton` dice "Ver código de entrega" en vuelo y "Recibir
  pedido" en tierra. Sale en el detalle, en el mapa del solicitante y, ya
  aterrizado, en Mis pedidos y Traslados entrantes.
- "Ver vuelo" sigue en el detalle de un pedido entregado para ver el
  regreso del dron.
- `GET /orders/incoming` (`incomingProvider`) alimenta "Traslados
  entrantes" del despachador y el contador "por recibir" de su inicio.

## Geovallas sobre el mapa (`features/geofences/`)

- Los vértices se dibujan en `GeofenceDrawScreen` (`MapSheetScaffold`, con
  `Navigator.push` desde el formulario): toque = vértice, tocar un vértice
  lo quita, Deshacer y Borrar todo, "Listo" con 3 o más.
- El formulario solo muestra la vista previa quieta
  (`GeofencePolygonPreview`, con un margen de encuadre chico: el del modo
  dibujar no cabe en 200 px y dejaba el mapa en negro); dentro de su scroll, arrastrar un mapa
  peleaba con el scroll.
- `GeofenceFormValues.vertices` guarda `[lng, lat]` sin el cierre; el
  anillo se cierra al armar el body (`GeoJsonPolygon.fromVertices`).

## Pantallas de trabajo (desde la Fase 6)

Las pantallas de los roles usan las piezas de auth (`AuthField`,
`AuthMorphButton`, `ResetPasswordStrength`) y estas, compartidas:

| Widget | Dónde | Para qué |
| --- | --- | --- |
| `SectionHeader` | `home/presentation/widgets` | Encabezado de trabajo: volver en vidrio (no en un destino de la barra), título grande (26, tracking cerrado), línea de contexto en dos líneas, `trailing` opcional y `bottom` debajo. Detrás, una trama de plano de vuelo con una luz del acento que se apaga hacia abajo (se pinta una vez). |
| `signOut` | `home/presentation/widgets` | Cerrar sesión y volver al login, para todos los inicios. |
| `StatusPill` / `PillTone` | `core/widgets` | Estado en pastilla con punto (positivo, atención, negativo, marca) y rebote al cambiar. `StatusPill.colorOf` da el color de cada tono. |
| `GlassCard` | `core/widgets` | La pieza base: vidrio translúcido con borde fino (en oscuro, con luz arriba que se apaga hacia abajo); con `onTap` se hunde; `blur` solo sobre mapa o imagen; `strong` para paneles. |
| `GlassIconButton` (`.back`) | `core/widgets` | Botón cuadrado de vidrio (volver, controles del mapa); `active` lo pinta con el acento. |
| `FloatingNavBar` / `NavDestination` / `NavCenterAction` / `NavScope` | `core/widgets` | La barra flotante con su botón central, contador con rebote y punto activo; `NavScope` dice si la pantalla es un destino. |
| `BalancedGrid` | `core/widgets` | Cuadrícula sin huecos: filas parejas (5 datos = 3 + 2) y, en dos columnas, la última impar a todo el ancho. La usan `HomeGrid` y la telemetría. |
| `RadarSweep` | `core/widgets` | Radar de adorno (anillos, cruz y barrido que gira); `reach` agranda los anillos y los recorta. No marca datos. Lo usan `HomeSpotlight` y `EmergencyBanner`. Quieto con "reducir movimiento". |
| `MetricTile` / `BarSpark` / `RingGauge` | `core/widgets` | Cifra grande en vidrio, mini gráfico de barras que crece y anillo de progreso. |
| `DroneArt` / `DronePainter` | `core/widgets` | El dron en tres cuartos (grafito con filos turquesa), hélices girando y vaivén; provisional hasta el render. |
| `MapSheetScaffold` | `core/widgets` | Mapa a pantalla completa con barra arriba y hoja que se arrastra (con la superficie de `AppSurfaces.sheet`); `titleBar` reemplaza el título de la barra y `hud` pone un panel a la izquierda. |
| `MapHudOverlay` | `core/widgets` | La capa de pantalla de vuelo sobre los tiles: un velo que los apaga, la grilla fina del acento, una luz arriba y los bordes fundidos con el fondo. Va entre los tiles y las rutas. |
| `SlideToLaunch` | `core/widgets` | Deslizar para confirmar (pedir urgencia): sigue el dedo, resiste en el borde, vuelve con resorte si no llega al 75 % y espera a `onLaunch`; si la pantalla sigue abierta, vuelve al inicio. Para el lector de pantalla es un botón. |
| `DroneMarker` / `HubMarker` / `TargetMarker` / `PlacePin` | `core/widgets` | El dron de la marca apuntando a su rumbo (`heading`) con un halo que late; la central como cuadro con la cruz médica; el destino como un blanco; y el pin genérico (elegir un punto). |
| `StatusCard` + `RowActionButton` | `core/widgets` | Tarjeta de lista con estado y acción a la derecha. |
| `ToneTile` (`ToneTile.icon`) | `core/widgets` | El cuadro teñido con ícono (o el dron) al frente de cada tarjeta. |
| `SectionFormPage` / `SectionStatePage` | `home/presentation/widgets` | Pantalla de formulario (encabezado, tarjeta sobre la curva y botón) y su versión para carga, error o vacío. La usan todos los formularios. |
| `FormBottomSheet` | `core/widgets` | Hoja inferior con título, campos y botón de guardar (editar perfil, mantenimiento). |
| `ChoicePill` | `core/widgets` | Chip elegible (relleno o teñido, con ícono o check). |
| `SlidingSegmented` | `core/widgets` | Filtro con pastilla que se desliza (`null` = "Todas"). |
| `showConfirmSheet` | `core/widgets` | Hoja inferior para confirmar suspender o reactivar. |
| `showAppSnack` / `showErrorSnack` / `GlassSnack` | `core/widgets/app_snack.dart` | El aviso de cualquier acción: pastilla de vidrio (desenfoque, tinte del tono y borde fino) con ícono, texto de Nest, acción opcional y una línea que se acorta mientras se ve. `SnackTone`: `success`, `error`, `info`, `warning`. Los errores de Nest van con `showErrorSnack`. |
| `YesNoQuestion` | `core/widgets` | Pregunta de sí o no con dos chips (recibir un traslado, revisar un retorno). |
| `FormSheetCard` | `core/widgets` | Tarjeta del formulario con la superficie de `AppSurfaces.sheet` y los campos de `AppSurfaces.fields`: la misma hoja del auth. |
| `MessageView` | `core/widgets` | Lista vacía o error de Nest, centrado. |
| `RiseIn` (`RiseIn.stagger`) / `PressScale` / `CountUpText` | `core/widgets` | Entrada en cascada, hundirse al tocar y números que cuentan. Respetan "reducir movimiento". |
| `HomePage` / `HomeHeader` / `HomeSpotlight` / `HomeGrid` / `HomeLabel` / `QuickTile` | `home/presentation/widgets` | Los inicios: lista en cascada; encabezado (marca con el `DroneMark`, campana, iniciales y salir; debajo el rol, el saludo a 34 y el contexto); la cifra principal en una tarjeta con el dron sobre un `RadarSweep` y el número separado por una línea fina; cuadrículas de dos columnas; accesos con contador (atención con `urgent`) o candado con `onTap: null`. |
| `DispatcherMoreScreen` / `showAdminCreateSheet` | `home/presentation` | "Más" del despachador en cuadrícula y la hoja del botón central del administrador. |
| `SectionHeader.backOrHome` | `home/presentation/widgets` | Volver con `pop` si se llegó con `push`; si no, al inicio. Los detalles y el mapa se abren con `push`. |
| `DetailSection` / `DetailLine` | `core/widgets` | Tarjeta con ícono teñido y rótulo, y filas "etiqueta … valor". |
| `AuthDateField` + `pickIsoDate` / `AuthChoiceGroup` | `auth/presentation/widgets` | Fecha en calendario (AAAA-MM-DD) y grupo de chips con label y error que tiembla, con la forma de `AuthField`. |
| `OrderTray` / `OrderRowCard` | `orders/presentation/widgets` | Andamiaje de las bandejas (encabezado con conteo, lista en cascada, recarga, vacío, error y refresco cada 10 s) y su tarjeta, con una franja del color del pedido en el borde izquierdo. |
| `MissionCard` / `MissionRoute` / `LiveMission` | `home/presentation` | La misión en curso del inicio (solicitante con su pedido, despachador con el primer vuelo de su central): luz verde, minutos para llegar de la telemetría en vivo (o el estado si no hay), qué va en el dron, la ruta con el dron en su punto real (flotando en medio sin telemetría) y altitud, velocidad y fase. `LiveMission` abre el socket solo mientras se ve el inicio. |
| `RequesterStats` / `NextDeliveryCard` | `home/presentation/widgets/requester` | Los números del solicitante (entregados con su anillo y los pedidos de las últimas 4 semanas en barras) y la próxima entrega programada (día y hora, plan o programada). Todo sale de sus pedidos. |
| `OrderJourney` | `orders/presentation/widgets/order_detail` | Arriba del detalle: el recorrido del pedido en cinco puntos (pedido, autorizado, carga, vuelo, entrega) con el dron sobre el actual y una equis si terminó mal. |
| `EmergencyBanner` / `MedicationCarousel` / `EmergencyFacts` | `orders/presentation/widgets/requester_order` | Pedir urgencia: el radar con la búsqueda (la central la elige el despachador al autorizar; sale un Wingcopter 198), el medicamento en tarjetas que se deslizan (la primera abre el buscador) y, sobre el deslizador, prioridad y ruta. No promete central ni tiempos antes de autorizar. |
| `AuthPickerField` / `showSearchPicker` / `PickerOption` | `auth/presentation/widgets` | Elegir de una lista que puede ser larga (medicamento, central de origen): un campo con la forma de `AuthField` que abre una hoja con buscador (sin mayúsculas ni tildes) y una lista perezosa. `offerOption` (`orders/presentation/widgets`) arma la opción de un insumo. No usar chips para listas que crecen con los datos. |
| `AuthLocationField` / `pickLocation` | `auth/presentation/widgets` | Vista previa quieta del punto; al tocarla abre el mapa a pantalla completa con el pin fijo al centro (se levanta al arrastrar y cae con rebote) y "Usar esta ubicación" (nueva central, urgencia y entrega periódica). |
| `OrderFormScaffold` | `orders/presentation/widgets` | Formularios de pedido sobre `SectionFormPage`; mientras su lista (catálogo o centrales) carga, falla o viene vacía, lo dice. |
| `pickFutureDate` | `auth/presentation/widgets/auth_date_field.dart` | El calendario de hoy a un año (inicio de planes, fecha estimada de mantenimiento). |
| `RequesterOrderValues` / `RequesterOrderState` | `orders/presentation/widgets/requester_order` | Valores, validación y estado compartidos por la urgencia y la entrega periódica del solicitante. **La ubicación es obligatoria**: Nest no autoriza sin coordenadas. |
| `ScheduleDraft` / `ScheduleFields` / `SchedulePreviewState` / `SchedulePreviewCard` | `orders/presentation/widgets/plan_schedule` | El calendario de un plan (RU-30): semanal, mensual o fechas sueltas, inicio, fin (fecha **o** número de entregas), hora en punto de 07:00 a 17:00 y, con fórmula, su vigencia. La vista previa llama `POST /orders/plans/preview` medio segundo después del último cambio; con error de Nest el botón se apaga. Lo usan el plan del solicitante, el abastecimiento y "Cambiar calendario". |
| `FallbackCard` / `AuthorizeOutcome` | `orders/presentation/widgets/order_detail` | HU-24: autorizar sin dron ya no da 409. `AuthorizeOutcome.of` lee `assignment` o `fallback` (otra central, convencional, reintento) o el rechazo por geovalla; `FallbackCard` muestra el motivo de Nest y las centrales alternativas. |
| `OccurrenceSection` / `OccurrenceRules` / `showRescheduleSheet` | `orders/presentation/widgets/order_detail` | Confirmar, omitir y mover una entrega de plan (sin dron y a 2 horas o más; la verdad es la respuesta de Nest). |
| `ReturnCheckSection` | `orders/presentation/widgets/order_detail` | Revisión del paquete devuelto (`return-check`) en la central de origen; con alerta de frío avisa que irá a cuarentena. |

Los formularios validan en la pantalla con `Validators` y pasan
`errorText` + `shakeCount` a cada `AuthField`, igual que el login
(`HubFormValues.validate`, `UserFormValues.validate`,
`HubRequestValues.validate`, `InventoryFormValues.validate`,
`RequesterOrderValues.validate`, `GeofenceFormValues.validate`). Los errores de
un provider se muestran con `ApiException.messageOf(error)`, nunca con
`'$error'`.

## Origen de datos (local | remote)

El front no depende de que el backend ya exista. Cada feature habla con un **repositorio** (contrato). El origen se elige en **un** sitio (`lib/core/data`):

- `local` — fixtures en memoria del cliente.
- `remote` — HTTP hacia Nest.

La UI no importa DTOs de red ni fixtures. Si el endpoint no está listo, la
feature queda en `local`.

### Patrón de una feature

Todas las features nuevas copian esta estructura. Es el mismo patrón que
`hubs` ya tiene:

```
lib/features/<dominio>/data/
  <dominio>_models.dart        # enums y entidades con fromJson/toJson
  <dominio>_repository.dart    # contrato abstracto
  remote_<dominio>_repository.dart
  local_<dominio>_repository.dart
  <dominio>_providers.dart     # switch local|remote + providers de estado
lib/features/<dominio>/presentation/
  ...
```

Reglas de los datos:

- El switch `appDataSource` que elige local o remote vive **solo** en el
  `<dominio>_providers.dart` de la feature.
- Los repositorios no importan Riverpod ni `TokenStore`, salvo el local (que
  necesita el token para simular la sesión).
- Los fixtures van dentro del repositorio local de cada feature.
- `mine()` es el único método que convierte un 404 en `null`; el resto relanza
  para que la UI muestre el mensaje de Nest.
- `ProviderScope` usa `retryOnlyWithoutResponse` (`lib/app/provider_retry.dart`):
  un error con código HTTP de Nest no se reintenta y se muestra de una vez;
  solo se reintenta (3 veces) cuando el servidor no respondió.
- Cada `<dominio>RepositoryProvider` hace `ref.watch(sessionUserIdProvider)`
  (`auth/presentation/auth_controller.dart`): al cambiar de cuenta se
  reconstruye y todo lo cargado se vuelve a pedir. Un repositorio nuevo
  tiene que hacer lo mismo, o la cuenta siguiente verá datos ajenos.
- Al pintar un `AsyncValue` con `switch`, el caso de datos es
  `AsyncValue(hasValue: true, hasError: false, :final value?)`, no
  `AsyncData(...)`: durante una recarga el estado es `AsyncLoading` con el
  valor anterior y la pantalla no debe quedar en blanco. Para leer un número
  o un título se usa `.value` (el último conocido), no `.asData?.value`.
- Las listas sin socket (cola, programados, pending-load, vuelos en curso, traslados entrantes,
  mis pedidos, el detalle del pedido) y los números del inicio del
  despachador, del operador y del solicitante se
  envuelven en `AutoRefresh` (`lib/core/widgets/auto_refresh.dart`), que
  invalida su provider cada 10 s mientras la pantalla está abierta.

## Contrato con el backend

- REST para CRUD y comandos (crear central, crear dron, dibujar geovalla).
- WebSocket solo para telemetría y, si conviene, cambios de estado en vivo. Reconexión automática (RNF-12).
- No persistir JWT en texto plano si la plataforma ofrece almacenamiento seguro.
- El contrato verificado de cada módulo vive en el código de Nest
  (`backend/src/<módulo>`). Si un endpoint cambia, el frontend se ajusta en el
  mismo PR.

## Ejecución y validación del frontend

Desde `frontend/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

También están disponibles Chrome/Edge si se necesita revisar en web
(`flutter run -d chrome --web-port=8888`). Para Android/iOS se usa el
dispositivo o emulador configurado. El backend remoto espera
`http://localhost:3000`; en el emulador Android, `localhost` apunta al propio
emulador y se debe usar `http://10.0.2.2:3000` cuando se conecte el backend
real.

Para una maqueta sin NestJS:

1. Cambiar temporalmente `appDataSource` en [`lib/core/data/data_source_config.dart`](lib/core/data/data_source_config.dart) de `DataSource.remote` a `DataSource.local`.
2. Ejecutar la app.
3. Usar los fixtures de cada `local_<dominio>_repository.dart`.
4. Volver a `DataSource.remote` antes de probar contra la API real.

No se debe usar una implementación local accidentalmente contra la API real; la selección se hace en un solo lugar.

## Contrato de Auth implementado

La pantalla y las capas de datos no deben inventar endpoints ni cambiar el contrato del backend:

| Operación | Método y ruta | Resultado frontend |
| --- | --- | --- |
| Registro | `POST /auth/register` | `RegisterResponse` |
| Verificación OTP | `POST /auth/verify-otp` | `AuthSession` |
| Reenvío OTP | `POST /auth/resend-otp` | `AuthMessage` |
| Login | `POST /auth/login` | `AuthSession` |
| Logout | `POST /auth/logout` | Sin cuerpo (`204`) |
| Recuperación | `POST /auth/forgot-password` | `AuthMessage` |
| Reset | `POST /auth/reset-password` | `AuthMessage` |
| Usuario actual | `GET /auth/me` | `PublicUser` |
| Actualizar perfil | `PATCH /auth/me` | `PublicUser` |

- Cambiar el correo es en dos pasos (RNF-04): `PATCH /auth/me` con
  `email` y `currentPassword` (la hoja `EmailEditSheet` la pide solo si el
  correo cambió) deja `pendingEmail`; `/profile/email` (`EmailChangeScreen`)
  confirma el código (`POST /auth/me/email/confirm`), reenvía a los 45 s o
  cancela (`DELETE /auth/me/email/pending`). El perfil muestra el correo
  pendiente mientras exista.
- `ApiClient` adjunta el JWT, convierte errores a `ApiException` y maneja el `401`.
- El controller es la única capa que guarda o elimina el token en `TokenStore`.
- Los repositorios no conocen Riverpod, Flutter UI ni `TokenStore` salvo el repositorio local para su sesión simulada.
- La UI muestra el mensaje de `ApiException`; no reemplaza el mensaje del backend por otro texto genérico cuando este viene definido.
- El OTP de registro dura 10 minutos; el de reset, 15 minutos.

### Registro: solo solicitante

`POST /auth/register` es el **único** registro público y crea un `requester`.
Despachador y operador los crea el administrador por `POST /users`
(`CreateInstitutionalUserDto`), sin OTP. Ver
[`../context/app/roles.md`](../context/app/roles.md).

`RegisterRequest` no lleva `role`, y eso no es una omisión: Nest usa
`forbidNonWhitelisted`, así que mandarlo produce 400. Tampoco existe
`UserRole.canSelfRegister` ni `UserRole.requiresEmail`; no los reañadas.

| Campo | Regla |
| --- | --- |
| `fullName` | obligatorio, 40 |
| `documentType` | obligatorio: `citizenship_id`, `foreigner_id` o `ppt` |
| `documentNumber` | obligatorio, 15. Cédulas: 6–10 dígitos. PPT: 6–15 alfanuméricos en mayúsculas |
| `phone` | **obligatorio**, 10 dígitos. No recibe el OTP |
| `email` | **obligatorio**. Ahí llega el OTP de registro y el de recuperación. El login es este correo y la contraseña |
| `password` | 8–72 |
| `consentAccepted` | obligatorio y `true` (RNF-05) |

### `PublicUser` y el documento

`PublicUser` trae `documentType`, `documentNumber` y `hubIds`.

- El documento **solo existe en el solicitante**. Las cuentas institucionales
  nacen con `documentType: null`, así que ambos campos son `DocumentType?` y
  `String?`.
- `hubIds` es `List<String>`, no `hubId`. Lee `[]` si el campo falta o no es
  lista, porque "ninguna central asignada" es un caso normal del solicitante y
  del administrador, no un error.
- Editar el documento es solo del solicitante, y el tipo y el número van
  **juntos**: Nest responde `El tipo y el número de documento se actualizan
  juntos.` si llega uno solo.

### El celular y el prefijo `57`

Nest solo quita lo que no es dígito (`replace(/\D/g, '')`) y después exige
`^\d{10}$`. No quita el prefijo de país. Por eso `+57 300 123 4567` llegaba
como `573001234567` y el registro respondía 400.

La regla vive **en un solo lugar**: `normalizeColombianPhone` en
[`lib/core/colombian_phone.dart`](lib/core/colombian_phone.dart). La usan
`Validators.phone`, `AuthContact.parse` y `LocalAuthRules.normalizePhone`.
No la reescribas en otro archivo. Cuando cambies un campo de contacto, pasa
por ahí.

El login y la recuperación piden correo. `AuthContact.parse` sigue
sirviendo para normalizar un celular en el registro: `+57 300 123 4567`
equivale a `300 123 4567`.

### Widgets de documento

| Archivo | Para qué |
| --- | --- |
| `widgets/document_type_labels.dart` | Copy: nombre completo, corto, hint y `usesDigits` |
| `widgets/document_type_tabs.dart` | Selector segmentado, compartido por registro y perfil |
| `widgets/register/register_document_section.dart` | Selector + campo del número en el registro |
| `widgets/profile/profile_document_editor.dart` | Lo mismo dentro del diálogo de perfil |

Viven fuera de `register/` porque los usan dos features. El enum
`DocumentType` sigue en `data/`, el copy en `presentation/`, igual que
`UserRole` con `ProfileLabels`.

`DocumentTypeLabels.usesDigits` decide el patrón: las dos cédulas son solo
dígitos y el PPT admite letras. Refleja `DOCUMENT_PATTERNS` de
`backend/src/auth/auth.rules.ts`.

## Alcance

No inventar pantallas fuera del MVP (multi-ciudad, clima real, tienda, chat médico). Roles y pantallas salen de [`../context/producto/requisitos.md`](../context/producto/requisitos.md) y [`../context/producto/casos-de-uso.md`](../context/producto/casos-de-uso.md).

