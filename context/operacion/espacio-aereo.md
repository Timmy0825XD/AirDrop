# Espacio aéreo

Este archivo dice por dónde puede volar un dron de AirDrop y por dónde no. El módulo de backend que lo aplica es `airspace/`, el "sistema de gestión de vuelo con geocercas" que el RAC 100.445 le pide a un operador BVLOS. La norma está en [../legal/aeronautica.md](../legal/aeronautica.md).

## Escala de la demo

El RAC 100 pone márgenes grandes: 9 km alrededor de un aeropuerto y 2 km alrededor de bases, cárceles e infraestructura crítica. Con esos márgenes, Valledupar entera queda prohibida y el mapa no muestra nada útil. Por eso la demo dibuja cada zona **con el tamaño que tiene en el visor de zonas de la Aerocivil**: un círculo pequeño sobre cada estación de policía y un polígono sobre cada batallón, cárcel o planta. El aeropuerto queda con un anillo de 1,5 km.

Esto es una **simplificación declarada**, no la norma. Una operación real aplicaría los márgenes del RAC 100 y consultaría el visor antes de cada vuelo (100.315(c)).

## Tipos de zona

| Tipo | Qué es | Forma en la demo | Efecto en la ruta | Norma de referencia |
| --- | --- | --- | --- | --- |
| `AERODROMO` | El aeropuerto Alfonso López Pumarejo (SKVP) | Círculo de **1,5 km** desde el ARP | Prohibido entrar | RAC 100.315(a)(14) |
| `PROHIBIDA` | Estación de policía o CAI, batallón o brigada, cárcel, subestación o planta eléctrica, pista agrícola | La del visor: círculo de **100 m** (policía), **400 m** (pista agrícola), el polígono de la instalación o, si solo se conoce su área, un círculo de esa superficie | Prohibido entrar. El dron la rodea | RAC 100.315(a)(13) |
| `HELIPUERTO` | Helipuerto o helipunto fuera de un aeródromo | Círculo de **300 m** | Prohibido entrar. El helipunto de SKVP queda dentro del anillo del aeropuerto y no se dibuja aparte | RAC 100.315(a)(15) |
| `TEMPORAL` | Restricción que crea el administrador desde la consola: orden público, evento, operativo o elecciones | La que se dibuje, con hora de inicio y de fin | Prohibido mientras dure. Si un vuelo en curso queda afectado, se desvía o vuelve | RAC 100.315(a)(1)–(5), 100.315(c) |

No hay zona urbana que bloquee: el dron vuela sobre la ciudad y entrega en un punto con observador ([../entregas/persona.md](../entregas/persona.md)). Tampoco hay zonas coordinadas ni corredores pactados.

## Instalaciones de la demo

Fuentes:
- El aeropuerto, de la AIP. Las pistas agrícolas, de OpenStreetMap.
- Todo lo demás (CAI, estaciones, batallones, cárcel, subestaciones y granjas solares), de una lista de ubicaciones que reunió el equipo en noviembre de 2026. Donde hay esquinas del terreno, la zona es ese polígono; donde solo hay área, es un círculo de la misma superficie.
- Un CAI dentro del anillo del aeropuerto no se dibuja: ya está cubierto. Por eso no está el CAI San Fernando.
- En Guatapurí no hay una instalación militar permanente (solo puestos temporales de alta montaña): no se dibuja.

### Valledupar

| Instalación | Tipo | Forma | Lat | Lon |
| --- | --- | --- | --- | --- |
| Aeropuerto Alfonso López Pumarejo (ARP según la AIP) | `AERODROMO` | Círculo de 1,5 km | 10.43513 | −73.24940 |
| Batallón La Popa – Décima Brigada Blindada | `PROHIBIDA` | Polígono de unos 1,4 × 1,2 km | 10.4665 | −73.2740 |
| Cárcel La Tramacúa (CPAMS Valledupar) | `PROHIBIDA` | Polígono de unos 390 × 380 m | 10.4638 | −73.3035 |
| Batallón de Ingenieros N.° 10 General Manuel Alberto Murillo | `PROHIBIDA` | Círculo de 330 m | 10.5285 | −73.2495 |
| Subestación Valledupar (220/110 kV) | `PROHIBIDA` | Círculo de 120 m | 10.4435 | −73.2685 |
| Subestación Guatapurí (110 kV) | `PROHIBIDA` | Círculo de 60 m | 10.48672 | −73.25798 |
| Granjas solares del sector La Mesa | `PROHIBIDA` | Círculo de 500 m | 10.4380 | −73.3250 |
| CAI Hurtado | `PROHIBIDA` | Círculo de 100 m | 10.5038 | −73.2682 |
| CAI San Joaquín | `PROHIBIDA` | Círculo de 100 m | 10.4712 | −73.2575 |
| CAI Garupal | `PROHIBIDA` | Círculo de 100 m | 10.4785 | −73.2688 |
| CAI El Carmen | `PROHIBIDA` | Círculo de 100 m | 10.4715 | −73.2435 |
| CAI Gobernación | `PROHIBIDA` | Círculo de 100 m | 10.4762 | −73.2465 |
| CAI Primero de Mayo | `PROHIBIDA` | Círculo de 100 m | 10.4618 | −73.2530 |
| CAI Mayales | `PROHIBIDA` | Círculo de 100 m | 10.4535 | −73.2415 |

