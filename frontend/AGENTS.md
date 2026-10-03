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
armar una pantalla nueva, reusar lo que ya existe:

| Widget | Para qué |
| --- | --- |
| `AuthPage` | Fondo con brillo, `SafeArea`, scroll y ancho máximo. Toda pantalla de auth lo usa como raíz. |
| `AuthGlow` / `AuthEntrance` | El brillo y la animación de entrada por dentro del `AuthPage`. |
| `AuthTopBar` | Botón de volver + título. `onBack` en `null` lo oculta; `showTitle: false` deja solo la flecha. |
| `LoginGlassCard` | La superficie translúcida que envuelve los formularios. |
| `LoginAlert` / `LoginFormAlert` | Mensaje de error o de éxito con animación. `LoginFormAlert` ya maneja el caso `null` sin ocupar espacio. |
| `LoginButton` | Botón principal con estado de carga. Es `ElevatedButton`, no `FilledButton`. |
| `LoginField` | Campo con label en **mayúsculas** (`toUpperCase()`), hint e ícono. |
| `RegisterField` | Igual que `LoginField` pero con `badge`, `prefix` y `suffix` opcionales. |

Colores siempre con `Theme.of(context)` y `withValues(alpha: ...)` para lo
translúcido. Nunca hex dentro de una feature.

Convenciones que ya están en el código:

- Los labels de campo van en mayúsculas con `letterSpacing`. Los assert de los
  tests buscan el texto en mayúsculas.
- El registro y el login no piden rol. El registro es solo del solicitante y
  usa `DocumentTypeTabs` para el tipo de documento; el login usa el bloque de
  método de contacto.
- Un formulario reusa `RegisterFieldValidators` o `LoginFieldValidators` para no
  pasar validadores uno por uno.

## Paleta y tokens visuales

La fuente de verdad ejecutable es [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart). No crear una segunda paleta ni escribir colores hardcodeados en las pantallas.

### Tokens de marca

| Token | Valor | Uso |
| --- | --- | --- |
| `primary` | `#06B6D4` | Marca, enlaces, foco y elementos activos |
| `secondary` | `#22D3EE` | Botones principales y acentos cyan |
| `tertiary` | `#10B981` | Éxito y estados positivos |
| `error` | `#E5484D` | Errores y acciones destructivas |

### Tema oscuro

| Token | Valor | Uso |
| --- | --- | --- |
| Background | `#0A0E14` | Fondo general |
| Surface | `#141A21` | Tarjetas, campos y superficies |
| Texto principal | `#EAF0E5` | Títulos y contenido principal |
| Texto secundario | `#8B98A5` | Ayudas y textos secundarios |

### Tema claro

| Token | Valor | Uso |
| --- | --- | --- |
| Background | `#F5F7FA` | Fondo general |
| Surface | `#FFFFFF` | Tarjetas, campos y superficies |
| Texto principal | `#10151B` | Títulos y contenido principal |
| Texto secundario | `#5B6672` | Ayudas y textos secundarios |

- Radius principal: `18`.
- `themeMode`: `ThemeMode.system`.
- Titulares: **Plus Jakarta Sans**.
- Cuerpo y etiquetas: **Inter**.
- `google_fonts`: `^8.2.1`.
- Las superficies translúcidas se construyen con `color.withValues(alpha: ...)`, no con colores nuevos.
- Las pantallas leen `Theme.of(context)` y los widgets reutilizados; no se definen RGB/hex dentro de features.
- Stitch es la referencia visual: <https://stitch.withgoogle.com/projects/1947458192612690185>. La app conserva tema claro y oscuro porque el tema sigue el sistema.

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

## Contrato con el backend

- REST para CRUD y comandos (crear central, crear dron, dibujar geovalla).
- WebSocket solo para telemetría y, si conviene, cambios de estado en vivo. Reconexión automática (RNF-12).
- No persistir JWT en texto plano si la plataforma ofrece almacenamiento seguro.
- El contrato verificado de cada módulo está en la sección 2 de
  [`../PLAN.md`](../PLAN.md). Si el backend cambia, ese archivo se actualiza en
  el mismo PR.

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
| `phone` | **obligatorio**, 10 dígitos. Es donde llega el código de un uso |
| `email` | opcional |
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
como `573001234567` y el registro, el login y la recuperación respondían 400.

