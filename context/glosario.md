# Glosario

Términos que deben usarse igual en código, UI y sustentación.

| Término | Definición |
| --- | --- |
| AirDrop | Nombre del proyecto y de la app. Logística aérea médica **simulada**. |
| Central (hub) | Punto de despacho: hospital, clínica, farmacia, banco de sangre, vacunación. |
| Solicitante | Quien crea el pedido de emergencia (o sigue uno). |
| Despachador | Usuario institucional de una central: inventario y autorización. |
| Operador de flota | Usuarios de drones, geovallas y telemetría. |
| Receptor | Quien confirma la recepción física. |
| Pedido de emergencia | Alta prioridad, bajo demanda. |
| Pedido / plan programado | Reabastecimiento con frecuencia y fechas. |
| Misión | Pedido ya asignado (o en proceso de asignación) a un dron y una ruta. |
| Motor de decisión | Evaluación de elegibilidad + prioridad. |
| Motor de simulación | Reloj que mueve drones y genera telemetría. |
| DroneModel | Plantilla de especificaciones (MVP: Wingcopter 198). |
| Geovalla | Polígono prohibido o restringido para rutas. |
| Corredor | Ruta 2D a una altitud fija. |
| Cadena de frío | Monitoreo de temperatura simulada del compartimento. |
| Fallback multimodal | Alternativa cuando no hay dron elegible (otra central o aviso de traslado convencional). |
| Telemetría | Snapshot en vivo: posición, altitud, velocidad, batería, payload, temperatura, ping, fase. |
| Fase de vuelo | Despegue, transición, crucero, descenso, aterrizaje. |
| OTP | Código de un uso para verificar cuenta. |
| JWT | Token de sesión de la API. |

Conceptos teóricos más largos: [`marco-de-referencia.md`](marco-de-referencia.md).
