# Glosario

Términos que deben usarse igual en código, UI y sustentación.

| Término | Definición |
| --- | --- |
| AirDrop | Nombre del proyecto y de la app. Logística aérea médica **simulada**. |
| Central (hub) | Punto de despacho: hospital, clínica, farmacia, banco de sangre, vacunación. |
| Solicitante | Quien crea el pedido de emergencia (o sigue uno), adjunta receta si aplica e ingresa el código de entrega. |
| Despachador | Usuario institucional de una central: inventario, autorización y confirmación de carga en el dron. |
| Operador de flota | Usuarios de drones, geovallas y telemetría. |
| Receta (imagen) | Foto o captura de la prescripción, obligatoria solo si el ítem del catálogo lo exige. |
| Confirmación de carga | El despachador marca que el insumo ya está en el dron asignado; condición para iniciar el vuelo. |
| Código de entrega | Código de un uso; se ingresa en el punto de destino. No hay rol receptor. |
| Espera de entrega | El dron ya está en el destino y aguarda el código (máximo 5 minutos). |
| Retorno con paquete | Si no hay código a tiempo, el dron regresa a la central con la carga. |
| Pedido de emergencia | Alta prioridad, bajo demanda. |
| Pedido / plan programado | Reabastecimiento con frecuencia y fechas. |
| Misión | Pedido ya asignado (o en proceso de asignación) a un dron y una ruta. |
| Motor de decisión | Evaluación de elegibilidad + prioridad; asigna dron al autorizar, sin despegar. |
| Motor de simulación | Reloj que mueve drones y genera telemetría **después** de confirmar la carga. |
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
