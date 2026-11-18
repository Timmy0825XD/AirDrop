# Product backlog, sprints e incrementos

Marco: **Scrum**. Pilares: transparencia, inspección, adaptación. Ceremonias: Sprint Planning, Daily (15 min), Sprint Review, Retrospective.

## Roles

| Scrum | Persona | Construcción |
| --- | --- | --- |
| Product Owner | Oscar Duque | Frontend |
| Scrum Master | Josheph Martínez | Backend |
| Development Team | Oscar Duque, Josheph Martínez, Sebastian Carrillo | Carrillo: mapa en vivo y cliente WebSocket |

Periodo: **1 de septiembre – 22 de noviembre de 2026**. Seis sprints de dos semanas. Estimación Fibonacci. **Total: 227 SP.** Los sprints 5 y 6 concentran simulación y telemetría.

Prioridad **Alta** = núcleo del MVP. **Media** = necesario pero puede recortarse con criterio del PO si el tiempo aprieta (hay que documentarlo).

---

## Módulo 1 — Autenticación y acceso

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-01 | Registro civil con documento, celular y OTP. Despachador y operador los crea el admin | Alta | 5 | 1 |
| HU-02 | OTP 6 dígitos, 10 minutos | Alta | 3 | 1 |
| HU-03 | Login y JWT según rol | Alta | 3 | 1 |
| HU-04 | Cerrar sesión | Alta | 1 | 1 |
| HU-05 | Recuperar contraseña, código 15 min | Media | 3 | 1 |

## Módulo 2 — Perfiles, centrales e inventario

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-06 | Admin crea la central (nombre, tipo, ubicación, contacto) | Alta | 5 | 1 |
| HU-07 | Admin suspende o reactiva una central | Alta | 5 | 2 |
| HU-08 | Perfil básico del solicitante | Media | 3 | 2 |
| HU-09 | Inventario (cantidad, lote, vencimiento, frío, tipo de venta) | Alta | 8 | 2 |
| HU-10 | Admin crea despachadores (una central) y operadores (una o varias), y puede suspenderlos | Media | 5 | 2 |

## Módulo 3 — Flota y geovallas

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-11 | Alta de dron + `DroneModel` (los tres tipos de RF-49 desde HU-63) | Alta | 8 | 1 |
| HU-12 | Estados de disponibilidad | Alta | 5 | 2 |
| HU-13 | Mantenimiento y fuera de servicio | Media | 3 | 2 |
| HU-14 | Dibujar y editar geovallas | Alta | 8 | 2 |

## Módulo 4 — Pedidos

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-15 | Pedido de emergencia (imagen de fórmula si es venta bajo fórmula; control especial no se crea) | Alta | 8 | 3 |
| HU-16 | Estados del pedido (incluye pendiente de carga, espera y retorno) | Alta | 5 | 3 |
| HU-17 | Cola de emergencia para el despachador | Alta | 5 | 3 |
| HU-18 | Abastecimiento programado entre centrales, o entrega periódica a un solicitante | Alta | 8 | 3 |
| HU-19 | Alerta de pedido sin atender | Media | 3 | 3 |
| HU-20 | Historial del solicitante | Media | 3 | 3 |

## Módulo 5 — Decisión y rutas

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-21 | Elegibilidad al autorizar (reserva dron; no despega) | Alta | 13 | 4 |
| HU-22 | Emergencia gana el dron | Alta | 5 | 4 |
| HU-23 | Ruta por corredores, evita geovallas | Alta | 13 | 4 |
| HU-24 | Fallback si nadie es elegible | Alta | 8 | 6 |

## Módulo 6 — Simulación y telemetría

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-25 | Simular movimiento y batería por fase (solo tras confirmar carga) | Alta | 13 | 5 |
| HU-26 | Publicar telemetría por WebSockets | Alta | 13 | 5 |
| HU-27 | Panel de telemetría del operador | Alta | 8 | 5 |
| HU-28 | Mapa en vivo para el solicitante | Alta | 8 | 5 |
| HU-29 | Push de aterrizaje / cambio de estado | Media | 5 | 5 |
| HU-30 | Alerta batería crítica o falla | Media | 5 | 5 |

## Módulo 7 — Frío y entrega

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-31 | Flag de sensible a temperatura | Media | 3 | 6 |
| HU-32 | Alerta de temperatura fuera de rango | Alta | 5 | 6 |
| HU-33 | Código de entrega de un uso | Alta | 5 | 6 |
| HU-34 | Espera de código 5 min; si no, retorno con el paquete y cuarentena | Alta | 5 | 6 |
| HU-35 | Despachador confirma carga, información de uso y registro de salida | Alta | 5 | 6 |

