# Flota

AirDrop usa tres tipos de dron propios, pensados para escenarios distintos. Son modelos de la simulación, no productos comerciales. Sus cifras están dentro de los rangos públicos de los drones médicos VTOL (despegue vertical y crucero en ala fija) y de carga pesada. La app y la web muestran el nombre del tipo, nunca un fabricante.

## Los tres tipos

| Código | Nombre | Carga útil | Crucero | Alcance | Techo de servicio (MSL) | Para qué |
| --- | --- | --- | --- | --- | --- | --- |
| `RAPID` | **Colibrí** | 2 kg | 140 km/h | 120 km | 3.500 m | Urgencias: antiveneno, insulina, adrenalina. Llega más lejos y antes |
| `BALANCED` | **Garza** | 5 kg | 110 km/h | 90 km | 4.000 m | Dispensación a pacientes y vuelos a la Sierra |
| `CARGO` | **Cóndor** | 15 kg | 60 km/h | 30 km | 2.500 m | Reabastecimiento de las centrales cercanas a la suya |

El nombre viene de las aves de la región. El cóndor es símbolo de la Sierra Nevada.

Los tres cubren el triángulo velocidad–carga–alcance: ganar en uno cuesta en otro. Un cuarto tipo "de montaña" no hace falta. El Garza tiene el techo más alto, y lo que cambia en la Sierra es la energía de subida, que el motor ya calcula ([condiciones-de-vuelo.md](condiciones-de-vuelo.md)).

## Compartimento de frío

Cualquier dron puede llevar un compartimento refrigerado de 2 a 8 °C. No es un tipo aparte.

- Lo instala el operador de flota y queda marcado en el dron.
- Pesa **1 kg**, que se descuenta de la carga útil: un Colibrí con frío lleva 1 kg de producto.
- Un ítem que exige frío ([../entregas/productos.md](../entregas/productos.md)) solo viaja en un dron con el compartimento.

## Cómo elige el motor

En dos pasos, y siempre explica por qué descarta cada dron.

**1. Filtros duros.** Se descarta el dron que no cumpla cualquiera de estas condiciones:

| Condición | Motivo de descarte |
| --- | --- |
| Está disponible (no en mantenimiento ni fuera de servicio) | Estado |
| La carga útil, con el frío descontado si lo lleva, alcanza para el peso del pedido | Carga |
| Tiene compartimento de frío si algún ítem lo exige | Frío |
| La batería alcanza para ida, vuelta y reserva, sobre el perfil real de la ruta | Batería |
| El punto más alto de la ruta, más la altura de vuelo, queda bajo su techo de servicio | Techo |
| Hay un corredor legal ([espacio-aereo.md](espacio-aereo.md)) | Ruta |

**2. Puntaje según la misión.** Entre los que pasan:

| Misión | Gana | Por qué |
| --- | --- | --- |
| Urgencia (de persona o de central) | El de **menor tiempo estimado de llegada** | En una urgencia lo que importa es el tiempo |
| Programado | El de **menor energía** para esa ruta | Un vuelo programado no corre; ahorra batería y deja libres a los rápidos |

Si empatan, gana el que lleva más tiempo en tierra, luego el de más batería y al final el identificador. Así la flota rota y el resultado es estable.

## Ejemplos para la sustentación

- **Antiveneno a Patillal (urgencia, 0,3 kg, frío).** Pasan el Colibrí y el Garza con frío. Gana el Colibrí porque llega antes.
- **Reabastecer el hospital de San Diego desde La Paz (programado, 12 kg).** Solo el Cóndor lleva 12 kg y San Diego está a 5,7 km: gana el Cóndor.
- **Dispensación en Guatapurí (1.277 m, 23 km).** Con la subida, el Garza pediría el 114 % de la batería; solo el Colibrí va y vuelve (97 %).
- **Pedido a Villa Germania.** Ningún tipo pasa el filtro de batería con la subida del terreno: no son puntos de la red y va la alternativa terrestre ([../negocio/cobertura.md](../negocio/cobertura.md)).
