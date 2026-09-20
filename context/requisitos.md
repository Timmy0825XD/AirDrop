# Requisitos

Los requisitos de usuario (RU) están en primera persona. De ellos salen los funcionales (RF) y no funcionales (RNF). Trazabilidad hacia historias: [`product-backlog.md`](product-backlog.md). Flujos: [`casos-de-uso.md`](casos-de-uso.md).

---

## Requisitos de usuario

### Solicitante

| ID | Requerimiento |
| --- | --- |
| RU-01 | Registrarme con celular o correo y verificar la cuenta con un código para poder solicitar entregas. |
| RU-02 | Reportar una urgencia: medicamento, ubicación y descripción breve, para atención lo más rápida posible. |
| RU-03 | Ver el estado del pedido: recibido, en evaluación, asignado, pendiente de carga, en vuelo, en espera de entrega, entregado, en retorno, devuelto o rechazado. |
| RU-04 | Ver el dron en un mapa en tiempo real una vez despega. |
| RU-05 | Notificación cuando el dron está por aterrizar, espera el código o cambia el estado del pedido. |
| RU-06 | Si ningún dron puede atender, que el sistema proponga una alternativa (no un rechazo vacío). |
| RU-07 | Generar un código de entrega de un uso para confirmar la recepción en el punto. |
| RU-08 | Consultar el historial de mis pedidos. |
| RU-24 | Ingresar el código de entrega cuando el dron está en el destino (desde mi sesión o una pantalla de confirmación, **sin** rol ni cuenta de receptor). |
| RU-25 | Si el medicamento o insumo lo exige, adjuntar una **imagen de la receta** para poder solicitarlo. |

### Despachador

| ID | Requerimiento |
| --- | --- |
| RU-09 | Registrar la central con correo institucional y verificar con código. |
| RU-10 | Ver pedidos de emergencia asignados a mi central, confirmar stock, ver la receta si aplica y autorizar. |
| RU-11 | Gestionar inventario (existencias, unidades, vencimiento, almacenamiento, si exige receta). |
| RU-12 | Crear un plan de reabastecimiento: suministro, cantidad, frecuencia y fechas. |
| RU-13 | Histórico de misiones de mi central (emergencia y programadas). |
| RU-14 | Marcar un ítem como sensible a temperatura (cadena de frío). |
| RU-15 | Alerta si un pedido de emergencia no se atiende en un tiempo límite. |
| RU-29 | Tras autorizar, ver la **referencia del dron** elegido, colocar el insumo y **marcar que ya está a bordo** para que el dron despegue. |

### Operador de flota

| ID | Requerimiento |
| --- | --- |
| RU-16 | Registrarme y verificar cuenta para el panel de flota. |
| RU-17 | Ver disponibilidad de cada dron: disponible, en misión, en mantenimiento, fuera de servicio. |
| RU-18 | Telemetría detallada en vuelo: posición, altitud, velocidad, batería, payload, temperatura de carga, ping/latencia, fase. |
| RU-19 | Definir y editar geovallas sobre un mapa. |
| RU-20 | Alerta si la temperatura de carga sale de rango. |
| RU-21 | Alerta de batería crítica o falla en misión. |
| RU-22 | Registrar mantenimiento y dejar el dron fuera de servicio para que no se asigne. |
| RU-23 | Dashboard epidemiológico: medicamentos más pedidos y distribución geográfica. |

### Administrador

| ID | Requerimiento |
| --- | --- |
| RU-26 | Aprobar o rechazar el registro de una central nueva. |
| RU-27 | Gestionar cuentas institucionales (despachadores y operadores), incluida suspensión. |
| RU-28 | Métricas: número de misiones, tiempos promedio, incidencias. |

No hay requisitos de un rol **receptor**. La entrega se cierra con el código (RU-07, RU-24).

---

## Requisitos funcionales

