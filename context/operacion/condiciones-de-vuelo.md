# Condiciones de vuelo

Cuándo y a qué altura vuela un dron. Las reglas de dónde puede volar están en [espacio-aereo.md](espacio-aereo.md); los tipos de dron, en [flota.md](flota.md).

## A cualquier hora

Se vuela de día y de noche (RF-44). La hora del reloj simulado no descarta drones ni manda una urgencia a traslado convencional. Los programados siguen atados a su franja de 07:00 a 17:00 (RU-30), que es horario de servicio.

**Simplificación.** El RAC 100.220(a)(3) dice: "No se autorizarán, en ningún caso, operaciones nocturnas para actividades de transporte de carga (Drone Delivery)". El MVP no lo aplica para que la demo se pueda presentar a cualquier hora ([../legal/aeronautica.md](../legal/aeronautica.md)).

## Condiciones meteorológicas visuales (VMC)

El RAC 100.440 exige vuelo en VMC y monitoreo meteorológico durante toda la operación. El clima es simulado: lo crean la consola o el modo caos (RF-32). No hay datos reales.

| Celda | Efecto |
| --- | --- |
| Tormenta | Zona no volable mientras dure; el planificador la rodea |
| Niebla (visibilidad reducida) | Sin VMC: zona no volable mientras dure, igual que la tormenta |
| Lluvia | Se vuela, con un 10 % más de consumo en el crucero |
| Viento | Cambia la velocidad sobre el suelo y el consumo. Por encima del límite del tipo, no se vuela |

**Límite de viento por tipo** (sostenido / ráfaga):

| Tipo | Sostenido | Ráfaga |
| --- | --- | --- |
| Colibrí | 12 m/s | 16 m/s |
| Garza | 15 m/s | 20 m/s |
| Cóndor | 10 m/s | 14 m/s |

El multirrotor pesado (Cóndor) tolera menos viento que los de ala fija. Así es en los drones de carga reales.

## Altura y terreno

**Reglas:**

- Despega hasta **90 m sobre el terreno** (AGL), la altura de referencia.
- Techo: **120 m AGL**. Queda por debajo de los 122 m (400 ft) del RAC 100, con margen.
- Piso: **60 m AGL**. Nunca baja de ahí.
- Entre el piso y el techo, el dron **mantiene su altitud**: no baja a cada hondonada para volver a subir. Cuando el terreno lo saca de la banda, sube lo justo hasta el piso o baja lo justo hasta el techo. Es lo que gasta menos energía.
- Como no sube más rápido que su velocidad vertical, empieza a subir antes de una ladera. Si ni así alcanza sin pasar del techo, prima el piso: en la vida real frenaría para subir.

**Malla de elevación.** El terreno sale de una malla precalculada de la región, hecha con el modelo de elevación **SRTM** de la NASA (de acceso libre), tomado de los mosaicos *Terrain Tiles* de AWS (zoom 12, unos 35 m por píxel):

- Una celda mide unos 500 m de lado y guarda la **altura máxima** del terreno dentro de ella, para no subestimar un cerro entre dos muestras.
- La malla es un archivo JSON del backend (`terrain-grid.json`). Se genera una sola vez con `scripts/build-terrain-grid.py` y no se consulta en línea.
- La ruta se muestrea cada **250 m** y en cada muestra se aplican las reglas de arriba.

**Ascenso por tipo:**

| Tipo | Velocidad vertical máxima | Masa máxima al despegue | Energía de batería |
| --- | --- | --- | --- |
| Colibrí | 5 m/s | 9 kg | 900 Wh |
| Garza | 4 m/s | 18 kg | 1.500 Wh |
| Cóndor | 3 m/s | 45 kg | 2.000 Wh |

**Energía de subida.** Cada metro de ascenso neto cuesta la energía potencial que gana el dron, con una eficiencia del 50 %:

> energía (Wh) = masa × 9,81 × metros de ascenso / 3.600 / 0,5

Sale aproximadamente en 0,55 % de batería cada 100 m en el Colibrí, 0,65 % en el Garza y 1,2 % en el Cóndor. Bajar no devuelve energía; es la cuenta conservadora.

**Techo de servicio.** Si el punto más alto de la ruta más 90 m supera el techo del tipo ([flota.md](flota.md)), ese tipo se descarta.

**Lo que se ve.** El radar y el seguimiento muestran la altura sobre el terreno y sobre el nivel del mar. La web puede dibujar el perfil vertical de la ruta.

## Misión típica

1. Despegue vertical en la central hasta 90 m AGL.
2. Transición a crucero.
3. Crucero por el corredor, siguiendo el terreno.
4. Descenso vertical sobre el destino: la ubicación del solicitante o la central ([../entregas/persona.md](../entregas/persona.md)).
5. Entrega o espera del código.
6. Regreso a la central por el mismo corredor.
