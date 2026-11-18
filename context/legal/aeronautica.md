# Norma aeronáutica

**RAC 100, "Operación de Sistemas de Aeronaves no Tripuladas (UAS)"**, adoptado por la Resolución 01983 del 27 de septiembre de 2023 (Diario Oficial 52.531) de la Aerocivil (UAEAC). Después vinieron dos enmiendas: la 1, con la Resolución 00718 de 2024 (sistema de gestión de seguridad), y la 2, con la Resolución 03034 de 2024. Junto con la Resolución 00317 de 2025, las fuentes secundarias describen esta última como un ajuste de plazos de transición. Los artículos citados aquí son los del texto de 2023. No encontramos el texto consolidado vigente publicado por la Aerocivil para compararlo artículo por artículo.

Este archivo dice qué artículo respalda cada regla del simulador y qué se deja fuera. Las zonas de la demo tienen el tamaño que muestra el visor de la Aerocivil, no el margen completo del RAC 100: es una simplificación declarada para que la red se pueda ver ([../operacion/espacio-aereo.md](../operacion/espacio-aereo.md#escala-de-la-demo)). Las reglas operativas están en [../operacion/](../operacion/).

## Dónde encaja AirDrop

Una operación real de AirDrop sería de **categoría específica** (100.205, comercial), tipo **"Transporte de carga (Drone Delivery)"** (100.405(a)(7)), con vuelos **BVLOS**: más de 3 km de distancia horizontal (100.445).

## Lo que se simula

| Artículo | Qué dice | Cómo lo aplica AirDrop |
| --- | --- | --- |
| 100.220(a)(3) | No se autorizan, en ningún caso, entregas con dron de noche | **Simplificación del MVP:** se vuela a cualquier hora (RF-44, [condiciones de vuelo](../operacion/condiciones-de-vuelo.md)) |
| 100.220(b) | En zona urbana: solo VLOS, a 30 m de personas y edificios, 122 m como máximo | Simplificado: el dron vuela sobre la ciudad, pero entrega en un punto con observador, a 30 m de personas ajenas |
| 100.220(c) | En vuelo autónomo hay que poder tomar el control y seguir la trayectoria en tiempo real | Telemetría en vivo y radar; la consola puede ordenar el regreso |
| 100.315(a)(1)–(5) | No volar en zonas prohibidas, restringidas, peligrosas, de entrenamiento ni en ZNVD | Zonas `PROHIBIDA` y `TEMPORAL` ([espacio aéreo](../operacion/espacio-aereo.md)) |
| 100.315(a)(13) | A menos de 2 km del perímetro de bases militares o de policía, cárceles e infraestructura crítica | Zona `PROHIBIDA` con el tamaño del visor: círculo de 100 m sobre la policía o polígono de la instalación, sin el margen de 2 km |
| 100.315(a)(14) | 9 km desde el ARP de un aeropuerto. Entre 6 y 9 km, hasta 61 m sobre el umbral más bajo | Zona `AERODROMO` de 1,5 km alrededor de SKVP, sin la franja de 6 a 9 km. Ningún nodo ni punto queda dentro |
| 100.315(a)(15) | 3 km desde el punto de referencia de un helipuerto | Zona `HELIPUERTO` de 300 m |
| 100.315(c) | Consultar en cada vuelo las áreas publicadas | El planificador revisa todas las zonas activas antes de cada vuelo y en cada replanificación |
| 100.320 | No volar sobre personas; 30 m horizontales | **Simplificación del MVP:** el dron llega a la ubicación del solicitante; no se verifica observador ni distancia (RF-45) |
| 100.400(b)–(c) | Cerca de un aeropuerto, coordinación previa con el servicio de tránsito aéreo (CDM) | No se simula: ningún vuelo entra al anillo de 1,5 km |
| 100.440 | Drone Delivery: VMC, monitoreo meteorológico, áreas de aterrizaje forzoso, dronpuertos, plan de emergencias, **manifiesto numerado por operación** | Clima simulado con VMC, puntos seguros ([contingencias](../operacion/contingencias.md)), nodos y ESE, y [manifiesto](../operacion/manifiesto.md) |
| 100.445 | BVLOS: 122 m AGL como máximo, desviación máxima de 30 m de la ruta, la pérdida del enlace C2 es una emergencia, sistema de gestión de vuelo con geocercas y telemetría visible | Techo de 120 m AGL, corredor con tolerancia de 30 m, protocolo de enlace perdido y módulo `airspace/` |

## Lo que no se simula

Son requisitos para que una empresa opere, no reglas de cómo vuela el sistema. Se dan por cumplidos (ver [cumplimiento.md](cumplimiento.md)):

- Certificado de explotador UAS, Manual de Operaciones y análisis de riesgos (100.410).
- Autorización de cada vuelo y de las áreas BVLOS por la UAEAC (100.410, 100.445).
- Piloto UAS al mando con certificado de idoneidad y sus adiciones (BVLOS, nocturno), del capítulo de personal del RAC 100.
- Explotador como persona jurídica y permiso de transporte público de carga RAC 5 (100.440).
- 250 h de pruebas de carga del modelo de dron (100.440).
- Pólizas de responsabilidad civil, de pérdida de la carga y de daños a terceros (100.410, 100.440).
- Registro de los drones ante la UAEAC.
- Mercancías peligrosas (RAC 175): AirDrop no transporta ninguna. Ver [salud.md](salud.md).
