# Arquitectura tecnológica

Dirección acordada en el documento base. El detalle de carpetas y convenciones está en los `AGENTS.md`; aquí está el **porqué** de cada pieza.

## 1. Aplicación móvil

- **Flutter**, una sola app para Android e iOS.
- Roles: solicitante, despachador, receptor, operador de flota (y administrador).
- **Sin componente web.** Mapas, geovallas y telemetría van en la misma app.

## 2. Backend y lógica de negocio

- **NestJS**, organización **modular por dominio** (flota, pedidos, despacho, rutas, geovallas, telemetría, etc.).
- Un solo proceso / un solo deploy en el MVP.
- Aquí viven las reglas del motor de decisión.

## 3. Base de datos

- **PostgreSQL + PostGIS:** geovallas, distancias, “¿la ruta cruza zona restringida?”.
- Persiste: pedidos, historial de misiones, inventario, geovallas, usuarios, configuración.

## 4. Estado en vivo

- **Redis:** posición, batería, velocidad (y el resto del snapshot) **durante** la misión.
- Pub/sub hacia el gateway para no martillar Postgres cada 2 segundos.

## 5. Tiempo real

- **WebSockets** (gateway NestJS): telemetría y estado de pedido.
- La app reconecta sola (RNF-12) y muestra último estado conocido.

## 6. Motor de simulación

- Un **reloj** en el backend (intervalo configurable, techo 2 s en vuelo).
- Cada tick: avanza el dron en la ruta, recalcula batería según **fase** (vertical vs ala fija).
- Specs desde `DroneModel` (Wingcopter 198), independientes de cada unidad de flota.
- Emergencia: asignación rápida, puede reservar flota al momento.
- Programado: calendario, posibilidad de agrupar entregas si el payload alcanza (sin convertir esto en un VRP académico; heurística simple).

## 7. Cadena de frío

- Sensor de temperatura **simulado** en el mismo loop de telemetría, solo si el ítem lo requiere.
- Fuera de rango → alerta al operador (y registro de incidencia).

## 8. Dashboard epidemiológico

- Agregaciones SQL sobre pedidos ya guardados.
- Sin Metabase/Tableau en el MVP.

## Diagrama lógico

```
[Solicitante/Despachador/Operador/Receptor/Admin]  Flutter
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
