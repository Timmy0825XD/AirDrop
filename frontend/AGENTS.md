# AGENTS.md — frontend (Flutter)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md) ni [`../context/principios-de-diseno.md`](../context/principios-de-diseno.md).

## Qué es este lado

Una **sola** aplicación Flutter. Tras autenticarse, el usuario ve el flujo de **su rol**. No hay app web ni un segundo proyecto Flutter.

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

## Origen de datos (local | remote)

El front no depende de que el backend ya exista. Cada feature habla con un **repositorio** (contrato). El origen se elige en **un** sitio (`lib/core/data`):

- `local` — fixtures/JSON en el cliente.
- `remote` — HTTP hacia Nest.

La UI no importa DTOs de red ni archivos JSON. Si el endpoint no está listo, la feature queda en `local`.

## Contrato con el backend

- REST para CRUD y comandos (crear pedido, autorizar, dibujar geovalla).
- WebSocket solo para telemetría y, si conviene, cambios de estado en vivo. Reconexión automática (RNF-12).
- No persistir JWT en texto plano si la plataforma ofrece almacenamiento seguro.

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
| 2 | Auth | Pantallas de login, registro, recuperar/restablecer contraseña y verify-otp; `AuthRepository` (local\|remote) y controller Riverpod contra los 9 endpoints de `/auth`; TTL de OTP (10 min registro / 15 min reset) | ⬜ **Siguiente** |
| 3 | Homes por rol | Home de admin / operador / solicitante, resolución de rol con `GET /auth/me` y redirect real por sesión (reemplaza el placeholder `/home`) | ⬜ Pendiente |
| 4 | Módulos | Frente A: centrales, usuarios e inventario · Frente B: flota y geovallas (CRUDs con `AppTextField`, `PrimaryButton` y `Validators`) | ⬜ Pendiente |
| 5 | Prueba manual | Recorrido completo con los 3 roles contra el backend corriendo + pulido final | ⬜ Pendiente |

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
