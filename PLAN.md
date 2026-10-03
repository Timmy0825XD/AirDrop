# PLAN.md — fases de trabajo (temporal)

> **Bloque temporal.** Continuidad entre sesiones de chat: una fase por sesión.
> Cuando las fases estén completas, eliminar este archivo y los punteros que lo
> referencian en los tres `AGENTS.md`.

Este plan **reemplaza** el bloque de fases que vivía en `frontend/AGENTS.md`
(Fases 0–5 de septiembre de 2026). Las Fases 0–3 de ese plan —preparación,
núcleo, auth y homes por rol— están **hechas** y son la base sobre la que se
construye esto; no se repiten. La Fase 4 de ese plan ("Módulos", que exigía
respetar el estado `approved`) queda **anulada**: el contrato cambió.

| Regla | Detalle |
| --- | --- |
| Rama | `feature/…` desde `develop`, un PR por fase. |
| Quién commitea | El agente guía; el usuario hace `commit`, `push` y PR (regla del `AGENTS.md` raíz). |
| Estado de datos | `DataSource.remote` es el origen por defecto. `local` solo para maqueta y se restaura antes de cerrar la fase. |
| Alcance de este plan | Solo `frontend/`. **El backend no se toca: ya está alineado.** |

---

## 1. Estado real del repositorio

Revisado el 1 de octubre de 2026 sobre `develop` (`29d6894`), que ya incluye los
PR #14 a #17 del backend (`feature/alinear-backend-sprint-2`) y la
reestructuración de `context/` en carpetas (`producto/`, `app/`, `entregas/`,
`legal/`, `diseno/`, `sustentacion/`).

| Capa | Estado |
| --- | --- |
| `frontend/lib/core` | Listo: `ApiClient` con JWT y manejo de 401, `TokenStore`, `ApiException`, `Validators`, `FieldLimits`, widgets, tema. |
| `frontend` Auth | **Alineado** desde la Fase 3: registro sin `role` con documento y celular obligatorio, `PublicUser` con `documentType`, `documentNumber` y `hubIds`, prefijo `57` normalizado. |
| `frontend` Homes | Homes de los 4 roles, `RoleHomeScreen`, `HomeShell`. Las tarjetas usan `showModulePreview` (snackbar). |
| `frontend` Hubs | Solo `mine()` con `HubSummary` y el enum viejo `pending_approval / approved / rejected`. |
| `backend` Auth | **Alineado**: registro sin `role` con `documentType` + `documentNumber` + celular, `PATCH /auth/me` con documento, `PublicUser` con `documentType`, `documentNumber` y `hubIds`. |
| `backend` Hubs | **Alineado**: `POST /hubs` de `admin` nace `active`, `GET /hubs` para `admin` y `fleet_operator`, `PATCH /hubs/:id/suspension`, `GET /hubs/me` exige exactamente una central, `requireActive`. |
| `backend` Users | **Alineado**: `POST /users` (`CreateInstitutionalUserDto`, nace `active`, sin OTP), `GET /users?hubId=` por join sobre `user_hubs`, `PATCH /users/:id/suspension`. |
| `backend` Inventory | **Alineado**: `lot` + `saleType`, fuera `requiresPrescription`, mensajes nuevos de rol, asignación y central suspendida. |
| `backend` Fleet | **Alineado**: `listDrones` valida que la central esté asignada (`Esa central no está asignada a tu cuenta.`). |
| `backend` Geofences | Completo y fiel al contrato objetivo. |
| `backend` Otros | Sin `Orders`, `Decision`, `Routing`, `Simulation`, `Telemetry`, `Analytics`. No se inventan. |
| `context/` | Reorganizado en carpetas. `context/app/roles.md` ya describe el modelo nuevo (registro de solicitante con documento, admin crea centrales y cuentas, sin aprobación). |

Relación usuario-central: **tabla `user_hubs`** (`users/user-hub-assignment.entity.ts`),
con `assignedHubIds(user)` en `users/hub-assignment.ts`. El despachador tiene
exactamente una; el operador, una o más.

