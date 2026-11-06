# Arquitectura tecnológica

Dirección acordada en el documento base. El detalle de carpetas y convenciones está en los `AGENTS.md`; aquí está el **porqué** de cada pieza.

## 1. Aplicación móvil

- **Flutter**, una sola app para Android e iOS.
- Roles: solicitante (registro público), despachador y operador de flota (los crea el admin) y administrador. La central no es un rol. No hay rol receptor. Detalle en [`../app/roles.md`](../app/roles.md).
- Mapas, geovallas y telemetría de los roles van en la misma app.
- **Una sola web:** `web/` (Next.js), solo para el administrador. Es el radar en tiempo real y la consola de simulación que se proyecta en una TV (RU-32). Usa el mismo REST y el mismo WebSocket que la app.

## 2. Backend y lógica de negocio

- **NestJS**, organización **modular por dominio** (flota, pedidos, despacho, rutas, geovallas, telemetría, etc.).
- Un solo proceso / un solo deploy en el MVP.
- Aquí viven las reglas del motor de decisión.

## 3. Base de datos

- **PostgreSQL + PostGIS:** geovallas, distancias, “¿la ruta cruza zona restringida?”.
- El planificador de corredores vive en `routing/`: `routing.rules.ts` (corredor de ida, regreso y cruces) y `visibility.rules.ts` (proyección a km, geovallas infladas con el margen y A*). PostGIS guarda los polígonos y las rutas; el cálculo es TypeScript puro para probarlo sin base de datos.
- Persiste: pedidos, historial de misiones, inventario, geovallas, usuarios, configuración.
- La imagen de la fórmula no va en la fila del pedido. Va a un bucket privado de Supabase Storage. Postgres guarda la clave. La sigue viendo solo el despachador que autoriza (RNF-06).

## 4. Estado en vivo

- **Redis:** posición, batería, velocidad (y el resto del snapshot) **durante** la misión.
- Pub/sub hacia el gateway para no martillar Postgres cada 2 segundos.
- Estado del reloj simulado y las últimas entradas de la línea de tiempo (RF-31, RF-39).

## 5. Tiempo real

- **WebSockets** (gateway NestJS): telemetría y estado de pedido.
- La app reconecta sola (RNF-12) y muestra último estado conocido.

## 6. Motor de simulación

- Un **reloj** en el backend (intervalo configurable, techo 2 s reales en vuelo).
- La hora la da `simClock` (`common/clock/`, RF-31): pausa, x1, x2, x4 o x8. Cada tick avanza el tiempo simulado que toque. JWT, OTP y login siguen en hora real.
- Cada tick: avanza el dron en la ruta, recalcula batería según **fase** (vertical vs ala fija).
- Specs desde `DroneModel` (Wingcopter 198), independientes de cada unidad de flota.
- La cuenta de batería vive en `simulation/flight-energy.rules.ts`. El reloj la usa para gastar en cada tick y el motor de decisión para saber si el vuelo alcanza (RF-11).
- Cada dron guarda la batería con que aterrizó y cuándo; la recarga en tierra se calcula al leerla (`batteryNow`), sin un reloj aparte.
- El reloj **no** arranca cuando el despachador autoriza. Autorizar dispara el motor de decisión (reserva dron + ruta). El tick de vuelo empieza cuando el despachador **confirma la carga**.
- En el punto de destino el reloj pasa a una fase de **espera** (5 min). Código válido → cierra misión. Sin código → simula el **retorno** a la central con el paquete.
- Emergencia: asignación al autorizar; el dron queda reservado hasta la carga o el fallback.
- Programado: calendario, posibilidad de agrupar entregas si el payload alcanza (sin convertir esto en un VRP académico; heurística simple).
- Si una zona nueva (geovalla, geovalla temporal, tormenta) cruza el tramo que falta, la ruta cambia en vuelo (RF-33).
- Ante un incidente, `contingency.rules.ts` elige el protocolo y el reloj lo ejecuta (RF-34). Una urgencia que no llega vuelve al motor de decisión (RF-35).

## 7. Cadena de frío

- Sensor de temperatura **simulado** en el mismo loop de telemetría, solo si el ítem lo requiere.
- Fuera de rango → alerta al operador (y registro de incidencia).

## 8. Consola de simulación

- Módulo `control/` en Nest y la web `web/`. Solo admin, y solo con `CONTROL_ENABLED`.
- Clima simulado por celdas en `weather/` (RF-32). Lo leen la decisión, las rutas y el vuelo.
- Actores simulados (despachador automático, generador, receptor) que llaman a los mismos servicios que una persona (RF-37). Modo caos apagado por defecto (RF-38).
- La línea de tiempo y las alertas pendientes van por la sala `radar` del mismo socket (RF-39).

## 9. Dashboard epidemiológico

- Agregaciones SQL sobre pedidos ya guardados.
- Sin Metabase/Tableau en el MVP.

## Diagrama lógico

```
[Solicitante/Despachador/Operador/Admin]  Flutter
[Admin: radar + consola]                 Next.js (web/)
                      | HTTPS REST
                      | WSS telemetría / estados
                      v
                 NestJS API
            /        |         \
     Decision    Simulation    Auth/CRUD
            \        |         /
              PostgreSQL+PostGIS
                     +
                   Redis (live)
```

## Lo que no entra en “dirección tecnológica”

Kubernetes, service mesh, Kafka, GIS server aparte, motor de juego 3D, ML para rutas. Fuera de alcance y de la sustentación razonable.
