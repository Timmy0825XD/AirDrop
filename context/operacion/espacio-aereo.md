# Espacio aéreo

Por dónde puede volar un dron de AirDrop y por dónde no. Cada tipo de zona sale de un artículo del RAC 100 (Resolución 01983 de 2023). El detalle de la norma está en [../legal/aeronautica.md](../legal/aeronautica.md). El módulo de backend que lo aplica es `airspace/`: es el "sistema de gestión de vuelo con geocercas" que el RAC 100.445 le pide a un operador BVLOS.

## Tipos de zona

| Tipo | Qué es | Margen | Efecto en la ruta | Norma |
| --- | --- | --- | --- | --- |
| `AERODROMO` | Aeródromo publicado en la AIP. En la demo, el aeropuerto Alfonso López Pumarejo (SKVP) | Círculo de 9 km desde el ARP | **Prohibido** entrar. La franja de 6 a 9 km admitiría vuelo por debajo de 61 m, pero AirDrop no la usa: los nodos y los puntos quedan fuera del anillo | RAC 100.315(a)(14), 100.400 |
| `PROHIBIDA` | Base militar, centro penitenciario, infraestructura crítica (subestaciones y plantas eléctricas) | **2 km** desde el perímetro | Prohibido entrar | RAC 100.315(a)(13) |
| `HELIPUERTO` | Helipuerto o helipunto | 3 km desde su punto de referencia | Prohibido entrar | RAC 100.315(a)(15) |
| `COORDINADA` | Estación de policía municipal, instalación militar menor dentro de un poblado, resguardo indígena | 2 km para la policía y la instalación militar; el polígono del resguardo | Solo se entra por el **corredor pactado**, y solo hacia el punto de entrega pactado. Cualquier otro vuelo la rodea | RAC 100.315(a)(13); Decreto 1500 de 2018 |
| `URBANA` | Casco urbano de Valledupar | El polígono urbano | Prohibido: en zona urbana solo se vuela con línea de vista. Coincide casi todo con el anillo del aeropuerto | RAC 100.220(b) |
| `TEMPORAL` | Restricción que crea el administrador desde la consola: orden público, evento, operativo o elecciones | La que se dibuje, con hora de inicio y de fin | Prohibido mientras dure. Si un vuelo en curso queda afectado, se desvía o vuelve | RAC 100.315(a)(1)–(5), 100.315(c) |
| `PRECAUCION` | Pista agrícola privada que aparece en OpenStreetMap | Solo el punto | **No bloquea**. Se muestra en el mapa | Ver nota |

**Por qué las pistas privadas no bloquean.** Las pistas agrícolas del valle no tienen un ARP publicado en la AIP, y los datos de OpenStreetMap no dicen si siguen activas. Una operación real las consultaría en el visor geográfico de la Aerocivil antes de cada vuelo (100.315(c)). El simulador las muestra para que se vean, sin inventarles un margen.

**Por qué la policía municipal es "coordinada" y no prohibida.** En San Diego, Manaure, Pueblo Bello, Codazzi y Atánquez la estación está en el centro del pueblo. Aplicar 2 km prohibidos dejaría a esos pueblos sin servicio. La categoría específica admite operar con una desviación autorizada (100.410(a)(10)). El simulador lo representa como un corredor y un punto de entrega acordados con cada estación. Las licencias y permisos que eso supondría en la vida real no se simulan ([../legal/cumplimiento.md](../legal/cumplimiento.md)).

## Instalaciones de la demo

Ubicadas con OpenStreetMap (consulta de noviembre de 2026). Las que quedan dentro del anillo de 9 km se dibujan igual, aunque ningún vuelo llega ahí.

| Instalación | Tipo | Lat | Lon | Al ARP |
| --- | --- | --- | --- | --- |
| Aeropuerto Alfonso López Pumarejo (ARP según la AIP: 10°26'06.47"N, 73°14'57.83"W) | `AERODROMO` | 10.43513 | −73.24940 | 0 |
| Helipunto junto a la pista | `HELIPUERTO` | 10.43261 | −73.24885 | 0,3 km |
| Batallón de Artillería n.º 2 La Popa – Décima Brigada Blindada | `PROHIBIDA` | 10.46633 | −73.27341 | 4,4 km |
| Cárcel La Tramacúa (EPAMSCAS Valledupar) | `PROHIBIDA` | 10.44922 | −73.30887 | 6,7 km |
| Instalación militar al norte de la ciudad | `PROHIBIDA` | 10.51728 | −73.24875 | 9,1 km |
| Subestación Valledupar | `PROHIBIDA` | 10.45870 | −73.27280 | 3,7 km |
| Subestación Guatapurí | `PROHIBIDA` | 10.48672 | −73.25798 | 5,8 km |
| Planta eléctrica al sur de la ciudad | `PROHIBIDA` | 10.38182 | −73.19470 | 8,4 km |
| Planta eléctrica cerca de San Diego | `PROHIBIDA` | 10.33490 | −73.22822 | 11,4 km |
| Cerro El Aguacil (instalación militar) | `PROHIBIDA` | 10.50739 | −73.55696 | 34,6 km |
| Batallón de Alta Montaña (Serranía del Perijá) | `PROHIBIDA` | 10.02971 | −73.04506 | 50,3 km |
| Estación de policía de San Diego | `COORDINADA` | 10.32999 | −73.18429 | 13,7 km |
| Estación de policía de Manaure | `COORDINADA` | 10.38873 | −73.02976 | 24,6 km |
| Estación de policía de Pueblo Bello | `COORDINADA` | 10.41559 | −73.58651 | 36,9 km |
| Estación de policía de Codazzi | `COORDINADA` | 10.02734 | −73.23679 | 45,4 km |
| Estación de policía de Atánquez | `COORDINADA` | 10.69706 | −73.35200 | 31,2 km |
| Instalación militar de Guatapurí | `COORDINADA` | 10.72705 | −73.38933 | 35,9 km |

La "inspección de policía" de Las Raíces no entra: es una autoridad administrativa del corregimiento, no una instalación de la Policía.

Los resguardos indígenas están en [../legal/territorio.md](../legal/territorio.md).

Antes de una operación real hay que verificar con la Aerocivil (visor de ZNVD), la Décima Brigada y el INPEC los perímetros y la lista completa de infraestructura crítica. OpenStreetMap no es una fuente oficial.

## Corredores

- **Fuera de las zonas coordinadas**, el planificador busca el camino más corto que no toque ninguna zona prohibida (con su margen) ni una zona temporal activa. A ese camino le deja 150 m de holgura.
- **Dentro de una zona coordinada**, la ruta usa el corredor pactado, que es fijo, y no se recalcula.
- En vuelo, el dron no se aparta más de **30 m** del corredor aprobado (RAC 100.445). Si el clima o una zona temporal obligan a salirse, eso es un desvío replanificado, no una deriva.
- Un corredor es una línea en planta. La altura la fija [condiciones-de-vuelo.md](condiciones-de-vuelo.md).
