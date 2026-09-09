---
name: airdrop-front-pending
description: >-
  Writes an ultra-specific Flutter implementation guide in learning/ for
  backend work that the frontend still lacks. Use when the user says Front
  Pending, front pending, guia frontend, o implementar backend en el front.
  Never edits Flutter unless the user explicitly asks to implement the front.
---

# Front Pending

Skill de **este repo**. Disparador: el usuario escribe **Front Pending** (o equivalente).

Entregable: un `.md` en `learning/` (carpeta gitignored, solo del usuario).

**No** toques `frontend/` ni ningún `.dart`. Esta skill es guía, no implementación. Si piden implementar el front en el mismo mensaje, primero la guía y espera confirmación explícita antes de editar Flutter.

**No** escribas la nota de `airdrop-learning-notes` en esta invocación: el `.md` de Front Pending ya es el entregable.

## Qué hacer

1. Analiza el **backend real** (módulos, controllers, DTOs, entidades, enums, guards, WebSockets).
2. Analiza el **frontend real** (`frontend/lib/`, features, repos, modelos, data source).
3. Diff: qué existe en API y aún no está (o está incompleto / en `local`) en Flutter.
4. Escribe una guía **paso a paso, ultra específica**, lista para implementar después sin adivinar.

Lee antes de redactar:

- `frontend/AGENTS.md`, `backend/AGENTS.md`, `AGENTS.md`
- `.cursor/rules/flutter.mdc`, `language.mdc`, `domain-model.mdc`, `data-source.mdc`
- `INDEX.md` y el `context/` del dominio que falte
- Controllers + DTOs del backend
- `frontend/lib/` (hoy puede ser casi vacío)

## Archivo de salida

`learning/YYYY-MM-DD-front-pending-<tema-corto>.md`

Fecha del día. Un tema kebab-case (ej. `auth`, `hubs-fleet`). Si cubres varios módulos, usa el más amplio (`auth-hubs-fleet`) o un archivo por dominio si el diff es enorme.

Español (Colombia). Identificadores de código en inglés, copys de UI en español.

## Contenido obligatorio de la guía

Sé concreto: rutas de archivo, nombres de clase, campos, longitudes, enums, roles, códigos HTTP. No “conectar el login”. Sí “POST `/auth/login` con body `{ email, password }` …”.

### 1. Resumen del hueco

Tabla: módulo backend → qué hay en Nest → qué hay en Flutter → estado (`falta` / `parcial` / `solo local`).

### 2. Contrato API (copiado del código, no inventado)

Por cada endpoint pendiente:

- Método, path, auth (público / JWT / rol)
- Query y body: cada campo, tipo, `MaxLength`, validaciones
- Respuesta 2xx: shape JSON (nombres reales)
- Errores relevantes (401, 403, 409, 429, mensajes si existen)
- Enums Postgres y valores exactos

Alinea modelos Dart y validaciones de formulario con `field-limits` / entidades. IDs `uuid`. Decimales como `String` o tipos que no usen `double` a ciegas si el API manda `numeric`.

### 3. Mapa a Flutter

Según `frontend/AGENTS.md`:

- Feature (`features/auth`, `hub`, `fleet`, …)
- Archivos a **crear** vs **editar** (ruta completa desde `frontend/lib/`)
- `data/` (DTO, cliente HTTP) vs `presentation/` (pantallas, un solo gestor de estado del proyecto)
- Data source: si el endpoint ya existe, el plan es pasar esa feature a `remote`; si no, no inventes API
- Widgets ≤ 60 líneas; tema en `lib/theme/`; copys en español Colombia
- JWT: almacenamiento seguro, no texto plano
- WebSocket solo telemetría / estado en vivo, con reconexión

### 4. Paso a paso de implementación

Orden de trabajo numerado, el que un humano seguiría:

1. Modelos / enums Dart
2. Cliente API / repositorio
3. Cablear `remote` en `lib/core/data` si aplica
4. Estado (mismo patrón que el resto de la app)
5. Pantallas y navegación por **rol**
6. Validaciones y mensajes de error
7. Cómo probar (qué rol, qué body, qué se debe ver)

Incluye snippets **mínimos** (un DTO, un método del repo). No dumps de pantallas enteras.

### 5. Fuera de alcance

Lista corta: no tocar backend, no inventar pantallas fuera del MVP, no implementar en esta invocación.

## Qué no hacer

- Editar `frontend/` o `backend/` “para adelantar”.
- Inventar endpoints, campos o roles que no estén en el código o en `context/`.
- Guía vaga (“haz el CRUD de hubs”).
- Commitear `learning/` (está en `.gitignore`).
- Commit / push / PR (el usuario lo hace a mano).
