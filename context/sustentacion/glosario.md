# Glosario

Términos que deben usarse igual en código, UI y sustentación.

| Término | Definición |
| --- | --- |
| AirDrop | Nombre del proyecto y de la app. Logística aérea médica **simulada**. |
| Central (hub) | Lugar con inventario. No es un usuario. Es de tipo **nodo** (tiene drones y despega) o **ESE** (recibe reabastecimiento, sin drones). |
| Nodo | Central con drones, ubicada fuera del anillo del aeropuerto y lejos de toda zona prohibida. |
| ESE | Empresa Social del Estado: el hospital público de un municipio. En AirDrop, central sin drones. |
| Solicitante | Persona civil con documento. Única cuenta de registro público. Pide para su ubicación. |
| Despachador | Profesional de la salud, o persona con capacitación certificada para aprobar solicitudes. Una central (nodo o ESE), creado por el admin. |
| Operador de flota | Usuario creado por el admin. Flota, geovallas y telemetría de los nodos que tiene asignados (uno o varios). |
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
| DroneModel | Plantilla de especificaciones de un tipo de dron: Colibrí, Garza o Cóndor. |
| Compartimento de frío | Accesorio refrigerado de 2 a 8 °C que se instala en cualquier dron y le resta 1 kg de carga. |
| Geovalla | Polígono prohibido o restringido para rutas que dibuja el operador. |
| Zona legal | Zona del RAC 100 que trae el escenario: aeródromo, prohibida, helipuerto o temporal. Tienen el tamaño de la demo, no el margen completo del RAC 100. No se edita. |
| ARP | Punto de referencia del aeródromo. Desde él se mide el anillo de 1,5 km de la demo. |
| Corredor | Ruta en planta, con un perfil de altura que sigue el terreno entre 60 y 120 m AGL. |
| AGL | Altura sobre el terreno (above ground level). El techo es de 120 m AGL. |
| VMC | Condiciones meteorológicas visuales. Sin ellas (tormenta, niebla) no se vuela. |
| Manifiesto | Documento numerado de cada vuelo: qué lleva, de dónde a dónde y quién autorizó. |
| Identificación remota | Lo que cada dron emite para que se sepa quién es: matrícula, operador, tipo, manifiesto y estado. |
| Enlace C2 | Enlace de mando y control entre el dron y la plataforma. Perderlo es una emergencia. |
| Cadena de frío | Monitoreo de temperatura simulada del compartimento. |
| Fallback multimodal | Alternativa cuando no hay dron elegible (otra central o aviso de traslado convencional). |
| Telemetría | Snapshot en vivo: posición, altitud, velocidad, batería, payload, temperatura, ping, fase. |
| Fase de vuelo | Despegue, transición, crucero, descenso, aterrizaje. |
| Consola de simulación | La web del administrador, en una TV: reloj, eventos, actores simulados, modo caos, línea de tiempo y reinicio. |
| Reloj simulado | La hora de todo el sistema, que puede ir en pausa, x1, x2, x4 u x8. JWT, OTP y login siguen en hora real. |
| Celda de clima | Zona con viento, lluvia, tormenta o niebla simulados y una duración. |
| Restricción temporal | Zona prohibida con motivo y vencimiento (orden público, evento, operativo) que lanza la consola o el modo caos. |
| Cambio de ruta en vuelo | Corredor nuevo desde la posición del dron cuando una zona nueva cruza el tramo que falta. |
| Incidente | Algo que le pasa a un dron en vuelo: falla, choque, pérdida de GPS o enlace, viento sobre el límite. |
| Protocolo | Lo que el sistema decide ante un incidente: seguir, volver al nodo o aterrizar de emergencia. |
| Aterrizaje de emergencia | Aterrizar en el punto seguro más cercano que alcance (nodo o ESE) o, si ninguno, fuera de toda zona y tormenta. |
| En tierra fuera de base | Estado del dron que aterrizó de emergencia, hasta que lo rescatan. |
| Actor simulado | Despachador automático, generador de pedidos o receptor simulado. Usa los mismos servicios que una persona. |
| Modo caos | Sorteo de eventos realistas, apagado por defecto. |
| Línea de tiempo | Pasos del flujo publicados en vivo por la sala del radar. |
| OTP | Código de un uso para verificar cuenta. |
| JWT | Token de sesión de la API. |

Conceptos teóricos más largos: [`marco.md`](marco.md).
