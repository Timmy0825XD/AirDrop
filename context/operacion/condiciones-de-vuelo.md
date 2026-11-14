# Condiciones de vuelo

Cuándo y a qué altura vuela un dron. Las reglas de dónde puede volar están en [espacio-aereo.md](espacio-aereo.md); los tipos de dron, en [flota.md](flota.md).

## Solo de día

El RAC 100.220(a)(3) dice: "No se autorizarán, en ningún caso, operaciones nocturnas para actividades de transporte de carga (Drone Delivery)".

- El RAC 100 no define la noche. Lo usual en aviación es tomarla desde el fin del crepúsculo civil vespertino hasta el inicio del matutino. AirDrop usa una ventana más estricta, **de la salida a la puesta del sol**, para que el despacho nunca dependa de la penumbra.
- La salida y la puesta se calculan para la fecha simulada y la coordenada del nodo, con las ecuaciones solares de la NOAA. No usan una API. En el Cesar, la salida varía entre las 5:40 y las 6:20 y la puesta entre las 17:40 y las 18:20, según la época.
- Un vuelo solo se despacha si el dron puede **aterrizar de regreso en el nodo antes de la puesta del sol**, con el tiempo estimado de ida, la espera en destino y la vuelta.

**Pedidos que caen de noche:**

| Pedido | Qué hace el sistema |
| --- | --- |
| Programado | Queda en cola y sale en la primera franja con luz del día |
| Urgencia | No se encola: se marca **"requiere alternativa terrestre"** (el fallback existente) y se avisa al despachador y al operador. Si la luz del día llega antes de que se resuelva por tierra, el despachador puede reactivarlo |

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

- Altura de crucero objetivo: **90 m sobre el terreno** (AGL).
- Techo: **120 m AGL**. Queda por debajo de los 122 m (400 ft) del RAC 100, con margen.
- Piso: 60 m AGL. Si el terreno sube más rápido de lo que el dron puede ascender, el dron baja su velocidad horizontal. Nunca baja del piso.

**Malla de elevación.** El terreno sale de una malla precalculada de la región, hecha con el modelo de elevación **SRTM** de la NASA (de acceso libre):

- Una celda mide unos 500 m de lado y guarda la **altura máxima** del terreno dentro de ella, para no subestimar un cerro entre dos muestras.
- La malla es un archivo JSON del backend. Se genera una sola vez con un script y no se consulta en línea.
- La ruta se muestrea cada **250 m**. En cada muestra, la altura de vuelo (sobre el nivel del mar) es la del terreno más 90 m.

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

1. Despegue vertical en el nodo hasta 90 m AGL.
2. Transición a crucero.
3. Crucero por el corredor, siguiendo el terreno.
4. Descenso vertical sobre el punto de entrega. Es un punto a la vista de su observador y a 30 m de personas ajenas ([../entregas/persona.md](../entregas/persona.md)).
5. Entrega o espera del código.
6. Regreso al nodo por el mismo corredor.