**Conclusión: no hay bloqueo de backend.** Las Fases 4 a 8 se pueden hacer ya.

---

## 2. Contrato de Nest (verificado contra el código)

Verificado archivo por archivo en `develop`. Si al integrar una fase el API
responde otra cosa, **no se adapta el frontend**: se corrige el backend o se
acuerda el cambio aquí.

| Módulo | Contrato verificado | Dónde |
| --- | --- | --- |
| Auth | `POST /auth/register` sin `role`, `documentType` + `documentNumber` + celular obligatorio, correo opcional; respuesta `{ message, userId }` | `auth/dto/register.dto.ts` |
| Auth | Documento: cédula `^\d{6,10}$`, PPT `^[A-Z0-9]{6,15}$` tras trim + mayúsculas | `auth/auth.rules.ts:44` |
| Auth | `PATCH /auth/me` con documento, solo `requester`, tipo y número juntos | `auth/dto/update-profile.dto.ts` |
| Auth | `PublicUser` con `documentType`, `documentNumber`, `hubIds` | `users/users.service.ts:91` |
| Users | `POST /users`: `email` obligatorio, `hubIds` con exactamente 1 para despachador y ≥1 para operador, solo centrales `active`, nace `active` sin OTP | `users/dto/create-institutional-user.dto.ts` |
| Hubs | `POST /hubs` de `admin` nace `active`; `GET /hubs` de `admin` filtra por `status`, de `fleet_operator` solo asignadas por nombre | `hubs/hubs.controller.ts:40` |
| Hubs | `PATCH /hubs/:id/suspension` con `{ "suspended": bool }`; 409 si ya está en ese estado | `hubs/hubs.service.ts:78` |
| Hubs | `GET /hubs/me` exige exactamente una asignación: `No tienes una central asignada.` (404) | `hubs/hubs.service.ts:41` |
| Inventory | Ítem con `lot`, `saleType`; `La central está suspendida.`, `Solo el despachador gestiona el inventario de su central.`, `Debes tener una central asignada para gestionar inventario.` | `inventory/inventory.service.ts:105` |
| Fleet | `GET /fleet/drones?hubId=` valida la asignación del operador | `fleet/fleet.service.ts:63` |
| Común | `FIELD_LIMITS.documentNumber = 15`, `FIELD_LIMITS.lotCode = 20` | `common/field-limits.ts:6` |
| Geofences | CRUD + reglas de polígono + `204` en delete, sin cambios | `geofences/` |

Ya cumple y **no se toca**: `ValidationPipe` global con `whitelist`,
`forbidNonWhitelisted` y `transform`; 401 para cuenta no `active` en la
strategy; interceptor de `Authorization`; `AdminSeedService`
(`administrador.plataforma@gmail.com` / `Admin1234`, salvo `ADMIN_EMAIL` y
`ADMIN_PASSWORD`); módulo de geovallas; seed de `WINGCOPTER_198`.

---

## 3. Fases

| # | Fase | Alcance | Bloqueada por |
| --- | --- | --- | --- |
| 1 | Verificar `context/` | Confirmar que `context/` y el backend coinciden | ✅ hecha, sin cambios |
| 2 | Núcleo y deuda | `getJson` con query, `FieldLimits` y `Validators` nuevos, splitting de archivos >60 líneas | ✅ hecha |
| 3 | Auth realineado | Documento, `hubIds`, perfil, registro de solicitante | ✅ hecha |
| 4 | Centrales | Lista, alta y suspensión del admin; `/hubs/me` del despachador | ✅ hecha |
| 5 | Cuentas | Lista, alta, suspensión y reactivación de despachadores y operadores | ✅ hecha |
| 6 | Inventario | CRUD del despachador, bloqueado por central suspendida | Fase 4 |
| 7 | Flota | Modelos, drones por central, estado y mantenimiento del operador | Fase 4 |
| 8 | Geovallas | CRUD de polígonos del operador, ruta real, tests | — |
| 9 | Cierre | Recorrido manual de los 4 roles contra Nest, pulido y estado real | Todas |

