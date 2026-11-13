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
- **Consola de simulación** en la web del administrador, proyectada en una TV (RU-32). Sirve para demostrar que el sistema responde bien ante situaciones realistas:
  - Reloj simulado único para todo el sistema, también para la app: pausa, x1, x2, x4 y x8 (RF-31).
  - Clima simulado por zonas (viento, lluvia, tormenta) que el motor de decisión, las rutas y el vuelo sí tienen en cuenta (RF-32).
  - Cambio de ruta en pleno vuelo cuando una zona nueva cruza el tramo que falta (RF-33).
  - Incidentes en vuelo (fallas, choques) con protocolos autónomos: seguir, cambiar de ruta, volver a la central o aterrizar de emergencia; una urgencia abortada se vuelve a despachar (RF-34, RF-35).
  - Eventos de entorno: geovalla temporal, central sin energía, pico de urgencias, nadie retira el paquete (RF-36).
  - Actores simulados (despachador automático, generador de pedidos, receptor) para una demo híbrida con personas reales usando la app (RF-37).
  - Modo caos realista, apagado por defecto (RF-38), línea de tiempo con alertas pendientes (RF-39) y reinicio del escenario (RF-40).
- **Solicitud de urgencia en 3 pasos:** tamizaje con signos de alarma y 123 (RF-41), paciente a cargo (RF-42), fórmula en PDF o hasta 3 fotos con visor y consulta desde el histórico (RF-27), y ubicación por GPS (RU-02).

## Limitaciones explícitas

| Limitación | Implicación |
| --- | --- |
| Dron 100 % simulado | Sin hardware ni API de fabricante |
| Clima simulado | Sin OpenWeather ni equivalente. El clima lo crean la consola o el modo caos |
| Incidentes simulados | Sin física de choques ni aerodinámica: cada incidente tiene un efecto simple y nombrado (más consumo, menos velocidad, protocolo) |
| Consola, no gestión | La web no reemplaza la app: no tiene formularios de pedidos, inventario, centrales ni flota |
| Sin 3D de terreno | Geovallas + altitud fija, como operadores reales de delivery |
| Geografía acotada | Multi-ciudad no desplegada |
| Inventario manual | El despachador carga stock; no hay HIS/hospital |
| No es atención médica | Complementa el **insumo**, no el traslado ni la atención del paciente |

Cualquier issue o PR que viole esta tabla debe rechazarse salvo que se actualice este documento de forma consciente (fuera del alcance de aula actual).
