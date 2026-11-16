# Espacio aéreo

Este archivo dice por dónde puede volar un dron de AirDrop y por dónde no. El módulo de backend que lo aplica es `airspace/`, el "sistema de gestión de vuelo con geocercas" que el RAC 100.445 le pide a un operador BVLOS. La norma está en [../legal/aeronautica.md](../legal/aeronautica.md).

## Escala de la demo

El RAC 100 pone márgenes grandes: 9 km alrededor de un aeropuerto y 2 km alrededor de bases, cárceles e infraestructura crítica. Con esos márgenes, Valledupar entera queda prohibida y el mapa no muestra nada útil. Por eso la demo dibuja cada zona **con el tamaño que tiene en el visor de zonas de la Aerocivil**: un círculo pequeño sobre cada estación de policía y un polígono sobre cada batallón, cárcel o planta. El aeropuerto queda con un anillo de 1,5 km.

Esto es una **simplificación declarada**, no la norma. Una operación real aplicaría los márgenes del RAC 100 y consultaría el visor antes de cada vuelo (100.315(c)).

## Tipos de zona

| Tipo | Qué es | Forma en la demo | Efecto en la ruta | Norma de referencia |
| --- | --- | --- | --- | --- |
| `AERODROMO` | El aeropuerto Alfonso López Pumarejo (SKVP) | Círculo de **1,5 km** desde el ARP | Prohibido entrar | RAC 100.315(a)(14) |
| `PROHIBIDA` | Estación de policía o CAI, batallón o brigada, cárcel, subestación o planta eléctrica, pista agrícola | La del visor: círculo de **100 m** (policía), **150 m** (fuerte o puesto militar menor), **400 m** (pista agrícola), o el polígono de la instalación | Prohibido entrar. El dron la rodea | RAC 100.315(a)(13) |
| `HELIPUERTO` | Helipuerto o helipunto fuera de un aeródromo | Círculo de **300 m** | Prohibido entrar. El helipunto de SKVP queda dentro del anillo del aeropuerto y no se dibuja aparte | RAC 100.315(a)(15) |
| `TEMPORAL` | Restricción que crea el administrador desde la consola: orden público, evento, operativo o elecciones | La que se dibuje, con hora de inicio y de fin | Prohibido mientras dure. Si un vuelo en curso queda afectado, se desvía o vuelve | RAC 100.315(a)(1)–(5), 100.315(c) |

No hay zona urbana que bloquee: el dron vuela sobre la ciudad y entrega en un punto con observador ([../entregas/persona.md](../entregas/persona.md)). Tampoco hay zonas coordinadas ni corredores pactados.

## Instalaciones de la demo

Fuentes:
- Las grandes salen de OpenStreetMap (consulta de noviembre de 2026).
- Los CAI de Valledupar y las estaciones de La Paz, San Diego, Manaure y Pueblo Bello vienen de una lista de direcciones de la Policía que reunió el equipo. Un CAI pegado a otra zona (a menos de 300 m) o dentro del anillo del aeropuerto no se dibuja: ya está cubierto. Por eso no están el CAI Pedregosa, el Comando Departamental, el CAI Mercabastos ni el CAI Sabanas del Valle.
- Las subestaciones de los corregimientos se ubicaron en el centro del poblado, con las capturas del visor de la Aerocivil.

### Valledupar