### Fase 1 — Verificar `context/` ✅

**Cerrada sin cambios.** Los PR #14 a #17 trajeron el backend alineado y
`context/` fue reestructurado en carpetas. `context/app/roles.md` ya dice: el
solicitante se registra con documento y OTP, el administrador crea al despachador
en **una** central y al operador en **una o varias**, y el administrador crea la
central y puede suspenderla. `context/producto/requisitos.md` y
`casos-de-uso.md` ya están alineados con el modelo nuevo.

No hay nada que alinear en `context/`. Cero código y cero documentos tocados.

Lo que sí queda de aquella revisión, y sigue vigente:

| Regla | Detalle |
| --- | --- |
| Dominios de `context/` | Un módulo o feature por dominio, como en [`../context/diseno/principios.md`](../context/diseno/principios.md). |
| Hubs en el mapa mental | Alta por el administrador y estado `active / suspended`, no "registro, aprobación, perfil". |
| Backlog | HU-06 a HU-10 ya reescritos en el PR #14; no reabrir. |
| Bandera del lote | El ítem lleva `lot` y `saleType`; el flag de receta vive en el pedido (RF-27). |

---

### Fase 2 — Núcleo y deuda ✅

**Cerrada el 1 de octubre de 2026**, en `feature/frontend-nucleo`. No cambió
ningún contrato y no se tocó `backend/`.

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | `getJson` con query | `api_client.dart` acepta `getJson(path, {Map<String, String>? query})` con `queryParameters` de Dio. Lo necesitan `GET /hubs?status=`, `GET /users?role=&status=` y `GET /fleet/drones?hubId=` |
| b | `FieldLimits` | `documentNumber = 15`, `lotCode = 20`, más `documentDigitsRegex`, `documentPptRegex`, `lotCodeRegex` e `isoDateRegex`. Los mismos topes que `backend/src/common/field-limits.ts:6` |
| c | `Validators` | 13 métodos: `documentDigits`, `documentPpt`, `lotCode`, `isoDate`, `latitude`, `longitude`, `reason`, `droneIdentifier`, `hubName`, `medicationName`, `geofenceName`, `address`. `invalidDocumentMessage` es la constante compartida, igual que Nest |
| d | Partir pantallas | Las 6 pantallas grandes de auth, con el patrón `auth_page.dart` + `widgets/<pantalla>/<screen>_content.dart` |
| e | Partir `local_auth_repository` | Por responsabilidad: `local_user.dart`, `local_fixtures.dart` y `local_auth_rules.dart` |

Reducción de líneas: `register_screen` 342 → 207 · `profile_screen` 285 → 83 ·
`reset_password_screen` 325 → 176 · `verify_otp_screen` 290 → 160 ·
`forgot_password_screen` 224 → 105 · `login_screen` 265 → 136 ·
`local_auth_repository` 321 → 186.

**Validación:** `flutter analyze` sin errores y `flutter test` con **36 pruebas**
(antes 17). Las 18 nuevas son de `test/core/validators_test.dart`. Hubo que
ajustar dos cosas del rediseño previo: el assert de `widget_test.dart` busca
`ACCESO DE PERSONAL` porque los labels se renderizan en mayúsculas y el botón es
`ElevatedButton`, no `FilledButton`; y el `FakeApiClient` de
`remote_auth_repository_test.dart` necesita la firma nueva con `query`.

**Pendiente de esta fase:** 12 widgets siguen sobre las 60 líneas. Son pantallas
cuyo `State` no se puede partir sin inventar una capa, más tres widgets del
rediseño visual que no se tocaron. Queda decidir si se parten en una fase corta
o se aceptan, porque la Fase 3 reescribe `register_screen` y `profile_screen` de
todos modos.

### Fase 3 — Auth realineado

Arregla el registro, que hoy está roto contra la API real: sigue mandando
`role` y el backend nuevo usa `forbidNonWhitelisted`.

