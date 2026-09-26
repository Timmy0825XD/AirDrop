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
| HU-11 | Alta de dron + `DroneModel` Wingcopter 198 | Alta | 8 | 1 |
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

---

## Incrementos

| Inc. | Sprint | El sistema al cerrar | Funcionalidades |
| --- | --- | --- | --- |
| 1 | 1 | Base: cuentas y flota inicial | OTP, JWT, recuperación, registro de central, alta de drones + `DroneModel` |
| 2 | 2 | Centrales e inventario; mapa de vuelo | Aprobación, inventario, estados/mantenimiento, geovallas, cuentas institucionales |
| 3 | 3 | Pedidos | Emergencia, estados, cola despachador, planes, alertas, historial solicitante |
| 4 | 4 | Decisión | Elegibilidad al autorizar, prioridad, rutas (sin despegue) |
| 5 | 5 | Vuelo en vivo | Simulación tras carga, WSS, panel operador, mapa solicitante, notificaciones, alerta batería |
| 6 | 6 | MVP presentable | Fallback, frío, código, espera 5 min, retorno, historiales, dashboard, métricas, pruebas, despliegue |

---

## Cronograma (12 semanas)

| Sprint | Semanas (2026) | Foco |
| --- | --- | --- |
| 1 | 1 sep – 14 sep | Arquitectura base, auth, OTP, JWT, central, flota |
| 2 | 15 sep – 28 sep | Perfiles, inventario, aprobación, geovallas, estados de flota |
| 3 | 29 sep – 12 oct | Pedidos emergencia y programados |
| 4 | 13 oct – 26 oct | Motor de decisión y rutas |
| 5 | 27 oct – 9 nov | Simulación, telemetría, paneles, mapa |
| 6 | 10 nov – 22 nov | Fallback, frío, carga, código, retorno, dashboard, admin, pruebas, cierre |

Semanas del documento original (S1 = 1 sep … S12 = 17 nov) se agrupan de dos en dos en cada sprint.