## Módulo 8 — Historial, dashboard, admin

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-36 | Histórico de misiones de la central | Media | 3 | 6 |
| HU-37 | Dashboard epidemiológico | Media | 8 | 6 |
| HU-38 | Métricas de administrador | Media | 5 | 6 |

**Suma: 227 SP.**

## Módulo 9 — Consola de simulación (ampliación)

Se agregó después de planear los seis sprints, para presentar el sistema en una TV (RU-32). No cambia los 227 SP del plan original y se cuenta aparte.

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-39 | Reloj simulado: pausa, x1, x2, x4, x8 para todo el sistema (RF-31) | Alta | 13 | 6 |
| HU-40 | Línea de tiempo y alertas pendientes en la sala del radar (RF-39) | Alta | 8 | 6 |
| HU-41 | Escenario de demostración y reinicio (RF-40) | Alta | 5 | 6 |
| HU-42 | Consola en la web: barra de tiempo, interruptores, línea de tiempo y alertas | Alta | 8 | 6 |
| HU-43 | Cambio de ruta en vuelo (RF-33) | Alta | 13 | 6 |
| HU-44 | Clima simulado por zonas en decisión, rutas y vuelo (RF-32) | Alta | 8 | 6 |
| HU-45 | Geovallas temporales (RF-36) | Media | 5 | 6 |
| HU-46 | Incidentes y protocolos; volver a despachar la urgencia (RF-34, RF-35) | Alta | 13 | 6 |
| HU-47 | Catálogo de fallas y choques del dron (RF-34) | Alta | 5 | 6 |
| HU-48 | Central sin energía y pico de urgencias (RF-36) | Media | 5 | 6 |
| HU-49 | Eventos sobre el mapa y capas de clima, incidentes y rutas en la web | Alta | 8 | 6 |
| HU-50 | Actores simulados: despachador automático, generador y receptor (RF-37) | Alta | 8 | 6 |
| HU-51 | Modo caos realista (RF-38) | Media | 5 | 6 |
| HU-52 | Contrato de estados, avisos y hora simulada para la app | Media | 3 | 6 |

**Suma del módulo 9: 107 SP.**

## Módulo 10 — Solicitud de urgencia (ampliación)

Se agregó después de probar la urgencia con personas: pedir debía ser más rápido y darle al despachador lo que necesita para decidir. Se cuenta aparte.

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-53 | Tamizaje de la urgencia: alarma con 123, síntomas, desde cuándo, intensidad y alergias (RF-41) | Alta | 8 | 6 |
| HU-54 | Paciente a cargo: la urgencia o el plan para un hijo o un familiar (RF-42) | Alta | 5 | 6 |
| HU-55 | Fórmula en PDF o hasta 3 fotos, con cámara (RU-25, RF-27) | Alta | 5 | 6 |
| HU-56 | Visor de la fórmula con zoom, abrir con otra app y consulta desde el histórico (RF-27, CU-13) | Alta | 5 | 6 |
| HU-57 | Ubicación por GPS (RU-02); es el destino de la urgencia y del plan | Alta | 5 | 6 |
| HU-58 | Urgencia en 3 pasos y tamizaje en el detalle y la cola del despachador | Alta | 8 | 6 |

**Suma del módulo 10: 36 SP.**

## Módulo 11 — Red regional y cumplimiento (ampliación)

Se agregó tras revisar el RAC 100, la Ley 1581 y la crítica del profesor a la geovalla del aeropuerto. La demo pasa a ser regional ([../negocio/cobertura.md](../negocio/cobertura.md)) y el vuelo sigue la norma ([../operacion/](../operacion/)). Se cuenta aparte.

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-59 | Red regional: central nodo o ESE, puntos de entrega y escenario con 5 nodos, 7 ESE y 14 puntos (RF-06, RF-07, RF-45) | Alta | 8 | 6 |
| HU-60 | Zonas legales a escala de demo: aeródromo de 1,5 km y zonas prohibidas del tamaño del visor (RF-43, RF-12) | Alta | 13 | 6 |
| HU-61 | Solo de día: salida y puesta del sol con la NOAA, urgencia nocturna a traslado convencional (RF-44) | Alta | 5 | 6 |
| HU-62 | Malla de terreno SRTM, perfil a 90 m AGL y energía de ascenso (RF-46) | Alta | 13 | 6 |
| HU-63 | Flota de tres tipos, compartimento de frío y selección por tipo de misión (RF-49, RF-11) | Alta | 8 | 6 |
| HU-64 | Punto de entrega en la urgencia y en el plan; fuera de cobertura sin punto al alcance (RU-02, RU-30, RF-45) | Alta | 5 | 6 |
| HU-65 | Manifiesto de carga numerado (RF-47) | Alta | 5 | 6 |
| HU-66 | Identificación remota en el radar y dron no identificado (RF-48, RF-36) | Media | 5 | 6 |
| HU-67 | Niebla y límite de viento por tipo (RF-32) | Media | 3 | 6 |
| HU-68 | Pérdida de enlace C2 y aterrizaje en punto seguro (RF-34) | Media | 5 | 6 |
| HU-69 | Política versionada, tamizaje opcional, revocar y suprimir la cuenta (RF-50) | Alta | 8 | 6 |
| HU-70 | Registro de acceso a fórmulas (RF-51) | Media | 3 | 6 |
| HU-71 | Accesibilidad y conexión rural débil (RNF-16, RNF-17) | Media | 5 | 6 |

