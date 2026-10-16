# AGENTS.md — frontend (Flutter)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/diseno/principios.md`](../context/diseno/principios.md).

## Qué es este lado

Una **sola** aplicación Flutter. Tras autenticarse, el usuario ve el flujo de **su rol**. No hay app web ni un segundo proyecto Flutter.

## Contexto de negocio que el frontend no debe perder

AirDrop simula logística aérea médica para Valledupar y zonas cercanas. El frontend representa cuatro roles: **solicitante** (persona civil, único registro público), **despachador** (una central, lo crea el admin), **operador de flota** (una o varias centrales, lo crea el admin) y **administrador**. La central no es un rol. No existe un rol receptor: la entrega se confirma con un código de un uso. La definición vigente está en [`../context/app/roles.md`](../context/app/roles.md). El contrato de `/auth` de abajo describe el código actual y se actualiza cuando el registro quede solo para el solicitante.

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
    tracking/    # mapa + telemetría (solicitante, operador)
    delivery/    # código de entrega (sin rol receptor)
    analytics/
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
    auth_page.dart          # andamiaje: fondo, SafeArea, ancho máximo
    auth_ambience.dart      # brillo y animación de entrada
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
- Reutilizar widgets. Ningún widget supera **60 líneas**; si pasa, se descompone.
- Tema solo en `lib/theme/`. Las pantallas leen `Theme.of(context)`.
- El mapa y el socket de telemetría se implementan **una vez** en `core` o `features/tracking` y se reutilizan.

### Sistema de diseño de Auth

Las pantallas de auth tienen identidad propia y **comparten andamiaje**. Antes de
armar una pantalla nueva, reusar lo que ya existe.

El rediseño de la Fase 1 (ver `../context/producto/avance.md`) va pantalla por
pantalla. Estas piezas son las nuevas y las usan el login y el registro; las
demás pantallas las adoptan cuando les toque su rediseño:

| Widget | Para qué |
| --- | --- |
| `AuthCurvedHeader` | Bloque verde con borde inferior curvo. Altura y curva se animan desde afuera (splash → encabezado). |
| `AuthHeaderMetrics` | Alturas del encabezado: alto (login) y compacto (el resto). Con ellas una pantalla arranca con la forma de la anterior. |
| `AuthBrandBar` / `AuthLogoTile` / `AuthPill` | Logo, nombre y pastilla de vidrio en la esquina del encabezado. El logo es provisional. |
| `AuthFormSheet` | Tarjeta de vidrio del formulario sobre la curva, con scroll y su animación de entrada (desde abajo o de lado). |
| `AuthField` | Label en mayúsculas (con nota o `AuthFieldBadge` opcional a la derecha), caja de 56 px, temblor y mensaje deslizante cuando la pantalla pasa `errorText`. |
| `AuthMorphButton` | `ElevatedButton` que se encoge a círculo con el dron girando mientras carga; con `onPressed` en `null` queda apagado. |
| `AuthGlass` / `AuthGlassPanel` | Vidrio esmerilado (blur + tinte + borde fino). Con medida: tarjeta del formulario y piezas sobre el encabezado. |
| `CircleReveal` | Círculo de marca que crece desde un punto hasta cubrir la pantalla. |
| `DroneGlyph` / `SpinningDrone` | El dron dibujado; quieto o girando como indicador de carga. |
| `AuthStepScaffold` | Pantallas de paso (código, recuperación): encabezado con `AuthBackButton` y pastilla opcional, ícono montado sobre la curva que entra con rebote (`turnIcon` lo hace girar, como la llave), contenido y la acción al fondo. `fromTall` cuando se llega desde el login. |
| `AuthTextLink` | "Pregunta + acción" centrados (¿No tienes cuenta? Regístrate). |
| `OtpCodeField` | Un campo invisible (acepta el autocompletado del código) y seis cajas que lo muestran; al verificar, las cajas se juntan en el check (`OtpSuccessCheck`). |
| `CheckMarkPainter` | Check que se dibuja de punta a punta; lo usan el consentimiento y el código. |

El login arma su coreografía con un solo `AnimationController` y tramos
`Interval` (`widgets/login/login_timeline.dart`). Con "reducir movimiento" del
sistema (`MediaQuery.disableAnimationsOf`) se salta el splash, el bucle y el
círculo de salida.

`/login`, `/register`, `/verify-otp`, `/forgot-password` y `/reset-password`
usan `NoTransitionPage`: cada pantalla anima su propia entrada partiendo de
la forma del encabezado de la anterior (`AuthHeaderMetrics`). Volver al login
desde registro, código o recuperación usa
`extra: LoginScreen.returnExtra`: el encabezado crece y no se repite el
splash, que sale solo al abrir la app y al cerrar sesión.