Los diez pasos se ejecutaron en cinco bloques, en el orden de la tabla de
abajo. Se agruparon así para que cada bloque dejara el árbol más cerca de
compilar: modelo y copy, celular, fixtures y repositorio local, pantallas, y
por último las pruebas.

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | `DocumentType` | Enum con `citizenship_id`, `foreigner_id`, `ppt` y su copy: Cédula de ciudadanía, Cédula de extranjería, PPT |
| b | `PublicUser` | Agregar `documentType` y `documentNumber`. Cambiar `hubId: String?` por `hubIds: List<String>` que lee `[]` si falta o no es lista |
| c | `RegisterRequest` | Quitar `role`. Agregar `documentType` y `documentNumber`. `phone` pasa a obligatorio, `email` sigue opcional |
| d | `UpdateProfileRequest` | Agregar `documentType` y `documentNumber`, que solo van juntos y solo si el rol es `requester` |
| e | `AuthContact.parse` | Si tras quitar los no dígitos quedan 12 y empiezan por `57`, quita el prefijo. El test que hoy espera `573001234567` pasa a esperar `3001234567`. Con esto también se arregla `Validators.phone('+57 …')`, que hoy falla |
| f | `register_screen` | Nombre, tipo de documento, número, celular (10 dígitos, obligatorio), correo opcional, contraseña, consentimiento. **Fuera `RoleSelector`**, `register_role_tabs.dart` y `register_role_section.dart` (se borran). El registro local solo crea `requester` |
| g | `profile_screen` | Muestra el documento si no es null. Editarlo solo con rol `requester` y siempre tipo + número juntos. La línea "Central operativa vinculada" pasa a mirar `hubIds.isNotEmpty` |
| h | Limpiar enums | `UserRole.canSelfRegister` y `requiresEmail` dejan de usarse aquí; el correo institucional se pide en el formulario de cuentas (Fase 5) |
| i | Fixtures locales | Los 4 usuarios de `local_fixtures.dart` llevan documento. `PublicUser.hubIds` en lugar de `hubId` |
| j | Tests | `PublicUser` con `hubIds` y documento · registro sin `role` · `AuthContact.parse` con prefijo `57` |

**Valida:** contra Nest, registrar un solicitante nuevo con documento y entrar
con el OTP que sale en el log.

---

### Fase 3 — Auth realineado ✅

Cerrada el 2 de octubre de 2026, en `feature/frontend-auth-realineado`, en
cinco bloques. **No se tocó `backend/`.** El registro público ya no manda
`role`, así que `forbidNonWhitelisted` lo acepta y el 400 desapareció.

| Bloque | Qué quedó |
| --- | --- |
| Modelo | `DocumentType` (`citizenship_id`, `foreigner_id`, `ppt`), `PublicUser` con `documentType`, `documentNumber` y `hubIds` en vez de `hubId`, `RegisterRequest` sin `role` con celular obligatorio, `UpdateProfileRequest` con documento |
| Copy | `document_type_labels.dart` y `document_type_tabs.dart` compartidos por registro y perfil |
| Celular | `core/colombian_phone.dart` quita el prefijo `57` en los 10 dígitos que Nest exige |
| Local | `local_user` y fixtures con documento, `LocalAuthRules.normalizeDocument`, `register` siempre `requester`, `updateProfile` desarmado en cinco métodos |
| Pantallas | Registro sin rol con selector de documento; perfil muestra el documento y solo el solicitante lo edita; fuera `role_selector.dart`, `register_role_tabs.dart` y `register_role_section.dart` |

**El arreglo del prefijo `57` era más amplio de lo que decía el plan:**
`AuthContact.parse` también lo usan el login y la recuperación de contraseña,
así que las tres pantallas devolvían 400 con `+57 300 123 4567`.

**El OTP va al celular.** `register_screen` manda
`AuthContact.phone(phone)` al `/verify-otp`, porque el celular es el único
contacto obligatorio y `roles.md` dice "OTP al celular". Antes prefería el
correo.

**Fuera de alcance, para más adelante:** `dispatcher_cards.dart` sigue con
`hub?.isApproved` y `HubStatus` con los tres valores viejos; eso es de la
Fase 4. Los 12 widgets sobre 60 líneas siguen pendientes de la Fase 9.
`local_auth_repository.dart` quedó en 240 líneas y es candidato a otra
partición.