| ID | Nombre | Descripción | RU |
| --- | --- | --- | --- |
| RF-01 | Registro de usuario | Cuatro tipos de cuenta (solicitante, despachador, operador, administrador); despachador y operador con correo institucional de la central. | RU-01, 09, 16 |
| RF-02 | OTP | Código de 6 dígitos, un solo uso, 10 min. Correo (institucionales) o SMS/WhatsApp (solicitante). Cuenta activa solo tras verificar. | RU-01, 09, 16 |
| RF-03 | Login JWT | Correo o celular + contraseña; JWT con rol. | — |
| RF-04 | Logout | Invalidar token en cliente; expiración en servidor. | — |
| RF-05 | Recuperar contraseña | Código temporal, 15 min, al correo o celular. | — |
| RF-06 | Aprobación de centrales | Admin aprueba o rechaza antes de operar. | RU-26 |
| RF-07 | Perfil de central | Nombre, tipo (hospital, clínica, farmacia, banco de sangre, vacunación), ubicación, contacto. | RU-09 |
| RF-08 | Inventario | CRUD de existencias: cantidad, vencimiento, flag de cadena de frío, flag de receta requerida. | RU-11, 14, 25 |
| RF-09 | Pedido de emergencia | Medicamento, ubicación GPS o manual, descripción; prioridad alta; imagen de receta si el ítem lo exige. | RU-02, 25 |
| RF-10 | Pedido programado | Plan: suministro, cantidad, frecuencia (única, semanal, quincenal, mensual), fecha de inicio. | RU-12 |
| RF-11 | Motor de elegibilidad | Al **autorizar** el despachador: batería, carga, mantenimiento, clima simulado, ruta sin geovallas. Emergencia > programado. Reserva el dron; **no** inicia el vuelo. | RU-29 |
| RF-12 | Cálculo de rutas | Corredores a altitud fija evitando geovallas (ida y, si aplica, retorno). | RU-19 |
| RF-13 | Simulación y telemetría | Tick **después** de confirmar carga: posición, velocidad, altitud, batería, payload, temperatura, ping, fase; WebSockets. | RU-04, 18 |
| RF-14 | Panel de telemetría | Vista de operador con el snapshot completo en vivo. | RU-18 |
| RF-15 | Seguimiento solicitante | Estado + mapa desde el despegue (ida y retorno). | RU-03, 04 |
| RF-16 | Push | Cambios de estado, llegada inminente, espera de código, retorno, alertas de temperatura o batería. | RU-05, 15, 20, 21 |
| RF-17 | Cadena de frío | Temperatura simulada si aplica; alerta fuera de rango. | RU-14, 20 |
| RF-18 | Fallback multimodal | Alternativa si ningún dron es elegible **en el momento de autorizar**. | RU-06 |
| RF-19 | Código de entrega | Un solo uso; se ingresa con el dron en espera en destino; cierra `entregado`. | RU-07, 24 |
| RF-20 | Gestión de flota | CRUD de drones, estados, `DroneModel` tipo Wingcopter 198. | RU-17, 22 |
| RF-21 | Geovallas | Dibujar, editar, eliminar; restricción obligatoria en rutas. | RU-19 |
| RF-22 | Historial | Filtrado por rol (propios / central / plataforma). | RU-08, 13 |
| RF-23 | Dashboard epidemiológico | Agregados por medicamento, ubicación y fecha. | RU-23 |
| RF-24 | Pedidos sin atender | Alerta al despachador si supera tiempo límite configurable. | RU-15 |
| RF-25 | Usuarios institucionales | Admin: consultar, suspender, reactivar. | RU-27 |
| RF-26 | Métricas de plataforma | Misiones por tipo, tiempo promedio, incidencias. | RU-28 |
| RF-27 | Receta en imagen | Si el ítem exige receta, el pedido no se crea sin imagen; el despachador la consulta al autorizar. Almacenamiento restringido. | RU-25, 10 |
| RF-28 | Confirmación de carga | El despachador ve identificador del dron asignado y marca el insumo a bordo; solo entonces arranca la simulación. El inventario se descuenta en este paso. | RU-29 |
| RF-29 | Espera de código | En destino el dron permanece hasta 5 minutos esperando el código. | RU-24 |
| RF-30 | Retorno con paquete | Si el código no se ingresa en 5 minutos, simular el vuelo de regreso a la central con la carga; pedido `en retorno` y luego `devuelto`. | RU-03, 05 |

---

## Requisitos no funcionales

| ID | Categoría | Nombre | Descripción |
| --- | --- | --- | --- |
| RNF-01 | Seguridad | Hash de contraseñas | bcrypt |
| RNF-02 | Seguridad | Canal cifrado | HTTPS y WSS |
| RNF-03 | Seguridad | RBAC | Cada endpoint verifica rol |
| RNF-04 | Seguridad | Ataques comunes | SQL injection, XSS, CSRF, fuerza bruta; máx. 5 intentos de login y bloqueo temporal |
| RNF-05 | Seguridad | Datos personales y de salud | Ley 1581 de 2012 y Decreto 1377 de 2013; consentimiento explícito; no loguear recetas ni payloads clínicos en texto plano |
| RNF-06 | Seguridad | Archivos | Documentos de registro de central y **imágenes de receta** en almacenamiento con acceso restringido |
| RNF-07 | Rendimiento | API | 95 % de REST < 800 ms en carga normal |
| RNF-08 | Rendimiento | Telemetría | Publicar al menos cada 2 s en vuelo (ida y retorno); en espera de código el snapshot puede ir más espaciado |
| RNF-09 | Disponibilidad | Uptime | 99 % en horario de uso; mantenimientos anunciados ≥ 24 h |
| RNF-10 | Usabilidad | UI | Android e iOS; fuente y contraste razonables |
| RNF-11 | Escalabilidad | Crecimiento | Más centrales/drones/misiones sin romper RNF-07; Postgres vs Redis |
| RNF-12 | Confiabilidad | Reconexión | Reconectar WSS y recuperar último estado |
| RNF-13 | Mantenibilidad | Módulos | Dominios independientes (flota, pedidos, despacho, rutas, geovallas, telemetría) |
| RNF-14 | Compatibilidad | Flutter | Versiones Android/iOS vigentes soportadas por Flutter al desarrollar |
| RNF-15 | Localización | es-CO | Español; fechas, horas y unidades de Colombia |
