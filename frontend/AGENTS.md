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

