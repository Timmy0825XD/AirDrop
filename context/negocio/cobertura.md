# Cobertura regional

La demo cubre unos 45 km alrededor de Valledupar: la ciudad, los corregimientos del municipio, y La Paz, San Diego, Manaure, Pueblo Bello y Agustín Codazzi. Valledupar está en el centro de la red: tiene su propio nodo y sus ESE. En la ciudad solo está vedado el anillo de 1,5 km del aeropuerto y las zonas pequeñas de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md).

## Los dos tipos de sitio

| Sitio | Qué tiene | Qué hace | Cuenta en el sistema |
| --- | --- | --- | --- |
| **Nodo** | Drones, inventario y despachador | Despega. Atiende a pacientes y reabastece a las ESE | Central de tipo `NODO` |
| **ESE** | Inventario y despachador, sin drones | Pide el reabastecimiento y recibe traslados | Central de tipo `ESE` |

El abastecimiento de los nodos desde Valledupar va por carretera y queda fuera del sistema ([modelo.md](modelo.md)).

## Ubicaciones

Las coordenadas de municipios y corregimientos son las de GeoNames (consultadas con el geocodificador de Open-Meteo). Su elevación es la de ese mismo registro. Los nodos son instalaciones ficticias de AirDrop, ubicadas a propósito:

- fuera de toda zona de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md), con 150 m de holgura;
- cerca de las ESE que atiende el Cóndor.

### Nodos

| Nodo | Lat | Lon | Elevación | Al ARP | Atiende |
| --- | --- | --- | --- | --- | --- |
| Nodo Valledupar | 10.4790 | −73.2350 | 170 m | 5,1 km | La ciudad de Valledupar |
| Nodo Norte (Río Seco) | 10.6075 | −73.2237 | 235 m | 19,4 km | Corregimientos del norte y la Sierra |
| Nodo Sur (La Paz – San Diego) | 10.3550 | −73.1400 | 170 m | 14,9 km | ESE La Paz, ESE San Diego, ESE Manaure, Media Luna |
| Nodo Occidente (Valencia de Jesús) | 10.3000 | −73.4050 | 185 m | 22,7 km | Valle del Cesar occidental y Pueblo Bello |
| Nodo Codazzi | 10.0420 | −73.2440 | 140 m | 43,6 km | ESE Codazzi y el sur (en el borde del casco urbano) |

### ESE (centrales sin drones)

| ESE | Lat | Lon | Elevación | Nodo | Distancia |
| --- | --- | --- | --- | --- | --- |
| Hospital Rosario Pumarejo de López (Valledupar) | 10.4772 | −73.2611 | 170 m | Valledupar | 2,8 km |
| Hospital Eduardo Arredondo Daza (Valledupar) | 10.4560 | −73.2545 | 165 m | Valledupar | 3,3 km |
| La Paz | 10.3844 | −73.1733 | 152 m | Sur | 4,9 km |
| San Diego | 10.3338 | −73.1805 | 180 m | Sur | 5,0 km |
| Manaure Balcón del Cesar | 10.3928 | −73.0325 | 726 m | Sur | 12,5 km |
| Pueblo Bello | 10.4171 | −73.5804 | 1.108 m | Occidente | 23,2 km |
| Agustín Codazzi | 10.0367 | −73.2356 | 136 m | Codazzi | 1,1 km |

**Fuera de la red por el terreno.** Con la malla de elevación real (RF-46), la ida, el regreso y la reserva pasan del 100 % de la batería en todos los tipos:

| Lugar | Nodo más cercano | Distancia | Batería que pide el mejor tipo (Colibrí) |
| --- | --- | --- | --- |
| Villa Germania (614 m, detrás de lomas) | Occidente | 34,1 km | 117 % |

Chemesquemena (1.427 m, a 22,6 km del Nodo Norte) queda al límite: el Colibrí pide el 99 %. Nabusímake (2.135 m) queda más lejos y más alto (130 %): fuera de alcance. Los tres sirven para explicar el límite de la red: ahí sigue la alternativa terrestre.

La ESE de Pueblo Bello (1.108 m, a 23 km del Nodo Occidente) solo la alcanza el Colibrí (87 %): su reabastecimiento va en entregas de hasta 2 kg.

## Alcance útil de cada tipo

Cada misión es de ida y vuelta por el mismo corredor (si nadie recibe, el dron vuelve con el paquete). Además, se aterriza con el 20 % de reserva. Despegue, transición, descenso y aterrizaje cuestan 8 % por tramo. Por eso, en terreno plano y sin viento, el radio útil es:

> radio ≈ (100 − 20 − 2 × 8) / 2 % del alcance = **32 % del alcance**

| Tipo | Alcance | Radio útil en plano |
| --- | --- | --- |
| Colibrí | 120 km | 38 km |
| Garza | 90 km | 29 km |
| Cóndor | 30 km | 10 km |

El terreno y el viento lo reducen: subir cuesta energía ([../operacion/condiciones-de-vuelo.md](../operacion/condiciones-de-vuelo.md)). El motor hace la cuenta real sobre el perfil de cada ruta; por eso un punto de montaña a 23 km puede quedar fuera aunque esté dentro del radio en plano. La tabla solo sirve para ubicar los nodos.

Las ubicaciones exactas de los dronpuertos de una operación real se definirían con cada ESE, cada alcaldía y cada comunidad. En la demo son ilustrativas.