Verificar el código abre la sesión (Nest devuelve `AuthSession`), así que tras
el check el círculo de marca cubre la pantalla y se va a `/home`. El reenvío
se habilita a los 45 s (espera solo de la app; el código dura 10 min).

El router escucha `authControllerProvider` y, apenas hay sesión, saca al
usuario de las pantallas públicas hacia `/home`. Por eso el login y el código
llaman `login(..., announce: false)` / `verifyOtp(..., announce: false)`:
guardan el token sin avisar, terminan su animación de salida y recién ahí
llaman `announce(session)`. Así la pantalla no se cierra a mitad del círculo.

Recuperar contraseña ya no salta sola a la siguiente pantalla: al enviar
muestra el mensaje de Nest (que no dice si la cuenta existe) y el botón pasa
a "Ingresar el código", que lleva a `/reset-password`.

Nueva contraseña reusa `OtpCodeField` para el código, mide la clave con
`PasswordScore` (solo orienta; lo que se exige es `Validators.password`) y
avisa en vivo si la confirmación no coincide. Al actualizar, el círculo de
marca cubre la pantalla y aparece `ResetSuccessView`; la sesión no se abre y
el botón vuelve al login.

Piezas anteriores, que hoy solo usa el perfil (y `LoginFormAlert`, también
login y registro). Se reemplazan cuando el perfil tenga diseño propio:

| Widget | Para qué |
| --- | --- |
| `AuthPage` | Fondo con brillo, `SafeArea`, scroll y ancho máximo. Raíz del perfil. |
| `AuthGlow` / `AuthEntrance` / `AuthPulsingDot` | El brillo, la entrada y el punto que late del perfil. |
| `LoginGlassCard` | La superficie translúcida del perfil. |
| `LoginAlert` / `LoginFormAlert` | Mensaje de error o de éxito con animación. `LoginFormAlert` ya maneja el caso `null` sin ocupar espacio. |
| `LoginButton` | Botón con estado de carga del perfil. Es `ElevatedButton`, no `FilledButton`. |

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

La fuente de verdad ejecutable es [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart). No crear una segunda paleta ni escribir colores hardcodeados en las pantallas.

### Tokens de marca

| Token | Valor | Uso |
| --- | --- | --- |
| `primary` | `#0B7A75` (claro) · `#68ADA9` (oscuro) | Marca, botones, enlaces, foco y el encabezado curvo |
| `secondary` | `#E8743B` | Naranja de señal: el dron y lo que está en vuelo |
| `tertiary` | `#10B981` | Éxito y estados positivos |
| `error` | `#C2362B` (claro) · `#FF8C7F` (oscuro) | Errores y acciones destructivas |

### Tema oscuro

| Token | Valor | Uso |
| --- | --- | --- |
| Background | `#0B1110` | Fondo general |
| Surface | `#141B1A` | Tarjetas, campos y superficies |
| Hundido (`surfaceContainerHighest`) | `#0F1615` | Segmentados y rellenos |
| Línea (`outline`) | `#25302E` | Bordes de campos |
| Texto principal | `#EEF3F1` | Títulos y contenido principal |
| Texto secundario (`onSurfaceVariant`) | `#95A4A0` | Ayudas, labels y textos secundarios |
| Texto sobre marca (`onPrimary`) | `#05201C` | Texto e íconos sobre el verde |

### Tema claro

| Token | Valor | Uso |
| --- | --- | --- |
| Background | `#F5F6F3` | Fondo general |
| Surface | `#FFFFFF` | Tarjetas, campos y superficies |
| Hundido (`surfaceContainerHighest`) | `#ECEEEA` | Segmentados y rellenos |
| Línea (`outline`) | `#E2E6E1` | Bordes de campos |
| Texto principal | `#101716` | Títulos y contenido principal |
| Texto secundario (`onSurfaceVariant`) | `#5D6A67` | Ayudas, labels y textos secundarios |
| Texto sobre marca (`onPrimary`) | `#FFFFFF` | Texto e íconos sobre el verde |