**Suma del módulo 11: 86 SP.**

## Módulo 12 — Rediseño Corredor (ampliación)

Se agregó tras revisar la app terminada: funcionaba, pero se veía plana, sin marca y sin estados intermedios. El concepto elegido es "Corredor": la ruta entre la central y el destino ordena la pantalla. Empieza por el solicitante; los cimientos cambian los cuatro roles. Se cuenta aparte.

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-72 | Cimientos visuales: tres niveles de superficie, acento del manual de marca, cifras en monoespaciada, bordes a 3:1 y una sola familia de íconos (RNF-16, RNF-18) | Alta | 8 | 6 |
| HU-73 | Estados de carga con esqueleto, vacío y error con ilustración (RNF-18) | Alta | 5 | 6 |
| HU-74 | Arranque con el logo por capas; despegue, llegada, código y retorno con animación propia y vibración | Media | 8 | 6 |
| HU-75 | Bienvenida de tres pasos (RF-53) | Media | 3 | 6 |
| HU-76 | Inicio, urgencia y seguimiento del solicitante con la ruta como motivo | Alta | 8 | 6 |
| HU-77 | Ajustes: tema con vista previa, texto, contraste, movimiento y modo sencillo (RF-52) | Alta | 8 | 6 |
| HU-78 | Medicamentos disponibles (RF-54) | Media | 5 | 6 |

**Suma del módulo 12: 45 SP.**

## Módulo 13 — Menos realismo (ajuste)

Se agregó antes de la presentación para simplificar la demo. Reemplaza HU-61 y HU-64: se vuela a cualquier hora y el dron llega a la ubicación del solicitante, sin puntos fijos de entrega. Se declara como simplificación frente al RAC 100.220. Se cuenta aparte.

| ID | Historia | Pri | SP | Sprint |
| --- | --- | --- | --- | --- |
| HU-79 | Vuelo a cualquier hora: quitar la regla de luz del día de la decisión y del fallback (RF-44, CU-48) | Alta | 3 | 6 |
| HU-80 | Destino en la ubicación del solicitante: urgencia y plan por GPS o pin, sin puntos de entrega (RU-02, RU-30, RF-45) | Alta | 8 | 6 |
| HU-81 | Generador, pico de urgencias y caos con destinos al azar al alcance de un nodo (RF-36, RF-37, RF-38) | Media | 3 | 6 |

**Suma del módulo 13: 14 SP.**

---

## Incrementos

| Inc. | Sprint | El sistema al cerrar | Funcionalidades |
| --- | --- | --- | --- |
| 1 | 1 | Base: cuentas y flota inicial | OTP, JWT, recuperación, registro de central, alta de drones + `DroneModel` |
| 2 | 2 | Centrales e inventario; mapa de vuelo | Suspensión de centrales, inventario, estados/mantenimiento, geovallas, cuentas institucionales |
| 3 | 3 | Pedidos | Emergencia, estados, cola despachador, planes, alertas, historial solicitante |
| 4 | 4 | Decisión | Elegibilidad al autorizar, prioridad, rutas (sin despegue) |
| 5 | 5 | Vuelo en vivo | Simulación tras carga, WSS, panel operador, mapa solicitante, notificaciones, alerta batería |
| 6 | 6 | MVP presentable | Fallback, frío, código, espera 5 min, retorno, historiales, dashboard, métricas, pruebas, despliegue |

---

## Cronograma (12 semanas)

| Sprint | Semanas (2026) | Foco |
| --- | --- | --- |
| 1 | 1 sep – 14 sep | Arquitectura base, auth, OTP, JWT, central, flota |
| 2 | 15 sep – 28 sep | Perfiles, inventario, suspensión de centrales, geovallas, estados de flota |
| 3 | 29 sep – 12 oct | Pedidos emergencia y programados |
| 4 | 13 oct – 26 oct | Motor de decisión y rutas |
| 5 | 27 oct – 9 nov | Simulación, telemetría, paneles, mapa |
| 6 | 10 nov – 22 nov | Fallback, frío, carga, código, retorno, dashboard, admin, pruebas, cierre |

Semanas del documento original (S1 = 1 sep … S12 = 17 nov) se agrupan de dos en dos en cada sprint.
