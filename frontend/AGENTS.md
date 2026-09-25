# AGENTS.md — frontend (Flutter)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/principios-de-diseno.md`](../context/principios-de-diseno.md).

## Qué es este lado

Una **sola** aplicación Flutter. Tras autenticarse, el usuario ve el flujo de **su rol**. No hay app web ni un segundo proyecto Flutter.

## Contexto de negocio que el frontend no debe perder

AirDrop simula logística aérea médica para Valledupar y zonas cercanas. El frontend representa cuatro roles: **solicitante**, **despachador**, **operador de flota** y **administrador**. No existe un rol receptor: la entrega se confirma con un código de un uso.

Flujo central que las pantallas deben respetar:

```text
pedido → autorización → decisión y ruta → confirmación de carga → vuelo simulado → código o retorno
```

Reglas de negocio que no deben contradecirse:

- Autorizar reserva/selecciona un dron, pero **no inicia el vuelo**.
- La simulación empieza únicamente después de que el despachador confirma la carga.
- Emergencia tiene prioridad sobre un pedido programado.
- La ruta debe evitar geovallas y trabajar a altitud/corredor fijo.
- En destino se esperan 5 minutos por el código; sin código, el paquete vuelve a la central.
- Si no hay dron elegible, se muestra fallback; no se rechaza ciegamente.
- El frontend no debe inventar hardware real, clima real, 3D, multi-ciudad ni un rol receptor.

La autoridad completa de negocio está en [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/); este resumen sirve para no perder el contexto durante una sesión de implementación.

## Organización sugerida (cuando exista código)

Feature-first, alineado a dominios del backend:

```
lib/
  app/           # MaterialApp, rutas, inyección simple
  theme/         # ThemeData, colores, tipografía (única fuente de estilo)
  core/          # HTTP, WebSocket, storage, data source, widgets compartidos
  features/
    auth/
    hub/
    inventory/
    fleet/
    geofences/
    orders/
    tracking/    # mapa + telemetría (solicitante, operador)
    delivery/    # código de entrega (sin rol receptor)
    analytics/
```

No Clean Architecture de tres capas por feature “porque sí”. Suficiente:

- `data/` — API DTOs y un cliente
- `presentation/` — pantallas y un controller/notifier (Riverpod, Bloc o Provider: **uno** para todo el proyecto)

Elegir un gestor de estado y no mezclar tres.

## UI

- Español de Colombia (RNF-15). Identificadores en inglés.
- Contraste y tamaños legibles (RNF-10).
- Reutilizar widgets. Ningún widget supera **60 líneas**; si pasa, se descompone.
- Tema solo en `lib/theme/`. Las pantallas leen `Theme.of(context)`.
- El mapa y el socket de telemetría se implementan **una vez** en `core` o `features/tracking` y se reutilizan.

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

- `local` — fixtures/JSON en el cliente.
- `remote` — HTTP hacia Nest.

La UI no importa DTOs de red ni archivos JSON. Si el endpoint no está listo, la feature queda en `local`.

## Contrato con el backend

- REST para CRUD y comandos (crear pedido, autorizar, dibujar geovalla).
- WebSocket solo para telemetría y, si conviene, cambios de estado en vivo. Reconexión automática (RNF-12).
- No persistir JWT en texto plano si la plataforma ofrece almacenamiento seguro.

## Ejecución y validación del frontend

Desde `frontend/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

También están disponibles Chrome/Edge si se necesita revisar en web. Para Android/iOS se usa el dispositivo o emulador configurado. El backend remoto espera `http://localhost:3000`; en el emulador Android, `localhost` apunta al propio emulador y se debe usar `http://10.0.2.2:3000` cuando se conecte el backend real.

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
- `RegisterRequest` puede enviar correo, celular o ambos; para despachador y operador el correo es obligatorio.
- El OTP de registro dura 10 minutos; el de reset, 15 minutos.

## Alcance

No inventar pantallas fuera del MVP (multi-ciudad, clima real, tienda, chat médico). Roles y pantallas salen de [`../context/requisitos.md`](../context/requisitos.md) y [`../context/casos-de-uso.md`](../context/casos-de-uso.md).

---

## Estado de las fases (temporal)

> **Bloque temporal.** Sirve para que cada sesión de chat continúe donde
> quedó la anterior (una sesión de chat por fase). **Cuando las 6 fases
> estén completas, eliminar todo este bloque** —su único propósito es la
> continuidad entre sesiones—.

Plan de desarrollo frontend: una fase por sesión, rama `feature/…` desde
`develop` y su PR a `develop`.

