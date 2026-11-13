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

El rediseño natural de la Fase 21 (ver `../context/producto/avance.md`)
dejó el bloque de marca como **un mapa de ciudad común**: tierra, parques,
río y calles, con las centrales unidas por rutas y drones de adorno. Es
plano (sin inclinación 3D) y sin brillos. Es solo decoración: no muestra datos ni contadores (nada de "drones en vuelo" ni
"entregas hoy" inventados). Sirve igual en claro y en oscuro; todos los
colores salen del tema. Piezas (en `widgets/` y `widgets/airspace/`;
`AuthField`, `AuthPickerField`, `AuthMorphButton`, la hoja de búsqueda,
`DroneGlyph` y `CheckMarkPainter` están en `core/widgets` porque las usa toda la app):

| Widget | Para qué |
| --- | --- |
| `AirspaceMap` | El mapa de la ciudad (tierra, parques, río, avenidas y calles; centrales como cuadro del acento con la cruz, rutas sólidas y drones como fichas claras). Lo mueven `network` (dibuja rutas y centrales), `traffic` (suelta los drones) y `dive` (la cámara se acerca en la salida). No se inclina. Con "reducir movimiento" queda quieto y sin drones. El dibujo vive en `AirspacePainter` (colores en `AppMapLook`, `theme/app_map_style.dart`) y los vuelos en `AirspaceTraffic`. |
| `DroneMark` (`core/widgets`) | El dron de la marca como ficha: círculo claro con sombra y el dron de líneas con el núcleo del acento (el mismo del logo). Lo usan el mapa (`DroneMarker`), el recorrido del pedido y los inicios. `halo` dibuja un anillo fino del acento. |
| `AuthCurvedHeader` | El `AirspaceMap` recortado con las esquinas de abajo redondeadas y un velo arriba para leer el logo. Altura y curva se animan desde afuera (entrada → encabezado); el mapa no se deforma, solo cambia el recorte. |
| `AuthHeaderMetrics` | Alturas del encabezado: alto (login, `tallOf`), de paso (`stepOf`) y compacto (registro). El alto y el de paso crecen con la pantalla para que en un teléfono largo la hoja no quede vacía. Con ellas una pantalla arranca con la forma de la anterior. |
| `AuthBrandBar` / `AuthLogoTile` / `AuthPill` | Logo (`DroneGlyph` en un círculo claro con sombra, 42 px) y nombre en la esquina del encabezado; pastilla sólida con ícono opcional. El logo es provisional. |
| `AuthFormSheet` | La hoja del formulario: sube desde abajo pegada a los bordes, con las esquinas de arriba redondeadas, scroll propio y su animación de entrada (desde abajo o de lado). |
| `AuthField` | Label en texto normal (`authLabelStyle`, 14 seminegrita; con nota o `AuthFieldBadge` opcional a la derecha), caja de 54 px, temblor y mensaje deslizante cuando la pantalla pasa `errorText`. El lector de pantalla lee la etiqueta en el campo (el label de arriba va en `ExcludeSemantics`); al fallar, `ShakeOnError` baja el formulario hasta el primer campo con error. Los placeholders de ejemplo empiezan por "Ej.:". Dentro de la hoja los campos toman borde visible e ícono que se enciende al enfocar (tema local de `AuthSheetPanel`); fuera de auth no cambian. |
| `AuthMorphButton` | `ElevatedButton` del acento liso (54 px, radio 16, sin flecha) que se encoge a círculo con el dron girando mientras carga; con `isDone` se pone verde y dibuja el check; `pill: true` lo vuelve píldora; con `onPressed` en `null` queda apagado. |
| `AuthChrome` / `AuthSheetPanel` | Las piezas sólidas sobre el mapa (pastilla, volver) con sombra corta; la hoja del formulario, sólida, radio 28. Los títulos usan `authTitleStyle` (28, negrita). |
| `AirspaceReveal` | La salida al inicio: desde el botón se abre un círculo con el mapa, la cámara se acerca y todo se funde en el fondo de la app. Con `dive: false` solo abre el mapa (lo usa la nueva contraseña). |
| `DroneGlyph` / `SpinningDrone` | El dron de líneas; quieto o girando como indicador de carga. |
| `AuthStepScaffold` | Pantallas de paso (código, recuperación, nueva contraseña): el mapa arriba con `AuthBackButton` y pastilla opcional, el ícono del paso en un círculo claro de 80 px montado sobre el borde de la hoja (baja al entrar; `turnIcon` lo endereza, como la llave) y la hoja con el contenido y la acción al fondo. `fromTall` cuando se llega desde el login y `fromStep` desde otra pantalla de paso. |
| `RegisterProgress` | El avance del registro: tres barras (identidad, contacto, acceso) que se llenan cuando cada grupo queda bien y "2 de 3 listos". Solo pinta; la validación al enviar no cambió. La fuerza de la contraseña usa `ResetPasswordStrength`. |
| `AuthTextLink` | "Pregunta + acción" centrados (¿No tienes cuenta? Regístrate). |
| `OtpCodeField` | Un campo invisible (acepta el autocompletado del código) y seis cajas que lo muestran; al verificar, las cajas se juntan en el check (`OtpSuccessCheck`). |
| `CheckMarkPainter` | Check que se dibuja de punta a punta; lo usan el consentimiento, el botón y el código. |