**Verificación:** `flutter analyze` sin issues y `flutter test` con **49
pruebas** (subieron de 36). Las 13 nuevas cubren el enum de documento, el
`hubIds` que puede faltar, el registro sin `role`, el prefijo `57` en
validación y en `AuthContact.parse`, y las reglas de documento del
repositorio local.

**Pendiente de esta fase:** validar contra Nest con el backend arriba.
`flutter run` no se probó en esta sesión. **Quedó cerrado** en la sesión de la
Fase 4: los 9 endpoints de `/auth` respondieron como espera el contrato.

### Fase 4 — Centrales ✅

Cerrada el 2 de octubre de 2026, en `feature/redisign-auth`, en tres bloques.
**No se tocó `backend/`.** El admin crea y suspende; el despachador consulta
la suya. Es la base de las Fases 5, 6 y 7 porque las tres leen la central
asignada.

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | Modelo `Hub` | Reemplaza `HubSummary`. `HubType` (5 valores), `HubStatus` solo `active`/`suspended`, `isActive`, `latitude`/`longitude` como `double`, `address`, `contactPhone`, `contactEmail`, `createdAt`. Fuera `rejectionReason` |
| b | `HubRepository` | Cuatro métodos: `mine()`, `list({status})`, `create(dto)`, `setSuspension(id, {suspended})` |
| c | `RemoteHubRepository` | Los cuatro contra Nest. **Solo `mine()` convierte 404 en `null`**; los demás relanzan |
| d | `LocalHubRepository` | Fixture `Central Demo`, `aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa`, `active`, hospital, `3001234567`, `10.463140` / `-73.253220`. Reusa `localFixtureHubId` |
| e | Providers | Listado con `FutureProvider`, `myHubProvider` a `Hub?`, y un `AsyncNotifier` por mutación. Tras suspender: `ref.invalidate` del listado **y de `myHubProvider`** |
| f | `hub_form_screen` | `AppTextField` + `PrimaryButton`, tipo en `DropdownButtonFormField`, latitud y longitud en dos campos numéricos |
| g | `hubs_screen` | Lista con nombre, tipo, estado y teléfono. Filtro Activas / Suspendidas / Todas. Botón Suspender o Activar según el estado, **nunca la acción repetida** (el API daría 409), con confirmación |
| h | `hub_detail_screen` | Solo lectura, para el `/hubs/me` del despachador: nombre, tipo, dirección, teléfono, correo, estado, coordenadas. Si `mine()` es null: "No tienes una central asignada." |
| i | Rutas | `/hubs`, `/hubs/new` (admin), `/hubs/me` (despachador). Otro rol a `/unauthorized` |
| j | Homes | `admin_home` navega a `/hubs` y `/users`; `dispatcher_cards` navega a `/hubs/me` |

| Bloque | Qué quedó |
| --- | --- |
| Modelo | `Hub` completo con `HubType` de 5 valores, `HubStatus` `active`/`suspended`, lat/lng `double` y `CreateHubRequest`; fuera `HubSummary`, `rejectionReason` y `isApproved` |
| Datos | `HubRepository` con los cuatro métodos; el remoto solo convierte 404 en `null` en `mine()`; el local replica el 409 de Nest ("Esta central ya está suspendida.") |
| Providers | `hubsProvider` con filtro `hubFilterProvider` (`Notifier<HubStatus?>`, porque `StateProvider` quedó en `legacy` de Riverpod 3), `myHubProvider` a `Hub?`, y un `AsyncNotifier` por mutación que invalida listado **y** `myHubProvider` |
| Pantallas | `hub_form_screen` (alta con `HubFormValues`, que agrupa los seis controladores), `hubs_screen` (filtro + confirmación antes de suspender) y `hub_detail_screen` (solo lectura) |
| Rutas | `/hubs`, `/hubs/new` (admin) y `/hubs/me` (despachador) con guardia por rol en el `redirect` → otro rol cae en `/unauthorized` |
| Copy | `hub_labels.dart` compartido por lista, formulario y detalle; `app_snack.dart` en `core/widgets` para el resultado de las mutaciones |