| # | Fase | Alcance | Estado |
| --- | --- | --- | --- |
| 0 | Preparación | `pubspec` con dependencias base (riverpod, dio, secure storage) y `sdk: ^3.12.0` | ✅ Hecha (PR #7) |
| 1 | Núcleo | `lib/core` (field_limits, api_exception, data source, token store, ApiClient), tema en `lib/theme`, widgets + `Validators`, rutas con placeholders y `main` con `ProviderScope` | ✅ Hecha (PR #7) |
| 2 | Auth | Pantallas de login, registro, recuperar/restablecer contraseña, verify-otp y perfil; `AuthRepository` (local\|remote) y controller Riverpod contra los 9 endpoints de `/auth`; TTL de OTP (10 min registro / 15 min reset) | ✅ Hecha |
| 3 | Homes por rol | Homes de solicitante, despachador, operador de flota y administrador; resolución de rol con `GET /auth/me` y redirect real por sesión (reemplaza el placeholder `/home`) | ✅ Hecha |
| 4 | Módulos | Frente A: centrales, usuarios e inventario · Frente B: flota y geovallas (CRUDs con `AppTextField`, `PrimaryButton` y `Validators`) | ⬜ Pendiente |
| 5 | Prueba manual | Recorrido completo con los 4 roles contra el backend corriendo + pulido final | ⬜ Pendiente |

### Estado real al cerrar la Fase 2 — 24 de septiembre de 2026

- Rama de trabajo: `feature/frontend-auth`, creada desde `develop`.
- La Fase 2 de Auth está implementada y probada; no se modificó `backend/`.
- Implementados `auth_models.dart`, `auth_repository.dart`, `remote_auth_repository.dart` y `local_auth_repository.dart` bajo `lib/features/auth/data/`.
- `RemoteAuthRepository` cubre los 9 endpoints de `/auth`: register, verify-otp, resend-otp, login, logout, forgot-password, reset-password, me y update profile.
- `LocalAuthRepository` permite trabajar sin NestJS con fixtures en memoria. Fixtures de desarrollo: `demo@airdrop.local / Demo1234`, `despacho@airdrop.local / Despacho123`, `operador@airdrop.local / Operador123`, `admin@airdrop.local / Admin1234`; OTP local `123456`. No son credenciales de producción.
- `RegisterRequest` acepta `email` y `phone` independientes porque el backend exige al menos uno y permite ambos; despachador y operador requieren correo.
- `AuthController` usa Riverpod 3, guarda el JWT únicamente mediante `TokenStore`, restaura la sesión con `me()` y no cambia el estado global a loading durante login o verificación OTP.
- Pantallas reales: `login`, `register`, `verify-otp`, `forgot-password`, `reset-password` y `profile`. OTP de registro: 10 minutos; reset: 15 minutos.
- `routerProvider` protege `/home` y `/profile`, permite las rutas públicas de Auth y sincroniza un `401` con el estado de sesión.
- Referencia visual de Stitch: <https://stitch.withgoogle.com/projects/1947458192612690185>.
- `DataSource.remote` sigue siendo el origen activo. Para una maqueta sin backend, cambiar temporalmente `appDataSource` a `DataSource.local`; no usar fixtures contra la API real.
- Pruebas frontend ejecutadas: `flutter analyze` sin errores y `flutter test` con 12 pruebas correctas. No se ejecutaron e2e contra NestJS porque el backend no se modificó ni se levantó en esta fase.
- En Fase 2 el único placeholder de navegación era `/home`; en Fase 3 fue reemplazado por `RoleHomeScreen`. `/unauthorized` y el error global siguen usando `PlaceholderScreen` intencionalmente.
- No se hicieron `commit`, `push` ni PR; el usuario debe hacerlos al terminar la revisión.

### Estado real al cerrar la Fase 3 — 25 de septiembre de 2026

- Rama de trabajo: `feature/frontend-homes`, creada desde `develop`; `RoleHomeScreen` resuelve los cuatro roles desde `AuthState.user.role` y reemplaza el placeholder `/home`.
- `HomeShell` mantiene perfil y logout; el home de despachador consulta `GET /hubs/me` y solo habilita Inventario cuando la central está `approved`. Los homes de operador y administrador muestran Flota/Geovallas y Centrales/Cuentas institucionales.
- Validación manual completada con `DataSource.local`, `flutter analyze` sin errores y `flutter test` con 17 pruebas correctas. Se restauró `DataSource.remote` como origen predeterminado; no se modificó `backend/` ni se hicieron commit, push o PR.

### Siguiente paso: Fase 4 — Módulos

1. Frente A: centrales, usuarios institucionales e inventario.
2. Frente B: flota y geovallas con CRUDs, `AppTextField`, `PrimaryButton` y `Validators`.
3. Reutilizar la capa de hubs creada en Fase 3 y respetar el estado `approved` del backend.
4. Validar cada módulo por rol antes de avanzar.

**Protocolo de sesión:**

1. **Al iniciar:** trabajar solo la primera fase `⬜` de la tabla; leer `lib/core`, `lib/theme` y `lib/app` antes de escribir código.
2. **Estilo de trabajo:** avanzar paso a paso — explicar cada paso y esperar la confirmación del usuario antes de ejecutarlo (así se trabajaron las fases 0 y 1).
3. **Al terminar la fase:** marcarla `✅` aquí con 1-3 líneas de lo que quedó hecho; el agente guía, el usuario hace el commit, push y PR (regla del `AGENTS.md` raíz).
4. **No reabrir** filas ya `✅` ni borrar la tabla hasta que la Fase 5 esté completa; entonces eliminar el bloque entero.

**Decisiones tomadas en sesiones anteriores (no reabrir):**

- Riverpod 3 es el **único** gestor de estado; el JWT vive solo en `FlutterSecureStorage` vía `TokenStore`.
- HTTP: `defaultBaseUrl` en `lib/core/network/api_client.dart` — `http://localhost:3000` (emulador Android: `http://10.0.2.2:3000`), **sin** prefijo `/api`.
- UI: tema único en `lib/theme/` (tokens Stitch: cyan `#06B6D4`, `themeMode: ThemeMode.system`); `google_fonts` **^8.2.1** (la 6.x no compila con Dart 3.12+), titulares en Plus Jakarta Sans y cuerpo en Inter.
- Origen de datos hoy: `DataSource.remote` (`lib/core/data/data_source_config.dart`).
- Validar siempre con `Validators` + `FieldLimits` (el celular se limpia de símbolos igual que Nest antes del regex).