El login arma su coreografía con un solo `AnimationController` y tramos
`Interval` (`widgets/login/login_timeline.dart`): se dibujan las rutas y
las centrales, llega el logo, el nombre entra letra por letra de borroso a
nítido, sale el eslogan y, en el morph, el mapa se recorta a encabezado,
el logo viaja a la esquina y sube la hoja. Tocar salta al morph. Las curvas propias son `authSettle` (sin
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

- Los labels de campo van en texto normal con `authLabelStyle` (desde la
  Fase 21; antes iban en mayúsculas). Los assert de los tests buscan el
  texto tal cual ("Correo electrónico").
- El registro y el login no piden rol. El registro es solo del solicitante y
  usa `DocumentTypeTabs` para el tipo de documento. El login pide correo y
  contraseña.
- Login y registro validan en la pantalla con `Validators` y pasan el error a
  cada `AuthField`. El registro nombra sus campos con `RegisterInput` y agrupa
  lo que comparten en `RegisterFormData`, para no pasar parámetros uno por uno.
- En el registro, "Crear cuenta" queda apagado hasta aceptar el
  consentimiento (RNF-05).

## Paleta y tokens visuales

Rediseño **natural** (Fase 21, rama `style/rediseno-frontend`; maquetas en el lienzo <https://claude.ai/artifact/VPqqU3ZLb4nhFTppKxJv14>, filas "Versión natural"). Reemplaza a "Grafito y turquesa": fondo cálido liso, superficies sólidas, un solo acento verde azulado, sin degradados, vidrio, velos ni brillos. Que se vea como un producto real; el movimiento solo donde dice algo.

La fuente de verdad ejecutable está en `lib/theme/`: [`app_theme.dart`](lib/theme/app_theme.dart) (`ThemeData`), [`app_palette.dart`](lib/theme/app_palette.dart) (`AppPalette`, la extensión con lo que `ColorScheme` no trae; se lee con `context.palette`), [`app_backdrop.dart`](lib/theme/app_backdrop.dart) (el fondo y la transición entre pantallas), [`app_motion.dart`](lib/theme/app_motion.dart) (tiempos y curvas) y [`app_map_style.dart`](lib/theme/app_map_style.dart) (el tinte de los tiles y `AppMapLook`, los colores del mapa dibujado del auth). No crear una segunda paleta ni escribir colores hardcodeados en las pantallas.

### `ColorScheme`

| Token | Oscuro | Claro | Uso |
| --- | --- | --- | --- |
| `primary` / `onPrimary` | `#5DBFB4` / `#10201F` | `#0F6E6A` / `#FFFFFF` | Marca, enlaces, foco, botón principal |
| `secondary` | `#E8B45A` | `#8F5200` | Atención (por cargar, pendientes) |
| `tertiary` | `#6FCF97` | `#177A45` | Éxito (en vuelo, entregado) |
| `error` | `#F0958E` | `#B3261E` | Errores, rechazo, geovallas |
| `surface` | `#222528` | `#FFFFFF` | Tarjetas, hojas y diálogos (sólidos) |
| `surfaceContainerHighest` | `#2B2F33` | `#F3F1EC` | Superficie hundida; campos en oscuro |
| `onSurface` / `onSurfaceVariant` | `#F1F0EC` / `#A6ABB0` | `#1B1D1F` / `#62676D` | Texto principal y secundario |
| `outline` | `#3D4247` | `#CFCBC3` | Bordes de campos y líneas |

### `AppPalette` (`context.palette`)

| Token | Oscuro | Claro | Uso |
| --- | --- | --- | --- |
| `backdrop` | `#17191B` (liso) | `#F5F4F1` (liso) | Fondo de toda la app; las tres paradas son el mismo color |
| `accentGlow` / `skyGlow` | transparente | transparente | Sin velos (se conservan para no romper a quien los lee) |
| `accentGradient` / `onAccent` | `#5DBFB4` liso / `#10201F` | `#0F6E6A` liso / `#FFFFFF` | Acento sin degradado |
| `glass` / `glassBorder` | `#222528` / `#363A3F` | `#FFFFFF` / `#E6E3DD` | Tarjetas, ya sólidas |
| `bar` | `#222528` | `#FFFFFF` | Barra y paneles sobre el mapa |
| `success` · `warning` · `danger` · `info` | `#6FCF97` · `#E8B45A` · `#F0958E` · `#8FB4D6` | `#177A45` · `#8F5200` · `#B3261E` · `#2F5F8A` | Semáforo (`StatusPill.colorOf`) |
| `droneShell` / `droneMetal` | grafito | grafito | Sin uso desde la Fase 21 (eran del dron en tres cuartos, `DroneArt`, que se borró) |

- Tipografía única: **Figtree** (`google_fonts`). Títulos en negrita (w700). Cifras con `FontFeature.tabularFigures()` para que los contadores no bailen. Escala: `displayLarge` 64, `displayMedium` 48, `headlineLarge` 32 (auth a 28 con `authTitleStyle`), `headlineMedium` 24, `titleLarge` 20, cuerpo 15–16. `labelSmall` (13, seminegrita, gris) es el rótulo de una sección dentro de una tarjeta. **Nada va en mayúsculas**: rótulos, etiquetas y títulos se escriben normal ("Revisión del traslado", no "REVISIÓN DEL TRASLADO"); los labels de campo usan `authLabelStyle` y los títulos de grupo, `HomeLabel`.
- Radios: campos 14; botones 16; tarjetas 20; hojas 28.
- Superficies de formulario en [`app_surfaces.dart`](lib/theme/app_surfaces.dart): `AppSurfaces.sheet` (la superficie sólida con sombra suave) y `AppSurfaces.fields` (blancos con borde gris cálido en claro, gris hundido en oscuro; el ícono se enciende al enfocar). Las usan la hoja del auth y `FormSheetCard`.
- El scaffold es transparente: el fondo lo pinta `AppBackdrop` (en `MaterialApp.builder` y en cada ruta con `AppPageTransitionsBuilder`).
- `themeMode`: `ThemeMode.system`; el modo oscuro es el principal.
- Curvas: nunca `Curves.linear` ni `Curves.ease`. `AppMotion.enterCurve` (`fastOutSlowIn`), `AppMotion.bounceCurve` (`easeOutBack`) y `AppMotion.pageCurve` (`easeInOutCubic`). Se anima con `Transform`, `Opacity`, escalas y recortes. `AppMotion.of(context, d)` devuelve cero con "reducir movimiento"; un rebote que encoge no anima anchos (pasa de 0): se anima la escala.

## Navegación por rol (`lib/app/role_shell.dart`)

Todas las rutas con sesión viven dentro de un `ShellRoute` con `RoleShell`: la pantalla y, abajo, `AppTabBar` (`core/widgets/app_tab_bar.dart`), la barra de pestañas pegada abajo como en cualquier app: cinco pestañas del mismo tamaño, la del centro es la acción del rol (con su texto corto `tabLabel` y, si hay, el contador rojo). Desde la Fase 21 reemplaza a la barra flotante con botón central levantado. Los destinos y la acción de cada rol están en [`role_tabs.dart`](lib/app/role_tabs.dart):

| Rol | Destinos | Pestaña del centro |
| --- | --- | --- |
| Solicitante | Inicio · Pedidos (`/orders/mine`) · Planes (`/orders/plans`) · Perfil | Urgencia: pedir urgencia (`push /orders/emergency`) |
| Despachador | Inicio · Agenda (`/orders/agenda`) · Inventario · Más (`/more`) | Urgencias: la cola (`go /orders/queue`, con contador) |
| Operador de flota | Inicio · Flota · Geovallas · Perfil | Mapa: mapa en vivo (`go /fleet/flights`, con contador de drones en misión); "Nuevo dron" es el "+" del encabezado de Flota |
| Administrador | Resumen · Centrales · Cuentas · Perfil | Crear: hoja para crear central o cuenta (`showAdminCreateSheet`) |

- En un destino la barra se ve; en un detalle o formulario se desliza hacia abajo, igual que al bajar en una lista (`UserScrollNotification`). Al subir vuelve.
- `RoleShell` suma el alto de la barra (`AppTabBar.height`, 64; la barra pinta además el área segura de abajo) a `padding` y `viewPadding` de `MediaQuery`: los botones flotantes quedan por encima solos. Las listas toman ese `padding` con `listPadding(context)` (ya no hay botones flotantes: crear va en el encabezado o en el "+" del centro) (`core/widgets/list_padding.dart`); un `EdgeInsets` fijo deja el final detrás de la barra.
- Toda hoja inferior se abre con `showAppSheet` (`core/widgets/app_sheet.dart`), nunca con `showModalBottomSheet` directo: va al navegador raíz, queda encima de la barra y su velo la bloquea. En el navegador del `ShellRoute` la hoja quedaba debajo de la barra y tapaba su botón. Adentro se cierra con el `context` de la hoja.
- Las filas de las listas cortan títulos y detalles a dos líneas (`maxLines: 2` con "…") y el correo a una: un nombre largo no estira la tarjeta.
- `NavScope.isTabRootOf(context)` dice si la pantalla es un destino: `SectionHeader` no muestra "volver" ahí.
- "Agenda" abre `GET /orders/agenda` (franjas del día, "despegar antes de"); los programados, el histórico (`/orders/history`) y la cuarentena (`/inventory/quarantine`) están en "Más".
- Los cuatro inicios tienen la campana de avisos (`NoticeBell`) con los sin leer; abre `/notifications`.
- Un inicio no repite lo que está en la barra (destinos ni botón central): solo lleva sus cifras y los accesos que la barra no tiene. La cifra principal puede abrir su lista (`HomeSpotlight.onTap`; "Pedidos en curso" → `/orders/mine?filtro=en-curso`).

## Telemetría y mapa (`features/tracking/`)

- `TelemetryClient` hace el `GET /telemetry/orders/:id` para el primer dibujo
  y abre el socket `/telemetry` (token crudo en `auth.token`). Un socket por
  pantalla: se cierra al salir. La única excepción es la hora simulada.
- **Hora simulada (RF-31).** `simClock` (`core/clock/sim_clock.dart`) es la
  hora de la app: toda pantalla usa `simClock.now()`, nunca
  `DateTime.now()` (cuentas regresivas, "hoy", franjas, fechas mínimas).
  `clockSyncProvider` (lo escucha `RoleShell`, así que dura la sesión) abre
  un socket solo para el evento `clock` (`TelemetryClient.watchClock`); al
  cerrar la sesión el reloj vuelve a la hora real. Con datos locales es la
  hora real. `SimClockBadge` (en `HomeHeader` y `SectionHeader`) dice
  "Simulación ×4" o "Simulación en pausa". JWT, OTP y el límite de intentos
  siguen en hora real. Un test que monte `RoleShell` con sesión anula
  `clockSyncProvider` (`overrideWith((ref) {})`).
- **Fechas y teléfonos en pantalla.** Un solo formato, en
  `core/date_format.dart`: `formatDay` (`sáb. 7 nov.`, o `hoy`/`mañana`/
  `ayer`; `relative: false` dentro de frases como "hasta el …"),
  `formatClock` (`9:50 a. m.`, hora de Colombia), `formatDateTime`
  (`sáb. 7 nov. · 9:50 a. m.`), `formatAgo` (`hace 6 min`, para listas) y
  `formatTimeText` (`HH:mm` de un calendario). No armar fechas a mano ni
  mostrar ISO. Los teléfonos pasan por `formatColombianPhone`
  (`core/colombian_phone.dart`) y, si se puede llamar, por `PhoneLink`.
- Nest contesta `subscribe` con los eventos `subscribed` o `error` (no con
  ack). Con `error` se muestra el mensaje y no se reintenta.
- El 404 `Todavía no hay vuelo para este pedido.` no es un error: la pantalla
  dice "El vuelo está por empezar".
- El mapa base es **uno**: `AppMap` en `lib/core/widgets/app_map.dart`.
  Tiles de OpenStreetMap (con `userAgentPackageName`) teñidos con
  `AppMapStyle` con **un solo** `ColorFiltered` sobre toda la capa (filtrar
  cada tile creaba una capa por tile y cerraba la app en el navegador): gris neutro invertido en oscuro, un poco desaturados
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
  destino, y `DroneMarker` (la ficha del dron con un anillo suave que
  late), que la cámara sigue. Sobre los tiles no va ninguna capa (la
  `MapHudOverlay` con velo y grilla se borró en la Fase 21); la ruta lleva
  un corredor tenue; el dron (`DroneMarker`) apunta al rumbo del tramo
  (`routeHeading`). Arriba, `FlightLiveBar` ("En vivo", el dron y, para la
  central de origen, la latencia); el panel `FlightHud` de altitud y rumbo
  se borró en la Fase 21. En la hoja, `FlightCard` ("Llega en 6 min", la
  hora estimada y la fase, la barra de avance por la ruta y los datos en
  filas "etiqueta … valor": altitud, velocidad y, para la central de
  origen, batería, nevera y carga) y `FlightTimeline` (autorizado,
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
- El operador tiene el **mapa en vivo** (`FleetMapScreen`, en
  `/fleet/flights`, el botón del centro): `GET /fleet/map` (sus centrales
  con el conteo de la flota, las geovallas y los vuelos con su ruta) y un
  socket por central (`TelemetryClient.watchFleet`, `subscribe-hub`) que
  mueve cada dron (`hub-telemetry`), vuelve a pedir el mapa con
  `hub-flight-status`, `hub-flight-ended` o un vuelo nuevo, marca dónde bajó
  un dron (`hub-incident`) y avisa las alertas con "Ver vuelo". Todo vive en
  `fleetMapProvider` (`fleet_map_providers.dart`); con datos locales no
  abre socket. Tocar un dron abre su ficha (`showDroneFacts`, sin nada del
  pedido); tocar una tarjeta de la hoja, su vuelo (`/tracking/:orderId`).
  El contador del botón y el inicio del operador (`fleetFlightsProvider`,
  `operatorDronesProvider`) suman **todas** sus centrales.
- Con `linkLost` (RF-34) la posición es estimada: `FlightLiveBar` dice "Sin enlace · posición estimada" en ámbar y el dron se dibuja tenue.
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
| `SectionHeader` | `home/presentation/widgets` | Encabezado de trabajo sobre el fondo liso: volver redondo (no en un destino de la barra), título grande (26), línea de contexto en dos líneas, `trailing` opcional y `bottom` debajo. Desde la Fase 21 ya no lleva la trama de plano de vuelo. |
| `signOut` | `home/presentation/widgets` | Pide confirmar (`showConfirmSheet`) y cierra la sesión. Solo lo llama el perfil: los inicios ya no tienen botón de salir. |
| `HeaderAddButton` | `home/presentation/widgets` | El "+" de 48 px en el `trailing` del `SectionHeader` para crear (inventario, flota, geovallas). No hay botones flotantes; el administrador crea con el "+" del centro de la barra. |
| `RowMenuButton` / `RowMenuAction` | `core/widgets` | El menú `⋮` de 48 px de una fila para lo que no se debe tocar sin querer (eliminar un insumo o una geovalla, suspender o reactivar una central); cada opción abre su confirmación. |
| `StatusPill` / `PillTone` | `core/widgets` | Estado en pastilla con punto (positivo, atención, negativo, marca) y rebote al cambiar. `StatusPill.colorOf` da el color de cada tono. |
| `GlassCard` | `core/widgets` | La tarjeta base (el nombre es del diseño anterior): la superficie sólida del tema, radio 20, sombra suave en claro y filo fino en oscuro; con `onTap` se hunde; `blur` solo sobre mapa; `strong` para paneles sobre el mapa. |
| `GlassIconButton` (`.back`) | `core/widgets` | Botón redondo de 44 px en la superficie con sombra corta (volver, controles del mapa); `active` lo pinta con el acento. |
| `AppTabBar` / `NavDestination` / `NavCenterAction` / `NavScope` | `core/widgets` | La barra de pestañas pegada abajo: cinco pestañas iguales, la del centro es la acción del rol (`tabLabel` corto, `label` para el lector) con contador rojo; bajo 360 px (`compactWidth`) solo rotula la pestaña abierta. `NavScope` dice si la pantalla es un destino. |
| `AppMaxWidth` | `core/widgets` | En tableta y web, pantalla y barra en una columna de 600 px centrada (lo pone `RoleShell`); el `MediaQuery` de adentro dice ese ancho. |
| `BalancedGrid` | `core/widgets` | Cuadrícula sin huecos: filas parejas (5 datos = 3 + 2) y, en dos columnas, la última impar a todo el ancho. La usan `HomeGrid` y la telemetría. |
| `MetricTile` / `BarSpark` / `RingGauge` | `core/widgets` | Cifra grande en una tarjeta con su etiqueta debajo (escrita normal) y contexto en gris; mini gráfico de barras que crece y anillo de progreso. |
| `MapSheetScaffold` | `core/widgets` | Mapa a pantalla completa con volver y una barra sólida arriba, y una hoja que se arrastra (con la superficie de `AppSurfaces.sheet`); `titleBar` reemplaza el título de la barra ("En vivo" en el vuelo). |
| `MenuList` / `MenuItem` | `core/widgets` | Una lista de opciones en una sola tarjeta, separadas por líneas finas, como los ajustes de un teléfono: ícono teñido, título, detalle opcional, contador (ámbar con `urgent`) y flecha, o candado con `onTap: null`. La usan "Más" y los accesos de los inicios (despachador, solicitante y administrador). |
| `SlideToLaunch` | `core/widgets` | Deslizar para confirmar (pedir urgencia y despegar al confirmar la carga): pista gris, perilla del acento con el avión; sigue el dedo, resiste en el borde, vuelve con resorte si no llega al 75 % y espera a `onLaunch`; si la pantalla sigue abierta, vuelve al inicio. Para el lector de pantalla es un botón. |
| `showLoadCheckSheet` | `orders/presentation/widgets/pending_load` | Revisión antes de confirmar la carga (medicamento, nevera, fórmula, dron y destino) y "Desliza para despegar". La usan la bandeja "Pendiente de carga" y el detalle: un toque nunca lanza el vuelo. |
| `DroneMarker` / `HubMarker` / `TargetMarker` / `PlacePin` | `core/widgets` | La ficha del dron (`DroneMark`) apuntando a su rumbo (`heading`) con un anillo suave que late; la central como cuadro del acento con la cruz médica; el destino como un blanco; y el pin genérico (elegir un punto). |
| `StatusCard` + `RowActionButton` | `core/widgets` | Tarjeta de lista: ícono, texto con la pastilla de estado debajo y la acción a la derecha (un botón o el `RowMenuButton`); `footer` opcional a todo el ancho debajo (la salud del dron). |
| `DroneHealth` / `DroneMaintenanceScreen` | `fleet/presentation` | La salud del dron en su fila (batería, último vuelo, "42 / 50 vuelos", "Le toca revisión", "Mantenimiento vencido") y su historial de taller (`/fleet/:id/maintenance`). "Gestionar" ofrece disponible, mantenimiento (`POST`, con fecha), fuera de servicio (`PATCH`, sin fecha) e historial. |
| `OperatorDashboard` (`FleetUsageCard`, `FleetHealthCard`, `FleetIncidentsCard`, `DashboardPeriod`) | `home/presentation/widgets/operator` | El tablero del inicio del operador (`GET /fleet/dashboard`, `fleetDashboardProvider`): uso (barra apilada, vuelos y km), salud (batería al volver, revisión y vencidos; lleva a la flota) e incidentes por tipo, día y dron, con 7, 30 o 90 días en `SlidingSegmented` (`DashboardPeriod`). |
| `FleetSummary` | `fleet/presentation/widgets` | Arriba de la lista de la flota: disponibles, en vuelo y en taller en una tarjeta partida en tres; sale de la misma lista de drones. |
| `ToneTile` (`ToneTile.icon`) | `core/widgets` | El cuadro teñido con ícono (o el dron) al frente de cada tarjeta. |
| `SectionFormPage` / `SectionStatePage` | `home/presentation/widgets` | Pantalla de formulario (encabezado, tarjeta sobre la curva y botón) y su versión para carga, error o vacío. La usan todos los formularios. |
| `showAppSheet` | `core/widgets` | La única forma de abrir una hoja inferior (navegador raíz, encima de la barra). |
| `FormBottomSheet` | `core/widgets` | Hoja inferior con título, campos y botón de guardar (editar perfil, mantenimiento); deja el área segura y tiene scroll. |
| `ChoicePill` | `core/widgets` | Chip elegible (relleno o teñido, con ícono o check). |
| `SlidingSegmented` | `core/widgets` | Filtro con pastilla que se desliza (`null` = "Todas"); si las opciones no caben, el filtro entero se desliza de lado (`segmentWidthOf`) en vez de cortar el texto. |
| `showConfirmSheet` | `core/widgets` | Hoja inferior para confirmar suspender, reactivar, eliminar o cerrar sesión. |
| `showAppSnack` / `showErrorSnack` / `GlassSnack` | `core/widgets/app_snack.dart` | El aviso de cualquier acción: tarjeta sólida con el ícono del tono, texto de Nest, acción opcional y una línea del tono que se acorta mientras se ve. `SnackTone`: `success`, `error`, `info`, `warning`. Los errores de Nest van con `showErrorSnack`. |
| `YesNoQuestion` | `core/widgets` | Pregunta de sí o no con dos chips (recibir un traslado, revisar un retorno). |
| `FormSheetCard` | `core/widgets` | Tarjeta del formulario con la superficie de `AppSurfaces.sheet` y los campos de `AppSurfaces.fields`: la misma hoja del auth. |
| `MessageView` | `core/widgets` | Lista vacía o error de Nest, centrado. |
| `RiseIn` (`RiseIn.stagger`) / `PressScale` / `CountUpText` | `core/widgets` | Entrada en cascada, hundirse al tocar y números que cuentan. Respetan "reducir movimiento". |
| `HomePage` / `HomeHeader` / `HomeSpotlight` / `HomeGrid` / `HomeLabel` | `home/presentation/widgets` | Los inicios: lista en cascada; encabezado (en gris el rol y el contexto, debajo "Hola, Nombre" a 28; a la derecha la campana y las iniciales, que abren el perfil; el aviso de la simulación debajo); la cifra principal en una tarjeta con su estado en pastilla, el número grande y la etiqueta al lado; títulos de grupo (`HomeLabel`, 18 negrita); cuadrículas de dos columnas. Los accesos van en `MenuList` (`QuickTile` se borró en la Fase 21). |
| `DispatcherMoreScreen` / `showAdminCreateSheet` | `home/presentation` | "Más" del despachador en tres listas (`MenuList`: Pedidos · Pedir a otra central · Mi central) y la hoja de la pestaña central del administrador. |
| `SectionHeader.backOrHome` | `home/presentation/widgets` | Volver con `pop` si se llegó con `push`; si no, al inicio. Los detalles y el mapa se abren con `push`. |
| `DetailSection` / `DetailLine` | `core/widgets` | Tarjeta con ícono teñido y título (escrito normal), y filas "etiqueta … valor" (`child` reemplaza el texto del valor, p. ej. un `PhoneLink`). |
| `PhoneLink` / `callPhone` | `core/widgets/phone_link.dart` | Teléfono con formato colombiano que se toca para llamar (`tel:+57…`, `url_launcher`), 48 px de alto; si el dispositivo no llama, avisa el número. |
| `OrderStatusChip` (`forRequester`) | `orders/presentation/widgets` | El estado del pedido; con `forRequester` en palabras del solicitante ("Preparando el envío", "En camino", "No se entregó"). El despachador y el operador ven el técnico. |
| `AuthDateField` + `pickIsoDate` / `AuthChoiceGroup` | `auth/presentation/widgets` | Fecha en calendario (guarda AAAA-MM-DD, muestra `sáb. 7 nov.`) y grupo de chips con label y error que tiembla, con la forma de `AuthField`. |
| `OrderTray` / `OrderRowCard` | `orders/presentation/widgets` | Andamiaje de las bandejas (encabezado con conteo, lista en cascada, recarga, vacío, error y refresco cada 10 s) y su tarjeta: ícono teñido del color del pedido, título, línea de color, línea gris y pastilla. |
| `MissionCard` / `MissionRoute` / `LiveMission` | `home/presentation` | La misión en curso del inicio (solicitante con su pedido, despachador con el primer vuelo de su central): el estado con su punto verde, el medicamento y lo que va, "6 min" con "llega 9:52 a. m." (hora simulada) si hay telemetría, la ruta como barra con la ficha del dron en su punto real (en medio, subiendo y bajando, sin telemetría) y "Ver mapa". `LiveMission` abre el socket solo mientras se ve el inicio. |
| `RequesterStats` / `NextDeliveryCard` | `home/presentation/widgets/requester` | Los números del solicitante (entregados con su anillo, o una frase si son 0, y los pedidos de las últimas 4 semanas en barras) y la próxima entrega programada (día y hora, plan o programada). Todo sale de sus pedidos. |
| `NextUpCard` / `dispatcherNextUp` | `home/presentation/widgets/dispatcher` | "Para atender ahora" del despachador: la urgencia más vieja de la cola, el pedido que espera la carga y el próximo programado; cada una abre su pedido. |
| `OrderJourney` | `orders/presentation/widgets/order_detail` | Arriba del detalle: el recorrido del pedido en cinco puntos (pedido, autorizado, carga, vuelo, entrega) con la ficha del dron sobre el actual y una equis si terminó mal. |
| `EmergencyFacts` | `orders/presentation/widgets/requester_order` | Pedir urgencia: la nota gris sobre el deslizador (va primero en la cola, el despachador elige la central, sale un Wingcopter 198 por una ruta que evita las geovallas). No promete central ni tiempos antes de autorizar. El medicamento se elige con `CatalogChoices` (buscador); el radar y el carrusel se borraron en la Fase 21. |
| `AuthPickerField` / `showSearchPicker` / `PickerOption` | `auth/presentation/widgets` | Elegir de una lista que puede ser larga (medicamento, central de origen): un campo con la forma de `AuthField` que abre una hoja con buscador (sin mayúsculas ni tildes) y una lista perezosa. `offerOption` (`orders/presentation/widgets`) arma la opción de un insumo. No usar chips para listas que crecen con los datos. |
| `AuthLocationField` / `pickLocation` | `auth/presentation/widgets` | Vista previa quieta del punto; al tocarla abre el mapa a pantalla completa con el pin fijo al centro (se levanta al arrastrar y cae con rebote) y "Usar esta ubicación" (nueva central, urgencia y entrega periódica). Con `gps: LocationGps(...)` suma "Usar mi ubicación" y la precisión del GPS (`location_gps_row.dart`, RU-02); el GPS lo lee `DeviceLocation` (`core/location`, `deviceLocationProvider`). |
| `OrderFormScaffold` | `orders/presentation/widgets` | Formularios de pedido sobre `SectionFormPage`; mientras su lista (catálogo o centrales) carga, falla o viene vacía, lo dice. Por pasos, `steps` (el avance) y `onBack` (volver al paso anterior). |
| `FormSteps` | `orders/presentation/widgets` | El avance de un formulario por pasos: una barra por paso y "Paso 2 de 3 · Cuándo". La entrega periódica va en Qué · Cuándo · Dónde; "Siguiente" valida solo el paso abierto y el atrás del teléfono vuelve al anterior. |
| `HubEmergencyFields` / `offerSourcesProvider` | `orders/presentation/widgets/hub_request` y `orders/data` | Urgencia a otra central con el medicamento primero: el catálogo general y después solo las centrales que lo tienen con stock (se cruzan los catálogos de las centrales de origen). El abastecimiento sigue con la central primero (`HubRequestFields`). |
| `TransferMap` / `transferMapOf` | `orders/presentation/widgets/hub_request` | En la urgencia y el abastecimiento a otra central, el traslado en un mapa quieto: la central de origen, la tuya, una línea punteada y la distancia en línea recta. Sale al elegir el origen si `GET /orders/origin-hubs` trae coordenadas. |
| `pickFutureDate` | `auth/presentation/widgets/auth_date_field.dart` | El calendario de hoy a un año (inicio de planes, fecha estimada de mantenimiento). |
| `PrescriptionPicker` / `PrescriptionAttachment` | `orders/presentation/widgets/requester_order`, `orders/data` | La fórmula (RU-25): "Tomar foto" (`image_picker`, 2400 px, calidad 85) y "Subir archivo" (PDF, JPG o PNG). Un PDF solo o hasta 3 fotos de 5 MB; un PDF reemplaza las fotos y una foto el PDF (`addPrescriptionFiles`). Va en `prescriptions` del body. |
| `RequesterOrderValues` / `RequesterOrderState` | `orders/presentation/widgets/requester_order` | Valores, validación y estado compartidos por la urgencia y la entrega periódica del solicitante. **La ubicación es obligatoria**: Nest no autoriza sin coordenadas. El punto es el destino y la dirección pasó a "Referencia para encontrarte", opcional (RU-02). |
| `ScheduleDraft` / `ScheduleFields` / `SchedulePreviewState` / `SchedulePreviewCard` | `orders/presentation/widgets/plan_schedule` | El calendario de un plan (RU-30): semanal, mensual o fechas sueltas, inicio, fin (fecha **o** número de entregas), hora en punto de 07:00 a 17:00 y, con fórmula, su vigencia. La vista previa llama `POST /orders/plans/preview` medio segundo después del último cambio; con error de Nest el botón se apaga. Lo usan el plan del solicitante, el abastecimiento y "Cambiar calendario". |
| `FallbackCard` / `AuthorizeOutcome` | `orders/presentation/widgets/order_detail` | HU-24: autorizar sin dron ya no da 409. `AuthorizeOutcome.of` lee `assignment` o `fallback` (otra central, convencional, reintento) o el rechazo por geovalla; `FallbackCard` muestra el motivo de Nest y las centrales alternativas. |
| `StatusReasonBanner` | `orders/presentation/widgets/order_detail` | El `statusReason` de un pedido que sigue su curso (`Order.inProgress`): incidente en vuelo o central sin energía. Un pedido cerrado dice su motivo en el resumen; con fallback lo dice `FallbackCard`. |
| `DecisionSection` (`HubTraceTile`, `OfferLadder`, `decisionSummary`) | `orders/presentation/widgets/order_detail/decision` | "¿Por qué este dron?" (`GET /orders/:id/decision`, solo despachador): la decisión en una línea y, al abrir, cada central con el veredicto de sus drones y la escalera de ofertas de la urgencia civil. Sin traza lo dice; con 404 no sale. |
| `WarningBanner` / `HubOutageBanner` / `hubOutageNote` | `core/widgets` y `hubs/presentation/widgets` | Franja ámbar (no es error). El apagón de la central (RF-36): `Hub.poweredAt` con la hora simulada; la franja en el inicio del despachador y en "Mi central", y Autorizar y Confirmar carga apagados con el motivo. |
| `DeclineButton` / `showDeclineSheet` / `canDecline` | `orders/presentation/widgets/order_detail` | "No puedo atenderla" (RU-10, `POST /orders/:id/decline`): solo la urgencia civil en recibido sin central; motivo rápido u "Otro" (opcional). Pasa la urgencia a la siguiente central, no la cierra (eso es "Rechazar"). |
| `queueWaitMinutes` / `queueWaitLabel` / `queueWaitTone` | `orders/presentation/widgets/queue_wait.dart` | "Espera 6 min" en la cola con la hora simulada: ámbar a los 3 min, rojo a los 5 o con `unattended`. |
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
- Un enum de **estado** (`DroneStatus`, `OrderStatus`, `PlanStatus`,
  `HubStatus`, `UserStatus`, `FlightPhase`) cae en `unknown` con un valor
  que la app no conoce: un estado nuevo de Nest no tumba la lista. Un enum
  de **tipo** (rol, misión, destino, venta…) sí lanza `FormatException`:
  sin conocerlo no se sabe qué regla aplicar. `DroneStatus.grounded` lo
  pone el sistema (RF-34): no está en `operatorStatuses` y el dron no se
  gestiona (`isOperable` es falso).
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

