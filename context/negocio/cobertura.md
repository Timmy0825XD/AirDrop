# Cobertura regional

La demo cubre unos 45 km alrededor de Valledupar: la ciudad, los corregimientos del municipio, y La Paz, San Diego, Manaure, Pueblo Bello y Agustín Codazzi. Valledupar está en el centro de la red: tiene varias centrales. En la ciudad solo está vedado el anillo de 1,5 km del aeropuerto y las zonas pequeñas de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md).

## Centrales

Toda central tiene drones, inventario y despachador: despega, atiende a pacientes y abastece a otras centrales. Su tipo (hospital, clínica, farmacia, banco de sangre o vacunación) solo describe el servicio.

El abastecimiento de las centrales desde mayoristas va por carretera y queda fuera del sistema ([modelo.md](modelo.md)).

## Ubicaciones

La demo tiene 12 centrales: cuatro en Valledupar, un hospital en cada municipio y un puesto de salud en cada corregimiento. Cada una tiene dos despachadores y dos drones de cada tipo (dos Colibrí, dos Garza y dos Cóndor). Una urgencia o una entrega programada sale de la central que la atiende y llega al lugar donde la pidió la persona.

Cada central está en la sede real de su hospital o puesto de salud (en Manaure y Pueblo Bello, su dronpuerto a 200 m de la estación de policía), y todas quedan fuera de las zonas de [../operacion/espacio-aereo.md](../operacion/espacio-aereo.md). Las cuatro de Valledupar cubren el centro, el sur, el noroccidente y el oriente de la ciudad, a entre 1,6 y 4,8 km una de otra; el Centro de Salud Los Mayales no se usa porque queda dentro de la zona de un CAI. Los lugares adonde piden los solicitantes simulados usan las coordenadas de GeoNames (consultadas con el geocodificador de Open-Meteo).

### Centrales de la demo

| Central | Tipo | Lugar | Lat | Lon | Al ARP |
| --- | --- | --- | --- | --- | --- |
| Hospital Rosario Pumarejo de López | Hospital | Valledupar (centro) | 10.4682 | −73.2558 | 3,7 km |
| Hospital Eduardo Arredondo Daza | Hospital | Valledupar (sur, San Martín) | 10.4485 | −73.2589 | 1,8 km |
| Centro de Salud La Nevada | Clínica | Valledupar (noroccidente) | 10.4831 | −73.2836 | 6,5 km |
| Centro de Salud El Carmen | Clínica | Valledupar (oriente) | 10.4714 | −73.2415 | 4,1 km |
| Hospital Marino Zuleta Ramírez | Hospital | La Paz | 10.3861 | −73.1731 | 10,0 km |
| Hospital El Socorro | Hospital | San Diego | 10.3325 | −73.1808 | 13,7 km |
| Hospital José Antonio Socarrás Sánchez | Hospital | Manaure Balcón del Cesar | 10.3905 | −73.0345 | 24,1 km |
| Hospital Camilo Villazón Pumarejo | Hospital | Pueblo Bello | 10.4149 | −73.5842 | 36,8 km |
| Hospital Agustín Codazzi | Hospital | Agustín Codazzi | 10.0367 | −73.2369 | 44,3 km |
| Puesto de Salud de Río Seco | Vacunación | Río Seco (Valledupar) | 10.6047 | −73.2228 | 19,1 km |
| Puesto de Salud de Valencia de Jesús | Clínica | Valencia de Jesús (Valledupar) | 10.3000 | −73.4000 | 22,3 km |
| Puesto de Salud de Media Luna | Clínica | Media Luna (San Diego) | 10.2439 | −73.1414 | 24,3 km |

El inventario cambia según el tipo: los hospitales tienen sueros, antibióticos inyectables y medicamentos de control especial; los centros de salud, crónicos (hipertensión, diabetes) y antibióticos orales; el puesto de vacunación, vacunas en frío; y los puestos rurales, suero antiofídico. Hay a propósito un lote por vencer, un producto con poco stock y dos lotes del mismo producto (FEFO), para la demo.

**Fuera de la red por el terreno.** Con la malla de elevación real (RF-46), la ida, el regreso y la reserva pasan del 100 % de la batería en todos los tipos:

| Lugar | Central más cercana | Distancia | Batería que pide el mejor tipo (Colibrí) |
| --- | --- | --- | --- |
| Villa Germania (614 m, detrás de lomas) | Valencia de Jesús | 34,1 km | 117 % |

Chemesquemena (1.427 m, a 22,6 km del puesto de Río Seco) queda al límite: el Colibrí pide el 99 %. Nabusímake (2.135 m) queda más lejos y más alto (130 %): fuera de alcance. Los tres sirven para explicar el límite de la red: ahí sigue la alternativa terrestre.

El hospital de Pueblo Bello (1.108 m, a 20 km de Valencia de Jesús) tiene sus propios drones; desde otra central solo lo alcanza el Colibrí (87 %).

## Alcance útil de cada tipo

Cada misión es de ida y vuelta por el mismo corredor (si nadie recibe, el dron vuelve con el paquete). Además, se aterriza con el 20 % de reserva. Despegue, transición, descenso y aterrizaje cuestan 8 % por tramo. Por eso, en terreno plano y sin viento, el radio útil es:

> radio ≈ (100 − 20 − 2 × 8) / 2 % del alcance = **32 % del alcance**

| Tipo | Alcance | Radio útil en plano |
| --- | --- | --- |
| Colibrí | 120 km | 38 km |
| Garza | 90 km | 29 km |
| Cóndor | 30 km | 10 km |

El terreno y el viento lo reducen: subir cuesta energía ([../operacion/condiciones-de-vuelo.md](../operacion/condiciones-de-vuelo.md)). El motor hace la cuenta real sobre el perfil de cada ruta; por eso un punto de montaña a 23 km puede quedar fuera aunque esté dentro del radio en plano. La tabla solo sirve para ubicar las centrales.

Las ubicaciones exactas de los dronpuertos de una operación real se definirían con cada hospital, cada alcaldía y cada comunidad. En la demo son ilustrativas.
