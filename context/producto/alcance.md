# Alcance y limitaciones (MVP)

## Entorno geográfico

- **MVP:** ciudad de **Valledupar** más uno o dos municipios o corregimientos cercanos (distancia media).
- **Visión posterior:** varias ciudades, cada una con una o más centrales y uno o más drones. Eso se **reserva en el modelo de datos** si es barato (p. ej. `hub` con ubicación), pero **no** se entrega como producto multi-ciudad.

## Incluido en el MVP

- Pedidos de **emergencia** (prioridad alta) y **programados** (fecha, frecuencia, cantidad: sangre, vacunas, otros).
- Entrega según [`../entregas/`](../entregas/) y el mínimo legal de [`../legal/`](../legal/).
- Flota de drones simulados con estados de disponibilidad.
- Geovallas y zonas restringidas definidas por el operador.
- Motor de decisión **al autorizar**: elige el mejor dron (batería, carga, mantenimiento, clima **simulado**, ruta libre de geovallas, tipo de misión); emergencia gana el recurso si hay competencia. **No** asume que el insumo ya está a bordo ni inicia el vuelo.
- El despachador ve la **referencia del dron asignado**, coloca el insumo y **marca la carga**. Solo entonces arranca la simulación.
- Rutas simuladas que evitan zonas restringidas y “edificaciones” vía **corredores a altitud fija** (no navegación 3D).
- Telemetría en tiempo real en la app.
- Panel de operador: posición, altitud, velocidad, batería, payload, temperatura de carga, ping/latencia, fase de vuelo.
- En destino: el dron **espera 5 minutos** el código de entrega. Si no se ingresa, **regresa a la central con el paquete**. El reingreso al inventario pasa por la cuarentena de [`../entregas/productos.md`](../entregas/productos.md).
- Cadena de frío simulada y alerta si la temperatura sale de rango.
- Fallback: alternativa de entrega si ningún dron es elegible al autorizar.
- Dashboard epidemiológico simple: qué se pide más y desde dónde.

## Limitaciones explícitas

| Limitación | Implicación |
| --- | --- |
| Dron 100 % simulado | Sin hardware ni API de fabricante |
| Clima simulado | Sin OpenWeather ni equivalente |
| Sin 3D de terreno | Geovallas + altitud fija, como operadores reales de delivery |
| Geografía acotada | Multi-ciudad no desplegada |
| Inventario manual | El despachador carga stock; no hay HIS/hospital |
| No es atención médica | Complementa el **insumo**, no el traslado ni la atención del paciente |

Cualquier issue o PR que viole esta tabla debe rechazarse salvo que se actualice este documento de forma consciente (fuera del alcance de aula actual).
