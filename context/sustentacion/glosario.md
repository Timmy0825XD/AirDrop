# Glosario

Términos que deben usarse igual en código, UI y sustentación.

| Término | Definición |
| --- | --- |
| AirDrop | Nombre del proyecto y de la app. Logística aérea médica **simulada**. |
| Central (hub) | Lugar con inventario y drones. No es un usuario. Puede despachar o recibir un abastecimiento. |
| Solicitante | Persona civil con documento. Única cuenta de registro público. Pide para su ubicación. |
| Despachador | Profesional de la salud, o persona con capacitación certificada para aprobar solicitudes. Una central, creado por el admin. |
| Operador de flota | Usuario creado por el admin. Flota, geovallas y telemetría de las centrales que tiene asignadas (una o varias). |
| Administrador | Crea y suspende centrales, despachadores y operadores. No despacha ni pide insumos. |
| Tipo de venta | Libre, bajo fórmula médica o control especial. Lo define el ítem de inventario. |
| Receta (imagen) | Foto de la prescripción. Obligatoria solo en venta bajo fórmula. El despachador verifica su contenido al autorizar. |
| Control especial | Medicamento fiscalizado. No se pide ni se despacha con una foto de fórmula. |
| Dispensación | Verificación en la central, información de uso y registro de salida. Ocurre antes del vuelo. |
| Confirmación de carga | El despachador marca que el insumo ya está en el dron asignado; condición para iniciar el vuelo. |
| Código de entrega | Código de un uso; se ingresa en el punto de destino. No hay rol receptor. |
| Espera de entrega | El dron ya está en el destino y aguarda el código (máximo 5 minutos). |
| Retorno con paquete | Si no hay código a tiempo, el dron regresa a la central con la carga. El reingreso depende de la cuarentena. |
| Cuarentena | Revisión al devolver el paquete. Con excursión de temperatura o empaque comprometido no vuelve al inventario. |
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
| Consola de simulación | La web del administrador, en una TV: reloj, eventos, actores simulados, modo caos, línea de tiempo y reinicio. |
| Reloj simulado | La hora de todo el sistema, que puede ir en pausa, x1, x2, x4 u x8. JWT, OTP y login siguen en hora real. |
| Celda de clima | Zona con viento, lluvia o tormenta simulados y una duración. |
| Geovalla temporal | Geovalla con vencimiento que lanza la consola o el modo caos. |
| Cambio de ruta en vuelo | Corredor nuevo desde la posición del dron cuando una zona nueva cruza el tramo que falta. |
| Incidente | Algo que le pasa a un dron en vuelo: falla, choque, pérdida de GPS o enlace, viento sobre el límite. |
| Protocolo | Lo que el sistema decide ante un incidente: seguir, volver a la central o aterrizar de emergencia. |
| Aterrizaje de emergencia | Aterrizar en el punto seguro más cercano, fuera de toda geovalla y tormenta. |
| En tierra fuera de base | Estado del dron que aterrizó de emergencia, hasta que lo rescatan. |
| Actor simulado | Despachador automático, generador de pedidos o receptor simulado. Usa los mismos servicios que una persona. |
| Modo caos | Sorteo de eventos realistas, apagado por defecto. |
| Línea de tiempo | Pasos del flujo publicados en vivo por la sala del radar. |
| OTP | Código de un uso para verificar cuenta. |
| JWT | Token de sesión de la API. |

Conceptos teóricos más largos: [`marco.md`](marco.md).
