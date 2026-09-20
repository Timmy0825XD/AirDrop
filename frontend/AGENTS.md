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