La regla vive **en un solo lugar**: `normalizeColombianPhone` en
[`lib/core/colombian_phone.dart`](lib/core/colombian_phone.dart). La usan
`Validators.phone`, `AuthContact.parse` y `LocalAuthRules.normalizePhone`.
No la reescribas en otro archivo. Cuando cambies un campo de contacto, pasa
por ahí.

El campo de login es único y `AuthContact.parse` decide correo o celular.
Como el mismo helper alimenta los tres caminos, escribir `+57 300 123 4567`
funciona igual que `300 123 4567` en las tres pantallas.

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

---

## Estado de las fases → ver [`../PLAN.md`](../PLAN.md)

> El plan de fases vigente vive en [`../PLAN.md`](../PLAN.md). Este bloque se
> conserva solo como diario de lo ya entregado. **Cuando `PLAN.md` se elimine,
> este bloque se elimina con él.**

Plan de desarrollo frontend: una fase por sesión, rama `feature/…` desde
`develop` y su PR a `develop`.

| # | Fase | Alcance | Estado |
| --- | --- | --- | --- |
| 0 | Preparación | `pubspec` con dependencias base (riverpod, dio, secure storage) y `sdk: ^3.12.0` | ✅ Hecha (PR #7) |
| 1 | Núcleo | `lib/core` (field_limits, api_exception, data source, token store, ApiClient), tema en `lib/theme`, widgets + `Validators`, rutas con placeholders y `main` con `ProviderScope` | ✅ Hecha (PR #7) |
| 2 | Auth | Pantallas de login, registro, recuperar/restablecer contraseña, verify-otp y perfil; `AuthRepository` (local\|remote) y controller Riverpod contra los 9 endpoints de `/auth`; TTL de OTP (10 min registro / 15 min reset) | ✅ Hecha |
| 3 | Homes por rol | Homes de solicitante, despachador, operador de flota y administrador; resolución de rol con `GET /auth/me` y redirect real por sesión (reemplaza el placeholder `/home`) | ✅ Hecha |
| 4 | Módulos | Frente A: centrales, usuarios e inventario · Frente B: flota y geovallas | ⬜ Anulada: el contrato de backend cambió (ver `PLAN.md`) |

El plan actual son las Fases 1 a 9 de [`../PLAN.md`](../PLAN.md): verificación
de `context/`, núcleo y deuda, auth realineado, centrales, cuentas, inventario,
flota, geovallas y cierre. La Fase 4 anterior queda anulada porque el backend
pasó de `pending_approval / approved / rejected` a `active / suspended`, el
registro público quedó solo para solicitante y las cuentas institucionales las
crea el administrador.

### Diario: Auth y Homes (25 de septiembre de 2026)

Fases 2 y 3 del plan viejo, sobre el contrato de backend anterior.

- `feature/frontend-auth` y `feature/frontend-homes`. `AuthRepository`
  (local\|remote) contra los 9 endpoints de `/auth`. Fixtures locales:
  `demo@airdrop.local / Demo1234`, `despacho@airdrop.local / Despacho123`,
  `operador@airdrop.local / Operador123`, `admin@airdrop.local / Admin1234`;
  OTP local `123456`. No son credenciales de producción.
- `RoleHomeScreen` resuelve los cuatro roles desde `AuthState.user.role`.
  `HomeShell` mantiene perfil y logout.
- `DataSource.remote` como origen predeterminado. `flutter test` con 17 pruebas.
- **Lo de esta etapa ya no vale:** el registro pedía rol y `PublicUser` traía
  `hubId`. Ver la sección de la Fase 3.

### Estado real al cerrar la Fase 2 del plan nuevo — 1 de octubre de 2026

Rama `feature/frontend-nucleo`, desde `develop` con los PR #14 a #17 del backend ya
mergeados. **No se tocó `backend/`.**

**a. `getJson` con query.** `api_client.dart` acepta
`getJson(path, {Map<String, String>? query})` y lo manda como
`queryParameters`. Lo necesitan `GET /hubs?status=`, `GET /users?role=&status=`
y `GET /fleet/drones?hubId=`.

**b. `FieldLimits`.** `documentNumber = 15` y `lotCode = 20`, más los regex que
necesitan los validadores: `documentDigitsRegex` (cédula, 6–10 dígitos),
`documentPptRegex` (6–15 alfanuméricos), `lotCodeRegex` (3–20 con guiones) e
`isoDateRegex`.

**c. `Validators`.** 13 métodos nuevos: `documentDigits`, `documentPpt`,
`lotCode`, `isoDate`, `latitude`, `longitude`, `reason`, `droneIdentifier`,
`hubName`, `medicationName`, `geofenceName` y `address`. Los mensajes son los
mismos que devuelve Nest. `invalidDocumentMessage` es la constante compartida
para cédula y PPT, igual que el backend.

**d. Partición de pantallas.** Las 6 pantallas grandes de auth quedaron
partidas en widgets por pantalla, siguiendo el patrón
`auth_page.dart` + `widgets/<pantalla>/<screen>_content.dart`:

| Pantalla | Antes | Ahora |
| --- | --- | --- |
| `register_screen` | 342 | 207 |
| `profile_screen` | 285 | 83 |
| `reset_password_screen` | 325 | 176 |
| `verify_otp_screen` | 290 | 160 |
| `forgot_password_screen` | 224 | 105 |
| `login_screen` | 265 | 136 |

Widgets nuevos del andamiaje compartido: `auth_page.dart` (fondo, `SafeArea`,
scroll y ancho máximo), `login_form_alert.dart` (alerta con animación que ya
maneja el `null`), `login_security_footer.dart`, `login_credentials.dart`,
`register_fields.dart`, `profile_content.dart`, `profile_labels.dart`,
`profile_states.dart`, `otp_verify_content.dart`, `reset_password_form.dart`,
`reset_code_section.dart`, `reset_code_header.dart`, `reset_resend_button.dart`
y `forgot_password_content.dart`.

`register_role_section.dart`Vivió aquí y se borró en la Fase 3, cuando el
registro dejó de pedir rol.

`AuthTopBar` pasó a `onBack` opcional y `showTitle`, para que la verificación del
código no repita el título.

**e. `local_auth_repository`.** 321 → 186 líneas. Se partió por responsabilidad en
`local_user.dart` (el usuario de la sesión simulada, con `toPublicUser()`),
`local_fixtures.dart` (las 4 cuentas de prueba + `localFixtureHubId`) y
`local_auth_rules.dart` (normalización y mensajes, con `LocalAuthRules.otp` y
`tokenPrefix`).

**Verificación:** `flutter analyze` sin errores y `flutter test` con **36
pruebas** (subieron de 17: 18 de los validadores nuevos más el ajuste de
`widget_test.dart` y la firma del `FakeApiClient`).

**Pendiente de esta fase:** 12 widgets siguen sobre las 60 líneas. Parte son
pantallas cuyo `State` no se puede partir sin inventar una capa
(`register_screen` 207, `reset_password_screen` 176, `verify_otp_screen` 160,
`login_screen` 136) y parte son widgets del rediseño visual que no se tocaron
(`otp_boxes_input` 168, `profile_identity_card` 141, `register_role_tabs` 128).
Queda decidir si se parten en una fase corta o se aceptan, porque la Fase 3 va a
reescribir `register_screen` y `profile_screen` de todos modos.

**Dos bugs encontrados y documentados, no corregidos a propósito:**

- `Validators.phone('+57 300 123 4567')` **falla**, y está bien que falle por
  ahora. Nest solo quita lo que no es dígito, así que el número llega como
  `573001234567` y no cumple los 10 dígitos. La Fase 3 quita el prefijo `57`.
  Hay un test en `test/core/validators_test.dart` que deja constancia.
- `register_screen` sigue mandando `role` en el body. El backend nuevo usa
  `forbidNonWhitelisted`, así que el registro público está **roto contra la API
  real** hasta la Fase 3. También sobran `register_role_tabs.dart` y
  `register_role_section.dart`.

> Los dos bugs de arriba **quedaron corregidos** en la Fase 3. El registro ya
> no manda `role` y el prefijo `57` se quita en `core/colombian_phone.dart`.
> `register_role_tabs.dart` y `register_role_section.dart` se borraron. El
> texto de arriba se conserva como el registro de lo que se encontró.

**Protocolo de sesión:**

1. **Al iniciar:** trabajar solo la primera fase `⬜` del plan; leer `lib/core`, `lib/theme` y `lib/app` antes de escribir código.
2. **Estilo de trabajo:** avanzar paso a paso — explicar cada paso y esperar la confirmación del usuario antes de ejecutarlo.
3. **Al terminar la fase:** marcarla `✅` en [`../PLAN.md`](../PLAN.md) con 1–3 líneas de lo que quedó; el agente guía, el usuario hace el commit, push y PR (regla del `AGENTS.md` raíz).
4. **Rama por fase:** `feature/frontend-nucleo`, `feature/frontend-auth`, `feature/frontend-hubs`, etc., siempre desde `develop`. Si ya hay trabajo sin commitear en `develop`, se guarda con `git stash push`, se crea la rama y se recupera con `git stash pop`; nunca se commitea en `develop`.
4. **No reabrir** filas ya `✅` de este diario. El plan vigente y su tabla están en [`../PLAN.md`](../PLAN.md); cuando la Fase 9 de ese plan cierre, se eliminan `PLAN.md` y este bloque.

**Decisiones tomadas en sesiones anteriores (no reabrir):**

- Riverpod 3 es el **único** gestor de estado; el JWT vive solo en `FlutterSecureStorage` vía `TokenStore`.
- HTTP: `defaultBaseUrl` en `lib/core/network/api_client.dart` — `http://localhost:3000` (emulador Android: `http://10.0.2.2:3000`), **sin** prefijo `/api`. En web decide con `kIsWeb` **antes** de tocar `Platform.isAndroid`, porque en compilación web `Platform` lanza `Unsupported operation: Platform._operatingSystem` y la app no arranca.
- UI: tema único en `lib/theme/` (tokens Stitch: cyan `#06B6D4`, `themeMode: ThemeMode.system`); `google_fonts` **^8.2.1** (la 6.x no compila con Dart 3.12+), titulares en Plus Jakarta Sans y cuerpo en Inter.
- Origen de datos hoy: `DataSource.remote` (`lib/core/data/data_source_config.dart`).
- Validar siempre con `Validators` + `FieldLimits`.
- El celular se normaliza con `normalizeColombianPhone` de
  [`lib/core/colombian_phone.dart`](lib/core/colombian_phone.dart) antes de
  validar o de mandar. No reescribir la regla en otro archivo.

### Estado real al cerrar la Fase 3 — 2 de octubre de 2026

Rama `feature/frontend-auth-realineado`, desde `develop` con el PR #18 ya
mergeado. **No se tocó `backend/`.** `flutter analyze` sin issues y
`flutter test` con **49 pruebas** (subieron de 36).

El registro público ya no manda `role`, así que `forbidNonWhitelisted` lo
acepta. `PublicUser` trae documento y `hubIds`. El prefijo `57` se quita en
`core/colombian_phone.dart`, lo que arregló también el login y la
recuperación, que devolvían 400. `register_role_tabs.dart`,
`register_role_section.dart` y `role_selector.dart` se borraron.

**Pendiente de esta fase:** validar contra Nest con el backend arriba.
`flutter run` no se probó en esa sesión. **Quedó cerrado** en la sesión de la
Fase 4 (ver abajo).

### Estado real al cerrar la Fase 4 — 2 de octubre de 2026

Rama `feature/redisign-auth`. **No se tocó `backend/`.** `flutter analyze`
sin issues y `flutter test` con **50 pruebas**.

- Modelo `Hub` con `active | suspended`, `address`, `contactPhone`,
  `contactEmail` y coordenadas `double`; repositorio `mine | list | create |
  setSuspension`; `mine()` sigue siendo el único 404 → `null`.
- Rutas `/hubs` (admin), `/hubs/new` (admin) y `/hubs/me` (despachador), con
  guard `_roleRoutes` en `router.dart`.
- **Validación contra Nest con el backend arriba:** crear central en
  Valledupar → `active`; suspender → `suspended`; repetir la acción → `409
  "Esta central ya está activa."`; `latitud 999` → `400 "La latitud no es
  válida."`; `GET /hubs/me` como admin → `403`; como despachador con central
  → `200` con nombre y estado; despachador sin central → `404` que el
  repositorio convierte en `null`. Los 9 endpoints de `/auth` de la Fase 3
  quedaron verificados en el mismo backend arriba.
- **Bug encontrado en la validación:** `defaultBaseUrl` usaba
  `Platform.isAndroid`, que en compilación web lanza `Unsupported operation:
  Platform._operatingSystem` y la app no arrancaba en Chrome/Edge. Se arregló
  con `kIsWeb` antes de tocar `Platform`.

### Pendientes que dejó la Fase 3

| Qué | Dónde | Por qué |
| --- | --- | --- |
| `local_auth_repository.dart` en 240 líneas | `lib/features/auth/data/local/` | Candidato a otra partición en la Fase 9 |
| 12 widgets sobre 60 líneas | varios | La Fase 9 decide si se parten o se aceptan |

`dispatcher_cards.dart` ya **no** es pendiente: en la Fase 4 pasó a `Hub` con
`hub.isActive` y navega a `/hubs/me`.

### Estado real al cerrar la Fase 5 — 3 de octubre de 2026

Rama `feature/cuentas-fase5`. **No se tocó `backend/`.** `flutter analyze`
sin issues y `flutter test` con **50 pruebas**. Ningún widget nuevo pasa de
60 líneas.

- Feature `users` (`data/` con los 5 archivos del patrón + `presentation/`),
  reusando `PublicUser` de auth. El local replica los mensajes y el 409 de
  `UsersService`.
- `/users` y `/users/new` con guard de admin en `router.dart`. La tarjeta
  "Cuentas institucionales" del `admin_home` dejó de `showModulePreview`.
- `hub_multi_select`: dropdown único para despachador, chips para operador.
  La regla 1/≥1 vive en `hubSelectionError` de `user_form_values.dart`.
- La fila oculta Suspender/Activar en la cuenta propia (Nest responde 403).
- **Validación contra Nest (3 de oct):** crear despachador y operador con la
  misma central → ambos `active`; entran **sin OTP**; repetir suspensión →
  `409 "Esta cuenta ya está suspendida."`; reactivar → `active`; suspender la
  propia → `403`; central suspendida en el alta → `400 "Solo puedes asignar
  centrales activas."`; `role=requester` en query → `400`; `GET /users` nunca
  trae solicitantes.
- **Inventario de UI:** `frontend/tools/ui_inventory.ps1` genera
  `frontend/docs/ui_inventory.md` (pantalla/widget por feature y tamaño de
  cada clase, con las que pasan de 60 marcadas). Correrlo tras cada fase que
  agregue o borre UI: es el mapa de lo que habrá que retocar al rediseñar.

**Pendiente de la Fase 2 que sigue igual:** la línea "Homologación
Aeronáutica" de `register_info_banner.dart` y el sello "Cifrado TLS 1.3 de
Grado Clínico" de `login_security_footer.dart` son copy de maquetación. No
afirman nada falso sobre el MVP, pero tampoco describen una funcionalidad;
si la sustentación los señala, se cambian en una fase corta.

### Estado real al cerrar la Fase 6 — 3 de octubre de 2026

Rama `feature/fase6`. **No se tocó `backend/`.** `flutter analyze` sin issues
y `flutter test` con **62 pruebas** (50 → 62). Ningún widget de inventory pasa
de 60 líneas.

- Feature `inventory` (`data/` con los 5 archivos del patrón +
  `presentation/`): modelos con `SaleType`; el local replica los mensajes de
  `InventoryService` y `HubsService.requireActive`.
- `/inventory`, `/inventory/new` y `/inventory/:id` con guard de despachador;
  la edición busca el ítem en `inventoryProvider` (no existe `GET /inventory/:id`).
- El `diff()` del formulario solo envía lo que cambió: un PATCH sin cambios no
  se emite (Nest responde `400 "Debes enviar al menos un campo para actualizar."`).
- La tarjeta del home navega solo con central activa; el paso f invalida
  `inventoryProvider` desde `hubs_screen._toggle` (no desde el notifier, para
  no ciclar imports `hubs ↔ inventory`).
- **Validación contra Nest (3 oct):** CRUD `201/200/204`; lote `ab` →
  `400 "El lote debe tener entre 3 y 20 letras, números o guiones."`; central
  suspendida → `403 "La central está suspendida."` en GET y POST; DELETE
  repetido → `404 "El ítem de inventario no existe."`. Quedaron la central y
  el despachador de validación (`despacho.fase6@airdrop.local`).
- **Registro de UI regenerado:** 13 pantallas, 80 archivos widget, 20 clases
  >60 — todas preexistentes (auth y `hub_detail_content` de la Fase 4).

### Estado real al cerrar la Fase 7 — 3 de octubre de 2026

Rama `feature/fase7`, desde `develop`. **No se tocó `backend/`.** `flutter
analyze` sin issues y `flutter test` con **81 pruebas** (62 → 81). Ningún widget
de `fleet` pasa de 60 líneas.

- Feature `fleet` (`data/` con los 5 archivos del patrón + `presentation/`):
  `DroneModel`, `Drone` y `DroneStatus` con sus 4 valores. El repositorio local
  replica `FleetService` (orden de validaciones incluido) y acepta `drones` en
  el constructor para poder testear un estado que la UI nunca produce sola: un
  dron `in_mission`.
- **Pantallas nuevas:** `FleetScreen` (`/fleet`) y `DroneFormScreen`
  (`/fleet/new`), ambas con guard `fleetOperator` en `router.dart` (el
  `POST /fleet/drones` es solo del operador). La tarjeta "Flota" del home dejó
  `showModulePreview`; "Geovallas" sigue en preview hasta la Fase 8.
- La central elegida vive en `fleetHubProvider` y la efectiva en
  `effectiveHubProvider` (cae a la primera asignada): la auto-selección es del
  provider, nunca del `build`. El modelo se resuelve con `fleetModelsProvider`
  para mostrar `name` y guardar `id`.
- `out_of_service` **solo** por "Registrar mantenimiento"
  (`POST .../maintenance`, motivo y fecha obligatorios); `PATCH .../status`
  ofrece `available | maintenance` con motivo y fecha opcionales. Un dron
  `in_mission` no recibe acciones desde la UI.
- **Validación contra Nest (3 oct), con la app corriendo en Chrome sobre
  `DataSource.remote`:** alta `201`; identificador repetido →
  `409 "Ya existe un dron con este identificador."`; modelo inexistente →
  `404 "El modelo de dron no existe."`; central inexistente →
  `404 "La central no existe."`; central sin asignar →
  `403 "Esa central no está asignada a tu cuenta."`; central suspendida →
  `403 "La central está suspendida."`; `hubId` sin uuid →
  `400 "La central no es válida."`; identificador de 33 →
  `400 "El identificador no puede superar 32 caracteres."`; fecha no ISO →
  `400 "La fecha estimada debe ser AAAA-MM-DD."`; `PATCH` con `in_mission` →
  `400 "El estado debe ser available, maintenance o out_of_service."`; dron en
  misión (marcado en datos) → `409 "No puedes cambiar el estado de un dron en
  misión."` en `PATCH` y en `POST .../maintenance`. Recorrido de UI: hoja de
  estado → mantenimiento → volver a disponible (borra motivo y fecha), alta de
  `DRON-03` con modelo y especificaciones → vuelve a la flota, validaciones de
  cliente (`Escribe el identificador.`, `Selecciona un modelo de dron.`) y el
  `403` de la central suspendida mostrado en el snack. `GET /fleet/models` como
  admin → `200`; `GET /fleet/drones` como admin → `403` por no tener la central
  asignada.
- **Dos divergencias del repositorio local corregidas contra el contrato
  real:** (1) una cuenta suspendida produce `401` porque la filtra
  `JwtStrategy.validate` antes que `assertActiveOperator`, así que el local
  lanza `LocalAuthRules.expiredSession()` y no un `403`; (2) un motivo en
  blanco en `POST .../maintenance` **no** da `400` (Nest solo exige `@IsString`
  y guarda `reason.trim()`), y el local además validaba lo que los DTO validan:
  `MaxLength(160)` y `AAAA-MM-DD`.
- **Tests nuevos:** `test/features/fleet/data/local_fleet_repository_test.dart`
  (11), `test/features/fleet/data/fleet_models_test.dart` (6) y el recorrido de
  la tarjeta "Flota" en `role_home_test.dart`. También se pasó el `tokenStore`
  a `LocalFleetRepository` desde `fleet_providers.dart`: sin él la maqueta local
  no podía consultar la flota.
- **Registro de UI regenerado:** 15 pantallas, 88 archivos widget, 18 clases
  >60 — todas preexistentes (auth); ninguna de `fleet`.
- **Datos de validación que quedaron en la base:** central `Central Fase 7`
  (activa), `operador.fase7@airdrop.local / Operador123` y los drones `DRON-01`
  (disponible), `DRON-02` (mantenimiento, hasta 2026-10-15) y `DRON-03`
  (disponible). No hay `DELETE /fleet/drones`, así que se limpiaron a mano los
  drones de prueba sobrantes.
- **Nota conocida:** la pantalla no ve en caliente una suspensión hecha por el
  admin (`assignedHubsProvider` está en caché), por eso el banner "La central
  está suspendida." solo aparece con datos frescos; igual el envío responde con
  el `403` de Nest en el snack.

### Estado real al cerrar la Fase 8 — 3 de octubre de 2026

Rama `feature/geofences-fase8`. `flutter analyze` sin issues y `flutter test`
con **119 pruebas** (108 → 119). Ningún widget de `geofences` pasa de 60
líneas. **Sí se tocó `backend/`** (un fix de 2 líneas, con visto bueno del
usuario; ver abajo).

- Feature `geofences` (`data/` + `presentation/`): `GeoJsonPolygon` guarda el
  anillo exterior en `coordinates[0]` y expone `hasSameRing()`; repositorio
  remoto con los 4 verbos (`remove` no parsea el 204) y local con las
  validaciones de Nest (anillo ≥4 cerrado, primer y último punto iguales,
  `MaxLength` 80/160, `diff` vacío → "No hay cambios para guardar.").
- **Pantallas:** `GeofencesScreen` (`/geofences`), alta (`/geofences/new`) y
  edición (`/geofences/:id`), con guard `fleetOperator`. El cliente cierra el
  anillo al guardar (si cargó 3 vértices distintos, copia el primero al final)
  y al editar muestra los puntos sin repetir el cierre. La edición se prefiila
  desde `geofencesProvider` porque no existe `GET /geofences/:id`.
- La tarjeta "Geovallas" del home dejó `showModulePreview` y **se borró
  `module_preview.dart`** (era su último uso; paso b de la Fase 9 hecho).
- **Validación contra Nest (3 oct), con la app sobre `DataSource.remote`:**
  alta de 3 vértices → `201` y fila en la lista; editar solo el nombre → `200`
  con "Geovalla actualizada." (motivo y polígono intactos vía `GET`); borrar
  con confirmación → `204` con "Geovalla eliminada."; validación de cliente
  antes de enviar ("Escribe la longitud.") y mensaje de Nest mostrado en la UI
  ("Correo o celular y contraseña no coinciden." en el login).
- **Bug del backend encontrado en la validación y corregido:**
  `GeofencesService.update` leía `rows[0]` del `query()` con `UPDATE`, pero
  TypeORM (`PostgresQueryRunner`) devuelve `[rows, rowCount]` para
  `UPDATE/DELETE`; `row.polygon` llegaba a `JSON.parse(undefined)` y **todo
  `PATCH /geofences/:id` respondía 500** aunque el `UPDATE` sí se aplicaba.
  Fix desestructurando `const [rows] = ... as [GeofenceRow[], number]`; solo
  ese módulo usaba `UPDATE...RETURNING`, el contrato no cambió y `npm test`
  del backend quedó en verde (34 pruebas).
- **Registro de UI regenerado:** 17 pantallas, 94 archivos widget, 18 clases
  >60 — todas preexistentes (auth); ninguna de `geofences`.
- **Datos de validación que quedaron en la base:** ninguna geovalla (se creó,
  editó y borró en el recorrido). Se usó la cuenta
  `operador.fase7@airdrop.local / Operador123`: la de fixtures locales
  `operador@airdrop.local` no existe en la BD remota y Nest respondió `401`.