**Fuera de alcance:** el paso j dijo `admin_home` a `/users`, pero esa ruta
es de la Fase 5, así que "Cuentas institucionales" sigue en
`showModulePreview` hasta que exista `users_screen`.

**Verificación:** `flutter analyze` sin issues y `flutter test` con **50
pruebas**. Ningún widget nuevo pasa de 60 líneas (`home_shell.dart`, en 63,
es de la Fase 1 y queda para la Fase 9).

**Validación contra Nest con el backend arriba (cerrada el 2 de octubre):**

| Qué se probó | Resultado |
| --- | --- |
| `POST /hubs` central en Valledupar (10.46 / -73.25) | Nace `active`, con tipo, dirección, teléfono y correo |
| `PATCH /hubs/:id/suspension` con `suspended: true` | → `suspended` |
| Repetir la misma suspensión | → `409 "Esta central ya está activa."` |
| `PATCH` con `suspended: false` | Vuelve a `active` |
| `GET /hubs?status=` (sin filtro, `active`, `suspended`) | Conteos correctos, incluye la central nueva |
| `POST /hubs` con `latitude: 999` | → `400 "La latitud no es válida."` |
| `GET /hubs/me` como admin | → `403` (la ruta del front tiene guard de rol) |
| `GET /hubs/me` como despachador con central | → `200` con nombre y estado; al suspender, responde `suspended` |
| Credenciales inválidas | → `401 "Correo o celular y contraseña no coinciden."` |

**Bug encontrado y corregido en esta validación:** `defaultBaseUrl` usaba
`Platform.isAndroid`, que en compilación web lanza `Unsupported operation:
Platform._operatingSystem` y la app no arrancaba en Chrome/Edge (los únicos
dispositivos disponibles en la máquina, aparte de Windows). Se decide con
`kIsWeb` antes de tocar `Platform`.

`flutter run` quedó probado en Chrome: la app compila, arranca y no vuelve a
lanzar `Platform._operatingSystem`. La recorrida manual de la UI en el
navegador no se completó en esta sesión; la cubren las 50 pruebas de widget.

### Fase 5 — Cuentas

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | Feature `users` completa | `user_models.dart`, `user_repository.dart`, `remote_user_repository.dart`, `local_user_repository.dart`, `user_providers.dart`. Reusa `PublicUser` de auth |
| b | `users_screen` | Lista de `GET /users`. Muestra nombre, correo, rol y estado. Filtros opcionales de rol y estado. **No muestra solicitantes**: el API no los lista |
| c | `user_form_screen` | Nombre, correo, celular opcional, contraseña, rol |
| d | `hub_multi_select` | Si el rol es despachador: un solo `Dropdown` de centrales `active` → `hubIds: [id]`. Si es operador: selección múltiple, mínimo una |
| e | Suspender / reactivar | `PATCH { "suspended": bool }` con confirmación. No ofrece suspender la propia cuenta |
| f | Rutas | `/users`, `/users/new` |

**Valida:** crear un despachador con una central y un operador con esa misma.
Ambos entran **sin OTP**. Suspender la central y tratar de asignarla a uno nuevo
→ "Solo puedes asignar centrales activas."

### Fase 5 — Cuentas ✅

Cerrada el 3 de octubre de 2026, en `feature/cuentas-fase5`. **No se tocó
`backend/`.** `flutter analyze` sin issues y `flutter test` con **50 pruebas**.
Ningún widget nuevo pasa de 60 líneas (medido clase por clase).

Feature `users` completa (modelos, contrato, remoto, local y providers),
`users_screen` con filtros de rol y estado, `user_form_screen` con
`hub_multi_select` (dropdown único para despachador, chips para operador),
rutas `/users` y `/users/new` con guard de admin, y la tarjeta del
`admin_home` dejó de usar `showModulePreview`. La fila oculta el botón en la
cuenta propia (Nest da 403).