- Radius principal: `18` (campos y botones); tarjetas `24`–`28`.
- `themeMode`: `ThemeMode.system`.
- Tipografía única: **Plus Jakarta Sans**. Titulares w800 con letter-spacing negativo; cuerpo w500; labels de campo `labelSmall` (11 px, w700, en mayúsculas).
- `google_fonts`: `^8.2.1`.
- Las superficies translúcidas se construyen con `color.withValues(alpha: ...)`, no con colores nuevos.
- Las pantallas leen `Theme.of(context)` y los widgets reutilizados; no se definen RGB/hex dentro de features.
- Referencia visual de auth: canvas "AirDrop · Auth transiciones" en Claude Design (<https://claude.ai/artifact/93zRSvo1BoLixvXs9dzjqC>). La app conserva tema claro y oscuro porque el tema sigue el sistema.
- Curvas de animación: nunca `Curves.linear` ni `Curves.ease`. Se usan `fastOutSlowIn`, `easeOutBack` (rebotes) y `easeInOutCubic`; se anima con `Transform`, `Opacity` y recortes, no con márgenes.

## Telemetría y mapa (`features/tracking/`)

- `TelemetryClient` hace el `GET /telemetry/orders/:id` para el primer dibujo
  y abre el socket `/telemetry` (token crudo en `auth.token`). Un socket por
  pantalla: se cierra al salir; no hay socket global.
- Nest contesta `subscribe` con los eventos `subscribed` o `error` (no con
  ack). Con `error` se muestra el mensaje y no se reintenta.
- El 404 `Todavía no hay vuelo para este pedido.` no es un error: la pantalla
  dice "El vuelo está por empezar".
- El mapa base es **uno**: `AppMap` en `lib/core/widgets/app_map.dart`
  (tiles de OpenStreetMap con `userAgentPackageName`, crédito y centro en
  Valledupar). Cada pantalla le pasa sus capas; no se crea otro `FlutterMap`.
- GeoJSON viene `[lng, lat]`: se convierte con `latLngFromGeoJson` y
  `geoJsonFromLatLng` (6 decimales), también en `app_map.dart`.
- `flutter_map` revienta con una `Polyline` sin puntos: la línea solo se
  agrega con 2 puntos o más.
- "Ver vuelo" (`WatchFlightButton`) aparece cuando `Order.hasFlight`: carga
  confirmada, en vuelo o esperando la entrega. El despachador solo si su
  central es el origen. El operador no tiene entrada al mapa.

## Geovallas sobre el mapa (`features/geofences/`)

- Los vértices se dibujan en `GeofenceDrawScreen` (pantalla completa, con
  `Navigator.push` desde el formulario): toque = vértice, tocar un vértice
  lo quita, Deshacer y Borrar todo, "Listo" con 3 o más.
- El formulario solo muestra la vista previa quieta
  (`GeofencePolygonPreview`); dentro de su scroll, arrastrar un mapa
  peleaba con el scroll.
- `GeofenceFormValues.vertices` guarda `[lng, lat]` sin el cierre; el
  anillo se cierra al armar el body (`GeoJsonPolygon.fromVertices`).

## Pantallas de trabajo (desde la Fase 6)

Las pantallas de los roles usan las piezas de auth (`AuthCurvedHeader`,
`AuthField`, `AuthMorphButton`, `AuthGlass`, `AuthPill`, `AuthBackButton`,
`ResetPasswordStrength`) y estas, compartidas:

| Widget | Dónde | Para qué |
| --- | --- | --- |
| `SectionHeader` | `home/presentation/widgets` | Encabezado curvo compacto con volver, título y subtítulo; `bottom` queda montado sobre la curva. |
| `signOut` | `home/presentation/widgets` | Cerrar sesión y volver al login, para todos los inicios. |
| `StatusPill` / `PillTone` | `core/widgets` | Estado en pastilla (positivo, atención, negativo) con rebote al cambiar. |
| `StatusCard` + `RowActionButton` | `core/widgets` | Tarjeta de lista con estado y acción a la derecha. |
| `ChoicePill` | `core/widgets` | Chip elegible (relleno o teñido, con ícono o check). |
| `SlidingSegmented` | `core/widgets` | Filtro con pastilla que se desliza (`null` = "Todas"). |
| `showConfirmSheet` | `core/widgets` | Hoja inferior para confirmar suspender o reactivar. |
| `FormSheetCard` | `core/widgets` | Tarjeta del formulario sobre la curva. |
| `MessageView` | `core/widgets` | Lista vacía o error de Nest, centrado. |
| `RiseIn` (`RiseIn.stagger`) / `PressScale` / `CountUpText` | `core/widgets` | Entrada en cascada, hundirse al tocar y números que cuentan. Respetan "reducir movimiento". |

Los formularios validan en la pantalla con `Validators` y pasan
`errorText` + `shakeCount` a cada `AuthField`, igual que el login
(`HubFormValues.validate`, `UserFormValues.validate`).

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
- Los fixtures van en su propio archivo (`local_fixtures.dart`) o en el
  repositorio local si son pocos.
- `mine()` es el único método que convierte un 404 en `null`; el resto relanza
  para que la UI muestre el mensaje de Nest.
- `ProviderScope` usa `retryOnlyWithoutResponse` (`lib/app/provider_retry.dart`):
  un error con código HTTP de Nest no se reintenta y se muestra de una vez;
  solo se reintenta (3 veces) cuando el servidor no respondió.
- Las listas sin socket (cola, programados, pending-load, historial) se
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
3. Usar los fixtures documentados abajo.
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

