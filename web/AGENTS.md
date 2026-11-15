<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# AGENTS.md — web (radar y consola de simulación)

Reglas de esta carpeta. Autoridad de negocio: [`../INDEX.md`](../INDEX.md) y [`../context/`](../context/). No contradecir [`../AGENTS.md`](../AGENTS.md).

## Qué es

Una sola página para el **administrador**, pensada para verse en una TV. Tiene dos partes:

- **Radar:** un mapa tipo Flightradar con la red regional: los nodos (con drones) y las ESE (solo reciben), los puntos de entrega (RF-45), las zonas legales (RF-43: el anillo del aeropuerto, el casco urbano, prohibidas, coordinadas y de precaución), los drones en vuelo y, al elegir uno, su ruta. Un panel lateral muestra el detalle de lo elegido: central, vuelo, zona legal (con su norma y su fuente) o punto de entrega.
- **Consola de simulación** (RU-32, RF-31 a RF-40): reloj simulado (pausa, x1, x2, x4, x8), eventos sobre el mapa (clima, fallas, choques, entorno), interruptores de despachador automático y de modo caos, línea de tiempo, alertas pendientes y reinicio del escenario.

Todo en la misma pantalla, con paneles plegables. Next.js (App Router) y Tailwind. Cómo correrlo y cómo está armado: [`README.md`](README.md).

## Reglas

- **Lee el sistema, y solo manda órdenes de la consola.** Las órdenes van por REST a `/control/*`: reloj, eventos, actores simulados, caos y reinicio. No crea ni edita a mano pedidos, centrales, inventario ni flota; eso es de la app Flutter. La única orden fuera de `/control/*` es activar o desactivar un punto de entrega (`PATCH /delivery-points/:id`, RF-45): es un interruptor como el apagón de una central, no un formulario. Los pedidos que aparecen por la consola los crean los actores simulados del backend, con los mismos servicios que usa una persona (RF-37).
- **Solo el administrador.** El backend lo exige (`/radar/*`, `/control/*` y la sala `radar` del socket) y apaga `/control/*` si `CONTROL_ENABLED` no está encendido. La web solo muestra el error.
- **Un solo canal en tiempo real:** el WebSocket `/telemetry` de Nest. Por ahí llegan la telemetría, la hora simulada, la línea de tiempo y las alertas. Nada de polling rápido ni de un segundo socket. Los paneles recargan por REST cada pocos segundos, y eso es todo.
- **La hora es la del reloj simulado** que publica el backend, no la del navegador. Cuentas regresivas, ETA y la línea de tiempo usan esa hora.
- **El contrato vive en el backend** (`backend/src/radar` y `backend/src/control`). Los tipos de `src/lib/types.ts` lo reflejan; si el backend cambia, se ajustan en el mismo PR.
- **Privacidad:** nada que identifique a una persona (nombre, documento, dirección, fórmula) ni el medicamento de una entrega a una persona. El backend ya no lo manda; no lo pidas. Los solicitantes simulados tampoco se presentan como personas reales.
- **Textos en español de Colombia.** Los códigos de Nest se traducen en `src/lib/labels.ts`; los mensajes de error de Nest se muestran tal cual.
- **Un solo mapa** (`components/map/RadarMap.tsx`) y **un solo bucle de animación** (`use-drone-tracks.ts`). Los drones se mueven sin pasar por React. Las capas nuevas (clima, geovallas temporales, incidentes, rutas cambiadas) van en ese mismo mapa.
- **La red regional:** las zonas legales llegan en `snapshot.airspace` y no cambian en ejecución (`useRadar` las conserva). Los puntos de entrega no llegan por el socket: `useDeliveryPoints` (`lib/use-region.ts`) los lee al abrir, al reiniciar el escenario y después de cambiar uno. El orden de las capas es zonas legales → geovallas → clima → rutas → puntos → drones. El mapa encuadra la red entera (centrales y puntos), no la ciudad.
- **Legible en una TV:** letra y controles grandes, contraste alto y nada que dependa de pasar el mouse por encima.
- **Modo demostración** (`?demo=1`) siempre rotulado en pantalla. Nunca se mezcla con datos reales. Allí la consola no manda órdenes al backend.
- Colores desde los tokens de `globals.css` (y `src/lib/theme.ts` para el mapa); no hexadecimales sueltos en componentes.
- `pnpm lint` y `pnpm build` en verde antes de un PR. El agente no hace commit, push ni PR.
