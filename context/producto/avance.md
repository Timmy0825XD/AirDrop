# Avance del frontend después de auth

Plan por fases del frontend Flutter a partir de la guía 25 (`learning/25-front-pending-despues-de-auth.md`, local y fuera de git). Todo agente que entre al repo lee este archivo para saber en qué fase vamos.

## Cómo se trabaja una fase

1. Se crea una rama nueva desde `develop`. No se trabaja en `develop` ni en `main`.
2. Se siguen los pasos en orden (Fase N · Paso M). Cualquier cambio fuera de los pasos se consulta antes.
3. Al cerrar: se actualiza este archivo y los `.md` que apliquen, se corren `flutter analyze` y `flutter test`, y se entrega el resumen de lo hecho junto con el commit y el título y body del PR. El commit, el push y el PR los hace una persona del equipo.

## Estado

| Fase | Tema | Rama | Estado |
| --- | --- | --- | --- |
| 0 | Preparación y documento de avance | `docs/plan-fases-front` | Hecha (PR pendiente) |
| 1 | Rediseño de auth con transiciones | `style/rediseno-auth` | Pendiente |
| 2 | Autorizar y confirmar carga (HU-21, HU-35) | `feature/autorizar-carga-front` | Pendiente |
| 3 | Telemetría y mapa en vivo (HU-26 a HU-28) | `feature/tracking-front` | Pendiente |
| 4 | Geovalla sobre el mapa (HU-14) | `feature/geovalla-mapa` | Pendiente |
| 5 | Rediseño del administrador | `style/rediseno-admin` | Pendiente |
| 6 | Rediseño del despachador | `style/rediseno-despachador` | Pendiente |
| 7 | Rediseño del solicitante y el operador | `style/rediseno-solicitante-operador` | Pendiente |
| 8 | Cierre y pruebas de punta a punta | `test/flujos-front` | Pendiente |

## Fase 0 — Preparación y documento de avance

- Paso 1: Resolver el cambio pendiente en `frontend/macos/Flutter/GeneratedPluginRegistrant.swift`.
- Paso 2: Crear este archivo.
- Paso 3: Enlazarlo desde `context/index.md`, `INDEX.md` y `frontend/AGENTS.md`.
- Paso 4: Copiar la guía 25 a `learning/`.
- Paso 5: Correr `flutter analyze` y `flutter test` para conocer la base. Resultado (2026-10-15): analyze sin issues, 123 tests en verde.
- Paso 6: Cerrar la fase.

## Fase 1 — Rediseño de auth con transiciones

Referencia visual: canvas "AirDrop · Auth transiciones" en Claude Design (https://claude.ai/artifact/93zRSvo1BoLixvXs9dzjqC). Solo pantallas de `features/auth/presentation/`. No cambia carpetas, rutas ni bodies.

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

## Fase 3 — Telemetría y mapa en vivo (HU-26 a HU-28)

- Paso 1: `socket_io_client`, `flutter_map` y `latlong2` en `pubspec.yaml`.
- Paso 2: `telemetry_models.dart` (vistas map y full) con tests.
- Paso 3: `telemetry_client.dart`: GET inicial y socket (suscripción, reconexión, cierre).
- Paso 4: `tracking_providers.dart`.
- Paso 5: `tracking_screen` con mapa, ruta, ficha y fase de vuelo (`userAgentPackageName` en el `TileLayer`).
- Paso 6: Router: `/tracking/:orderId` en `_parameterizedRole`.
- Paso 7: Botones "Ver vuelo" en historial, detalle y pending-load.
- Paso 8: Cerrar la fase.

## Fase 4 — Geovalla sobre el mapa (HU-14)

- Paso 1: Modo "dibujar" del mapa, sin socket.
- Paso 2: Polígono con taps, cerrado al enviar.
- Paso 3: Usarlo al crear y editar geovallas.
- Paso 4: Cerrar la fase.

## Fases 5 a 7 — Rediseño por rol

Mismo lenguaje visual de la Fase 1. Una rama por rol para que cada PR sea revisable.

- Paso 1: Aplicar el diseño a los homes y pantallas del rol, sin cambiar rutas ni bodies.
- Paso 2: Partir los widgets de más de 60 líneas.
- Paso 3: Actualizar los tests que verifican textos.
- Paso 4: Cerrar la fase.

## Fase 8 — Cierre y pruebas de punta a punta

- Paso 1: Recorrer con el backend real los flujos de la sección 10 de la guía 25.
- Paso 2: Corregir lo que aparezca.
- Paso 3: Anotar aquí lo que le falta al backend.
- Paso 4: Cerrar la fase.

## Pendiente del backend (no lo resuelve el frontend)

- Fallback con estado `reasignado` (RF-18); hoy solo responde 409.
- Código de entrega, espera de 5 min, retorno y cuarentena (Sprint 6).
- Bandeja de telemetría del operador (RU-18, CU-19): la API no le dice qué pedido lleva su dron.