| Instalación | Tipo | Forma | Lat | Lon |
| --- | --- | --- | --- | --- |
| Aeropuerto Alfonso López Pumarejo (ARP según la AIP) | `AERODROMO` | Círculo de 1,5 km | 10.43513 | −73.24940 |
| Batallón La Popa – Décima Brigada Blindada | `PROHIBIDA` | Polígono de unos 400 × 300 m | 10.46633 | −73.27341 |
| Cárcel La Tramacúa (CPAMS Valledupar) | `PROHIBIDA` | Polígono de unos 300 × 250 m | 10.44922 | −73.30887 |
| Instalación militar al norte de la ciudad | `PROHIBIDA` | Círculo de 150 m | 10.51728 | −73.24875 |
| Subestación Valledupar | `PROHIBIDA` | Círculo de 100 m | 10.45870 | −73.27280 |
| Subestación Guatapurí | `PROHIBIDA` | Círculo de 100 m | 10.48672 | −73.25798 |
| Planta eléctrica al sur de la ciudad | `PROHIBIDA` | Círculo de 150 m | 10.38182 | −73.19470 |
| CAI Hurtado | `PROHIBIDA` | Círculo de 100 m | 10.5010 | −73.2681 |
| CAI San Joaquín | `PROHIBIDA` | Círculo de 100 m | 10.4764 | −73.2558 |
| CAI Garupal | `PROHIBIDA` | Círculo de 100 m | 10.4748 | −73.2645 |
| CAI El Carmen | `PROHIBIDA` | Círculo de 100 m | 10.4712 | −73.2608 |
| CAI Gobernación | `PROHIBIDA` | Círculo de 100 m | 10.4705 | −73.2494 |
| CAI Primero de Mayo | `PROHIBIDA` | Círculo de 100 m | 10.4578 | −73.2562 |
| CAI Mayales | `PROHIBIDA` | Círculo de 100 m | 10.4535 | −73.2428 |
| CAI San Fernando | `PROHIBIDA` | Círculo de 100 m | 10.4405 | −73.2355 |

### Pueblos y corregimientos

| Instalación | Tipo | Forma | Lat | Lon |
| --- | --- | --- | --- | --- |
| Estación de policía de La Paz | `PROHIBIDA` | Círculo de 100 m | 10.38540 | −73.17220 |
| Estación de policía de San Diego | `PROHIBIDA` | Círculo de 100 m | 10.33640 | −73.18150 |
| Estación de policía de Manaure | `PROHIBIDA` | Círculo de 100 m | 10.39160 | −73.03220 |
| Estación de policía de Pueblo Bello | `PROHIBIDA` | Círculo de 100 m | 10.41670 | −73.58330 |
| Estación de policía de Codazzi | `PROHIBIDA` | Círculo de 100 m | 10.02734 | −73.23679 |
| Estación de policía de Atánquez | `PROHIBIDA` | Círculo de 100 m | 10.69706 | −73.35200 |
| Subestación de policía de Valencia de Jesús | `PROHIBIDA` | Círculo de 100 m | 10.30100 | −73.39150 |
| Subestación de policía de Aguas Blancas | `PROHIBIDA` | Círculo de 100 m | 10.22800 | −73.49500 |
| Subestación de policía de Mariangola | `PROHIBIDA` | Círculo de 100 m | 10.18700 | −73.58900 |
| Subestación de policía de Patillal | `PROHIBIDA` | Círculo de 100 m | 10.70900 | −73.21000 |
| Subestación de policía de Badillo | `PROHIBIDA` | Círculo de 100 m | 10.63400 | −73.12600 |
| Instalación militar de Guatapurí | `PROHIBIDA` | Círculo de 150 m | 10.72705 | −73.38933 |
| Batallón de Alta Montaña (Serranía del Perijá) | `PROHIBIDA` | Círculo de 150 m | 10.02971 | −73.04506 |

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

OpenStreetMap no es una fuente oficial. Antes de una operación real habría que verificar los perímetros con la Aerocivil, la Policía, la Décima Brigada y el INPEC.

## Corredores

- El planificador busca el camino más corto que no toque ninguna zona prohibida, del aeródromo, de un helipuerto ni una zona temporal activa. Le deja **150 m** de holgura al borde.
- En vuelo, el dron no se aparta más de **30 m** del corredor aprobado (RAC 100.445). Si el clima o una zona temporal obligan a salirse, eso es un desvío replanificado, no una deriva.
- Un corredor es una línea en planta. La altura la fija [condiciones-de-vuelo.md](condiciones-de-vuelo.md).
