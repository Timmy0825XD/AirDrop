# Cobertura regional

La demo cubre unos 45 km alrededor de Valledupar: la ciudad, los corregimientos del municipio, y La Paz, San Diego, Manaure, Pueblo Bello y Agustín Codazzi. Valledupar está en el centro de la red. Tiene su propio nodo, sus ESE y sus puntos de entrega, y además sirve de **relevo**: un dron que no alcanza su destino en un solo tramo hace escala ahí ([Relevo en Valledupar](#relevo-en-valledupar)). En la ciudad solo está vedado el anillo de 1,5 km del aeropuerto y las zonas pequeñas de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md).

## Los tres tipos de sitio

| Sitio | Qué tiene | Qué hace | Cuenta en el sistema |
| --- | --- | --- | --- |
| **Nodo** | Drones, inventario y despachador | Despega. Atiende a pacientes y reabastece a las ESE | Central de tipo `NODO` |
| **ESE** | Inventario y despachador, sin drones | Pide el reabastecimiento y recibe traslados | Central de tipo `ESE` |
| **Punto de entrega** | Dronpuerto o puesto de salud, con un observador | El paciente recoge su pedido con el código | No es una cuenta; es un lugar del seed |

El abastecimiento de los nodos desde Valledupar va por carretera y queda fuera del sistema ([modelo.md](modelo.md)).

## Ubicaciones

Las coordenadas de municipios y corregimientos son las de GeoNames (consultadas con el geocodificador de Open-Meteo). Su elevación es la de ese mismo registro. Los nodos son instalaciones ficticias de AirDrop, ubicadas a propósito:

- fuera de toda zona de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md), con 150 m de holgura;
- cerca de las ESE que atiende el Cóndor.

### Nodos

| Nodo | Lat | Lon | Elevación | Al ARP | Atiende |
| --- | --- | --- | --- | --- | --- |
| Nodo Valledupar | 10.4790 | −73.2350 | 170 m | 5,1 km | La ciudad, y relevo de toda la red |
| Nodo Norte (Río Seco) | 10.6075 | −73.2237 | 235 m | 19,4 km | Corregimientos del norte y la Sierra |
| Nodo Sur (La Paz – San Diego) | 10.3550 | −73.1400 | 170 m | 14,9 km | ESE La Paz, ESE San Diego, ESE Manaure, Media Luna |
| Nodo Occidente (Valencia de Jesús) | 10.3000 | −73.4050 | 185 m | 22,7 km | Valle del Cesar occidental y Pueblo Bello |
| Nodo Codazzi | 10.0550 | −73.2550 | 140 m | 42,3 km | ESE Codazzi y el sur |

### ESE (centrales sin drones)

| ESE | Lat | Lon | Elevación | Nodo | Distancia |
| --- | --- | --- | --- | --- | --- |
| Hospital Rosario Pumarejo de López (Valledupar) | 10.4772 | −73.2611 | 170 m | Valledupar | 2,8 km |
| Hospital Eduardo Arredondo Daza (Valledupar) | 10.4560 | −73.2545 | 165 m | Valledupar | 3,3 km |
| La Paz | 10.3844 | −73.1733 | 152 m | Sur | 4,9 km |
| San Diego | 10.3338 | −73.1805 | 180 m | Sur | 5,0 km |
| Manaure Balcón del Cesar | 10.3928 | −73.0325 | 726 m | Sur | 12,5 km |
| Pueblo Bello | 10.4171 | −73.5804 | 1.108 m | Occidente | 23,2 km |
| Agustín Codazzi | 10.0367 | −73.2356 | 136 m | Codazzi | 2,9 km |

### Puntos de entrega

| Punto | Lat | Lon | Elevación | Nodo | Distancia | Nota |
| --- | --- | --- | --- | --- | --- | --- |
| Los Mayales (Valledupar) | 10.4510 | −73.2400 | 165 m | Valledupar | 3,1 km | Barrio |
| La Nevada (Valledupar) | 10.4950 | −73.2870 | 185 m | Valledupar | 6,0 km | Barrio |
| Primero de Mayo (Valledupar) | 10.4555 | −73.2590 | 165 m | Valledupar | 3,7 km | Barrio |
| Villa Miriam (Valledupar) | 10.4560 | −73.2300 | 160 m | Valledupar | 2,6 km | Barrio |
| Patillal | 10.7064 | −73.2123 | 513 m | Norte | 11,1 km | |
| Badillo | 10.6314 | −73.1279 | 200 m | Norte | 10,8 km | |
| Guacoche | 10.4964 | −73.1660 | 130 m | Norte | 13,9 km | |
| Guacochito | 10.5154 | −73.1517 | 133 m | Norte | 12,9 km | |
| Atánquez | 10.6976 | −73.3545 | 793 m | Norte | 17,5 km | |
| Guatapurí | 10.7261 | −73.3925 | 1.277 m | Norte | 22,7 km | Con la subida, solo la alcanza el Colibrí |
| Media Luna | 10.2455 | −73.1439 | 407 m | Sur | 12,2 km | |
| Valencia de Jesús | 10.3017 | −73.3945 | 185 m | Occidente | 1,2 km | |
| Aguas Blancas | 10.2253 | −73.4910 | 184 m | Occidente | 12,6 km | |
| Mariangola | 10.1851 | −73.5871 | 124 m | Occidente | 23,7 km | |

**Fuera de la red por el terreno.** Con la malla de elevación real (RF-46), la ida, el regreso y la reserva pasan del 100 % de la batería en todos los tipos:

| Lugar | Nodo más cercano | Distancia | Batería que pide el mejor tipo (Colibrí) |
| --- | --- | --- | --- |
| Villa Germania (614 m, detrás de lomas) | Occidente | 34,1 km | 117 % |

Chemesquemena (1.427 m, a 22,6 km del Nodo Norte) queda al límite: el Colibrí pide el 99 %. Con un margen tan justo no se ofrece como punto. Nabusímake (2.135 m) tampoco es punto de entrega: queda más lejos y más alto (130 %). Los tres sirven para explicar el límite de la red, incluso con relevo: ahí sigue la alternativa terrestre.

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

## Relevo en Valledupar

El insumo a veces está solo en un nodo que queda lejos del destino. Si ningún dron de los nodos que tienen el insumo alcanza el destino ida y vuelta en un solo tramo, el motor prueba la misma misión **con escala en el Nodo Valledupar**:

1. El dron sale de su nodo con el paquete y vuela al Nodo Valledupar.
2. Aterriza. En Valledupar le cambian la batería por una llena; esto toma **5 minutos** simulados. El paquete no se baja, y el manifiesto es el mismo.
3. Sale de Valledupar hacia el destino y entrega.
4. Vuelve a Valledupar, cambia la batería otra vez y regresa a su nodo. Si nadie recibió, el paquete hace el mismo camino de vuelta.

Las reglas:

- **Una sola escala**, y solo en el Nodo Valledupar.
- **Cada tramo cierra con su propia batería**, con la reserva del 20 %:
  - el nodo de origen → Valledupar;
  - Valledupar → destino → Valledupar;
  - Valledupar → nodo de origen.
- Toda la misión, escalas incluidas, tiene que **terminar antes de la puesta del sol** (RF-44).
- Si hay ruta directa, gana la directa. El relevo solo entra cuando la directa no existe.
- En la decisión del pedido queda dicho que hubo relevo y por qué.

El relevo no cambia el dron ni el paquete, solo la batería. Si con relevo tampoco alcanza, va la alternativa terrestre.

Las ubicaciones exactas de los dronpuertos de una operación real se definirían con cada ESE, cada alcaldía y cada comunidad. En la demo son ilustrativas.