### Pueblos y corregimientos

| Instalación | Tipo | Forma | Lat | Lon |
| --- | --- | --- | --- | --- |
| Estación de policía de La Paz | `PROHIBIDA` | Círculo de 100 m | 10.3845 | −73.1722 |
| Estación de policía de San Diego | `PROHIBIDA` | Círculo de 100 m | 10.3364 | −73.1815 |
| Estación de policía de Manaure | `PROHIBIDA` | Círculo de 100 m | 10.3918 | −73.0332 |
| Estación de policía de Pueblo Bello | `PROHIBIDA` | Círculo de 100 m | 10.4162 | −73.5855 |
| Estación de policía de Agustín Codazzi | `PROHIBIDA` | Círculo de 100 m | 10.0385 | −73.2375 |
| Estación de policía de Atánquez | `PROHIBIDA` | Círculo de 100 m | 10.7015 | −73.3485 |
| Subestación de policía de Valencia de Jesús | `PROHIBIDA` | Círculo de 100 m | 10.3125 | −73.4018 |
| Subestación de policía de Aguas Blancas | `PROHIBIDA` | Círculo de 100 m | 10.2445 | −73.4852 |
| Subestación de policía de Mariangola | `PROHIBIDA` | Círculo de 100 m | 10.1812 | −73.5625 |
| Subestación de policía de Patillal | `PROHIBIDA` | Círculo de 100 m | 10.6655 | −73.1492 |
| Subestación de policía de Badillo | `PROHIBIDA` | Círculo de 100 m | 10.6318 | −73.1115 |
| Batallón de Alta Montaña N.° 7 Mayor Raúl Guillermo Mahecha (Perijá) | `PROHIBIDA` | Círculo de 280 m | 9.9850 | −73.0650 |

En Manaure y Pueblo Bello el hospital queda pegado a la estación de policía (16 m y 94 m). Su dronpuerto se ubica a 200 m de la estación, del lado opuesto: el hospital sigue siendo la central, pero el dron despega y aterriza fuera de la zona.

### Pistas agrícolas

OpenStreetMap trae unas 25 en el valle. Para no saturar el mapa, la demo usa las 6 que quedan cerca de rutas reales. Cada una es una zona `PROHIBIDA`: un círculo de 400 m que cubre la pista.

| Pista | Lat | Lon |
| --- | --- | --- |
| Codazzi | 10.11143 | −73.22570 |
| Las Flores | 10.10260 | −73.23302 |
| Ana María | 10.03750 | −73.28361 |
| Aguas Blancas | 10.20756 | −73.47514 |
| Convención | 10.26407 | −73.41425 |
| Madaci | 10.32760 | −73.37257 |

Ni OpenStreetMap ni la lista del equipo son fuentes oficiales. Antes de una operación real habría que verificar los perímetros con la Aerocivil, la Policía, el Ejército y el INPEC.

## Corredores

- El planificador busca el camino más corto que no toque ninguna zona prohibida, del aeródromo, de un helipuerto ni una zona temporal activa. Le deja **150 m** de holgura al borde.
- En vuelo, el dron no se aparta más de **30 m** del corredor aprobado (RAC 100.445). Si el clima o una zona temporal obligan a salirse, eso es un desvío replanificado, no una deriva.
- Un corredor es una línea en planta. La altura la fija [condiciones-de-vuelo.md](condiciones-de-vuelo.md).