**Validación contra Nest con el backend arriba (3 de octubre):**

| Qué se probó | Resultado |
| --- | --- |
| `POST /users` despachador con 1 central y operador con la misma | ambos `active` con el mismo `hubIds` |
| Login de los dos nuevos | entran **sin OTP** |
| `PATCH /users/:id/suspension` + repetirlo | `suspended` → `409 "Esta cuenta ya está suspendida."` |
| `PATCH` con `suspended: false` | vuelve a `active` |
| Suspender la cuenta propia | `403` |
| Alta con central suspendida | `400 "Solo puedes asignar centrales activas."` |
| Alta con `role: requester` | `400 "El rol debe ser despachador u operador de flota."` |
| `GET /users?role=&status=` | filtros correctos; `role=requester` → `400` (el front no lo envía) |
| `GET /users` sin filtro | solo institucionales, nunca solicitantes |

**Inventario de UI para el rediseño:** `frontend/tools/ui_inventory.ps1`
genera `frontend/docs/ui_inventory.md` con pantalla/widget por feature y el
tamaño de cada clase, marcando las que pasan de 60 líneas. Correrlo después
de cada fase que agregue o borre UI.

**Nota:** el formulario solo lista centrales `active`, así que una central
suspendida no aparece en el selector; el mensaje de Nest se vería si la
suspensión ocurre con el formulario ya abierto.

### Fase 6 — Inventario

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | Feature `inventory` | `SaleType` (`over_the_counter`, `prescription`, `special_control`) y el ítem con `lot` y `saleType`. **No** lleva `hubId` en el body: la central sale de la asignación del despachador |
| b | Repositorio | Los cuatro: listar, crear, editar, borrar. `DELETE` usa `ApiClient.delete`, sin parsear cuerpo (204) |
| c | `inventory_screen` | Nombre, lote, cantidad, vencimiento, tipo de venta y una marca si `requiresColdChain` |
| d | `inventory_form_screen` | Alta y edición con los campos del DTO. **Si el PATCH no cambia nada, no lo envías** (el API responde 400) |
| e | Gate en el home | La tarjeta navega solo si `hub.isActive`. Suspendida → "La central está suspendida." y `onTap: null`. Sin central → "No tienes una central asignada." |
| f | Invalidación | Tras suspender una central, el inventario se invalida para que el despachador vea la tarjeta apagada sin reiniciar |
| g | Rutas | `/inventory`, `/inventory/new`, `/inventory/:id` |
| h | Tests | Home del despachador deshabilita con `suspended` y habilita con `active`. Fuera los asserts de "Pendiente de aprobación" y "Aprobada" |

**Nota:** el control especial **se puede guardar**. El pedido de control especial
no existe todavía, así que no se bloquea el alta del ítem.

### Fase 7 — Flota

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | Feature `fleet` | `DroneModel` (id, code, name, velocidad, carga, alcance), `Drone`, `DroneStatus` con los 4 valores |
| b | `fleet_screen` | Primero `GET /hubs` (sus centrales). Si está vacío: "No tienes centrales asignadas." Elige una y lista `GET /fleet/drones?hubId=` |
| c | `drone_form_screen` | Alta deshabilitada si la central está suspendida, con "La central está suspendida." El modelo sale de `GET /fleet/models` (mostrar `name`, guardar `id`). Identificador máximo 32 |
| d | `drone_tile` | Identificador, estado, motivo y fecha si vienen. Si `in_mission`: **no** muestra cambiar estado ni mantenimiento (el API da 409) |
| e | `drone_status_sheet` | Disponible → `PATCH {status: available}`. En mantenimiento → `PATCH` con motivo y fecha opcionales. **"Registrar mantenimiento" → `POST .../maintenance`** (motivo y fecha obligatorios, queda `out_of_service`). Una sola vía por botón, nunca las dos |
| f | Rutas | `/fleet`, `/fleet/new` |

**Valida:** crear `DRON-01` con Wingcopter 198, pasarlo a mantenimiento,
registrar mantenimiento → queda Fuera de servicio con motivo y fecha.

