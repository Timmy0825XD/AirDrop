<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# AGENTS.md — web (radar en tiempo real)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md).

## Qué es

Una sola página, solo lectura, para el **administrador**: un mapa tipo Flightradar con las centrales, los drones en vuelo y, al elegir uno, su ruta; un panel lateral con el detalle de la central o del vuelo. Next.js (App Router) y Tailwind. Cómo correrlo y cómo está armado: [`README.md`](README.md).

## Reglas

- **Solo lectura.** No crea ni cambia pedidos, centrales ni flota; eso es de la app Flutter. Si hace falta una acción, no entra aquí.
- **Solo el administrador.** El backend lo exige (`/radar/*` y la sala `radar` del socket); la web solo muestra el error.
- **Un solo canal en tiempo real:** el WebSocket `/telemetry` de Nest. Nada de polling rápido ni de un segundo socket. Los paneles recargan por REST cada pocos segundos, y eso es todo.
- **El contrato vive en el backend** (`backend/src/radar`). Los tipos de `src/lib/types.ts` lo reflejan; si el backend cambia, se ajustan en el mismo PR.
- **Privacidad:** nada que identifique a una persona (nombre, documento, dirección, fórmula) ni el medicamento de una entrega a una persona. El backend ya no lo manda; no lo pidas.
- **Textos en español de Colombia.** Los códigos de Nest se traducen en `src/lib/labels.ts`; los mensajes de error de Nest se muestran tal cual.
- **Un solo mapa** (`components/map/RadarMap.tsx`) y **un solo bucle de animación** (`use-drone-tracks.ts`). Los drones se mueven sin pasar por React.
- **Modo demostración** (`?demo=1`) siempre rotulado en pantalla. Nunca se mezcla con datos reales.
- Colores desde los tokens de `globals.css` (y `src/lib/theme.ts` para el mapa); no hexadecimales sueltos en componentes.
- `pnpm lint` y `pnpm build` en verde antes de un PR. El agente no hace commit, push ni PR.