### Fase 8 — Geovallas

Único módulo cuyo backend nunca cambió: se puede hacer en cualquier momento. No
va por central, no usa `hubId`, y cualquier operador activo ve todas.

| Paso | Qué | Detalle |
| --- | --- | --- |
| a | Feature `geofences` | `GeoJsonPolygon` con el anillo exterior en `coordinates[0]`, cada punto `[longitud, latitud]`. No usa `hubId` |
| b | `geofences_screen` | Lista con nombre y motivo. Borrar con confirmación |
| c | `geofence_form_screen` | Nombre, motivo y al menos 3 vértices longitud/latitud |
| d | `polygon_point_fields` | El **cliente cierra el anillo**: si cargó 3 vértices distintos, copia el primero al final. Al editar muestra los puntos sin repetir el cierre y lo vuelve a armar al guardar |
| e | Rutas | `/geofences`, `/geofences/new`, `/geofences/:id` para `fleet_operator`; otro rol cae en `/unauthorized` |
| f | Home | Sustituye el `showModulePreview` de la tarjeta del operador |
| g | Delete | Usa `ApiClient.delete` y no parsea cuerpo (204) |

**Sin mapa:** no se agrega paquete de mapas. El mapa en vivo pertenece a
telemetría, que no existe.

**Valida:** con una cuenta de operador, crear una geovalla de 3 vértices,
editar el nombre y borrar.

### Fase 9 — Cierre

| Paso | Qué |
| --- | --- |
| a | Recorrido manual de los 4 roles contra Nest en el puerto 3000, con `DataSource.remote` |
| b | Borrar `module_preview.dart` si ya no tiene usos |
| c | Decidir qué hacer con los 12 widgets que siguen sobre las 60 líneas |
| d | `flutter analyze` y `flutter test` finales; este archivo y los punteros en los `AGENTS.md` se eliminan al cerrar |

---

## 4. Decisiones firmes (no reabrir)

- Riverpod 3 es el **único** gestor de estado. El JWT vive solo en `FlutterSecureStorage` vía `TokenStore`.
- HTTP: `defaultBaseUrl` en `lib/core/network/api_client.dart`, `http://localhost:3000` (emulador Android: `http://10.0.2.2:3000`), **sin** prefijo `/api`.
- Tema único en `lib/theme/` (tokens Stitch: cyan `#06B6D4`, `themeMode: ThemeMode.system`, `google_fonts` ^8.2.1). Colores solo con `Theme.of(context)`.
- Widgets de UI de **máximo 60 líneas**; los repositorios no importan Riverpod ni `TokenStore`, salvo el local.
- Validar siempre con `Validators` + `FieldLimits`. El celular se limpia de símbolos igual que Nest, y se le quita el prefijo `57` si sobra.
- La UI muestra el `message` de `ApiException`; no se reemplaza por un texto genérico cuando el backend ya lo define.
- No se agregan paquetes de mapas: la geovalla es un formulario de vértices en este incremento.
- Identificadores en inglés, copys en español de Colombia, sin commitear `learning/`.
- Rama `feature/…` por fase desde `develop`. Nunca se commitea en `develop`; si hay trabajo sin commitear, va con `git stash push` + `git stash pop` a la rama nueva.
- El agente no hace `commit`, `push` ni PR.

## 5. Fuera de alcance

Pedidos, autorización, carga, vuelo, código de entrega, telemetría, WebSocket, métricas, mapa, creación de modelos de dron desde la app, flujo de aprobar o rechazar centrales, autoregistro de despachador u operador, y cualquier endpoint que no esté en la sección 2.

## 6. Protocolo de sesión

1. Al iniciar, trabajar **solo** la primera fase sin ✅. Leer `lib/core`, `lib/theme` y `lib/app` antes de escribir código.
2. Explicar cada paso y esperar la confirmación del usuario antes de ejecutarlo.
3. Al terminar: marcar ✅ aquí con 1–3 líneas de lo que quedó, y en qué estado quedó el bloqueo de backend. El agente guía; el usuario hace `commit`, `push` y PR.