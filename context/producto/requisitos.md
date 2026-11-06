# Requisitos

Cada requisito dice qué se exige y por qué. Los ID no se renumeran. Los flujos están en [casos-de-uso.md](casos-de-uso.md). Las historias, en [backlog.md](backlog.md).

Roles: [../app/roles.md](../app/roles.md). Entregas: [../entregas/](../entregas/). Norma: [../legal/](../legal/).

No hay rol receptor. La recepción se cierra con el código (RU-07, RU-24).

## Solicitante

### RU-01 — Registro civil

Nombre, tipo y número de documento, celular de 10 dígitos, correo, contraseña y consentimiento. Documentos: cédula de ciudadanía, cédula de extranjería o PPT.

**Por qué.** Es la única cuenta que se crea sola. El documento identifica a la persona que va a recibir el medicamento. El consentimiento es obligatorio porque el pedido puede llevar datos de salud (Ley 1581 de 2012). No se admite un documento de menor.

**Se cumple cuando.** Falta uno de esos datos, el documento o el celular ya existen, o no hay consentimiento: la cuenta no se crea. Sin OTP válido queda sin activar.

### RU-02 — Urgencia a mi ubicación

Medicamento, ubicación y una descripción breve, con prioridad alta.

**Por qué.** La urgencia civil no es un traslado entre centrales. El destino es la persona, y el despachador todavía no ha autorizado.

### RU-30 — Entrega periódica a mi ubicación

Medicamento, cantidad, calendario y hora. El calendario se arma como en un calendario de teléfono:

- **Días de la semana**, cada 1 a 4 semanas (por ejemplo, todos los jueves, o martes y jueves cada 15 días).
- **Un día del mes** (por ejemplo, el 15; si el mes es más corto, el último día).
- **Fechas sueltas**, hasta 30.

Termina en una fecha o después de un número de entregas, nunca las dos. Un plan dura como máximo **3 meses** desde su inicio y, si es bajo fórmula, no pasa de la vigencia de la fórmula. Cada entrega tiene una **franja de 1 hora**, que empieza a una hora en punto entre las 07:00 y las 17:00 (la última cierra a las 18:00). Una entrega que empezaría en menos de 2 horas no se agenda: no da tiempo de avisar ni de preparar la carga. Antes de crear el plan, la app muestra las fechas y horas que van a quedar.

Quien lo creó puede cambiar el calendario o la hora: las entregas que todavía no tienen dron se rehacen con la regla nueva y las que ya salieron no cambian. Puede cancelarlo cuando quiera: el plan queda cancelado y las entregas que siguen en recibido también. Las que ya salieron de recibido no se revierten.

Cada entrega a una persona pide confirmación: el día anterior le llega el aviso y, si no confirma 2 horas antes de la franja, la entrega queda omitida y el dron no sale. Hasta 2 horas antes puede omitir o mover una sola entrega. El despachador autoriza y carga desde 2 horas antes hasta el cierre de la franja. Si la franja cierra sin despegue, la entrega queda vencida y aplica RF-18. Los avisos llegan a la bandeja de la app y al correo.

**Por qué.** Hay civiles en zonas de difícil acceso que necesitan el mismo insumo cada semana, quincena o mes. No se modela como un abastecimiento de central.

### RU-25 — Fórmula cuando el ítem la exige

Si el tipo de venta es bajo fórmula, la imagen es obligatoria y el documento de la cuenta es el del paciente. El control especial no se pide por este canal.

**Por qué.** El Decreto 2200 prohíbe dispensar sin fórmula lo que la etiqueta marca como venta bajo fórmula, y prohíbe entregar a una persona distinta de la prescrita. El control especial tiene otro régimen.

### RU-03 — Ver el estado

Estados: agendado, por confirmar, recibido, en evaluación, asignado, pendiente de carga, en vuelo, en espera de entrega, entregado, en retorno, devuelto, rechazado, reasignado, omitido, vencido o cancelado. Agendado y por confirmar son de las entregas de un plan antes de que quien recibe confirme (RU-30); omitido es la entrega que no se confirmó o que quien recibe dejó pasar; vencido es la que no despegó al cerrar su franja. Cancelar un plan deja en cancelado las entregas que todavía no tienen dron.

**Por qué.** Autorizar no es despegar. El solicitante tiene que distinguir “ya hay dron reservado” de “ya va en el aire”.

### RU-04 — Mapa en vuelo

Ver el dron en el mapa desde que despega, en la ida y en el retorno.

### RU-05 — Avisos

Aviso cuando el dron está por aterrizar, cuando espera el código o cuando cambia el estado. Las entregas programadas avisan el día anterior para confirmar, si puede faltar stock, cuando despegan (con la hora estimada de llegada) y si una entrega no sale. Esos avisos quedan en la bandeja de la app y llegan al correo, sin el nombre del medicamento.

### RU-06 — Alternativa, no un rechazo vacío

Si ningún dron puede salir, el sistema propone otra central o un traslado convencional.

**Por qué.** El problema del proyecto es la distancia, no un “no hay”.

### RU-07 y RU-24 — Código de un uso

El solicitante genera el código y lo ingresa cuando el dron está en su ubicación. La pantalla de confirmación no crea una cuenta de receptor.

**Por qué.** Alguien tiene que acusar recibo. Un rol receptor duplicaría a la persona que ya pidió.

### RU-08 — Historial propio

Sus pedidos, por fecha y estado final.

## Despachador

### RU-09 — Una central asignada

Entra a la central que el administrador le asignó. No se registra solo y no abre otra central.

**Por qué.** Quien aprueba salidas es un profesional o una persona con capacitación certificada. Esa cuenta no puede nacer en un formulario público.

### RU-10 — Cola de emergencia

Ve la urgencia dirigida a su central, el stock, la fórmula si el destino es una persona, y autoriza o rechaza con motivo.

Una urgencia de un solicitante no aparece a la vez en todas las centrales. El sistema ordena las centrales activas que tienen el lote, un corredor libre y batería para ida, regreso y reserva (RF-11 y RF-12): primero las que tienen un dron elegible y, dentro de cada grupo, la que llega antes por su corredor. La urgencia entra solo a la cola de la primera. Si no la autoriza a tiempo, también entra a la cola de la siguiente, sin salir de la primera, y la autoriza la que lo haga antes. Ese tiempo de ventaja es lo que la central ahorra frente a la siguiente, con un mínimo de 1 minuto y un máximo de 3.

El despachador puede declinarla ("No puedo atenderla": sin dron, sin personal o sin lote). Entonces la ve la siguiente central en ese instante. Rechazar con motivo queda para una fórmula que no cumple, y cierra el pedido. Si ninguna central puede llegar, o todas declinan, el pedido pasa a traslado convencional (RF-18). Una urgencia entre centrales (RU-31) ya trae su central de origen y no se escalona.

**Por qué.** Si la urgencia la toma la primera central que la ve, una central dos o tres veces más lejos puede ganarle a la cercana solo porque estaba mirando la cola. La ventaja medida en minutos de vuelo deja a la cercana atender primero y no hace esperar al paciente más de lo que ella ahorra.

### RU-11 y RU-14 — Inventario

Cantidad, lote, vencimiento, tipo de venta y si exige frío.

**Por qué.** Sin lote no hay remisión ni dispensación trazable. El tipo de venta decide si hace falta fórmula. El frío decide si el trayecto se monitorea.

### RU-12 — Abastecimiento programado desde otra central

Pide a otra central un plan: suministro, cantidad, calendario y hora. El destino es su central. El calendario, la franja, los topes, el cambio y la cancelación son los de RU-30. Una central siempre tiene personal, así que sus entregas no piden confirmación.

### RU-31 — Urgencia de abastecimiento

Pide a otra central un insumo que a la suya le falta, con prioridad alta. El destino es su central.

**Por qué.** RU-12 y RU-31 no los crea el solicitante. Los crea el despachador que necesita el stock. Quien suelta el insumo es el despachador de la otra central.

### RU-29 — Carga antes del vuelo

Después de autorizar ve el identificador del dron, deja la constancia que corresponda (información de uso si el destino es una persona; remisión si el destino es una central) y marca la carga. Solo entonces despega.

**Por qué.** Autorizar reserva. Despegar con la bodega vacía rompería la dispensación y la remisión.

### RU-13 — Histórico de la central

Misiones de emergencia y programadas de su central.

### RU-15 — Alerta de urgencia sin atender

Si una urgencia en su cola lleva más de 5 minutos en recibido, al abrir la cola ve el aviso. El aviso no autoriza la salida.

## Operador de flota

### RU-16 — Centrales asignadas

Entra con la cuenta que creó el administrador y ve una o varias centrales. No se registra solo.

**Por qué.** El técnico no está atado a un solo sitio. El despachador sí, porque el inventario y la firma de salida son de una central.

### RU-17 — Estado del dron

Disponible, en misión, en tierra fuera de base, en mantenimiento o fuera de servicio. En tierra fuera de base es el dron que aterrizó de emergencia lejos de su central (RF-34); cuando se recupera pasa a mantenimiento.

### RU-18 — Telemetría

Posición, altitud, velocidad, batería, carga, temperatura, latencia y fase.

### RU-19 — Geovallas

Dibujar, editar y borrar polígonos. Toda ruta nueva los respeta.

### RU-20 y RU-21 — Alertas de vuelo

Temperatura fuera de rango. Batería crítica, falla o incidente, con el protocolo que aplicó el sistema (RF-34).

### RU-22 — Mantenimiento

Registrar el motivo y dejar el dron fuera de asignación.

### RU-23 — Dashboard

Medicamentos más pedidos y zona, en agregados. Sin identificar personas. Lo dice [../legal/datos.md](../legal/datos.md).

## Administrador

### RU-26 — Centrales

Crea la central (nombre, tipo, ubicación, contacto) y puede suspenderla. No hay alta pública.

**Por qué.** Si el despachador no se autoregistra, la central tampoco puede nacer de su registro. Suspenderla la saca de despacho y de pedido.

### RU-27 — Cuentas institucionales

Crea despachadores (una central, correo institucional) y operadores (una o varias centrales, correo institucional). Puede suspenderlos y reactivarlos. Esas cuentas no pasan por OTP de registro público.

### RU-28 — Métricas

Número de misiones, tiempo promedio e incidencias, incluidos los retornos sin entrega.

### RU-32 — Consola de simulación

En la web, sobre el mapa del radar y en la misma pantalla (una TV), maneja el reloj simulado, lanza eventos sobre un dron, una zona o una central, enciende el despachador automático y el modo caos, sigue la línea de tiempo y las alertas pendientes, y reinicia el escenario. No crea pedidos a mano, no autoriza ni pilotea: los eventos los resuelve el sistema con sus propias reglas.

**Por qué.** Mostrar drones volando no demuestra nada. La consola pone al sistema frente a situaciones realistas (clima, fallas, choques, una central caída) y deja ver en vivo cómo decide, mientras otras personas usan la app en su celular.

## Funcionales

### RF-01 — Registro

El registro público solo crea solicitantes, con los datos de RU-01. Despachador y operador los crea el administrador. La cuenta de administrador inicial no sale de ese formulario.

**Por qué.** Mezclar el alta pública con quien aprueba medicamentos deja la red sin control de la central.

### RF-02 — OTP del solicitante

Seis dígitos, un uso, 10 minutos, al correo. El celular no recibe ese código. La cuenta civil queda activa solo después. Si intenta entrar sin verificar, se envía un código nuevo al correo.

### RF-03 — Sesión

Correo y contraseña. El token lleva el rol. Una cuenta sin verificar no abre sesión: recibe un código nuevo en el correo.

### RF-04 — Cierre de sesión

El cliente deja de usar el token. El servidor lo considera vencido al expirar.

### RF-05 — Recuperar contraseña

Código de 15 minutos al correo de la cuenta. Si el correo no existe, el mensaje no lo revela.

### RF-06 y RF-07 — Central

El administrador la crea con nombre, tipo (hospital, clínica, farmacia, banco de sangre o vacunación), ubicación y contacto, y puede suspenderla.

### RF-08 — Inventario

Alta, edición y baja con cantidad, lote, vencimiento, frío y tipo de venta: libre, bajo fórmula o control especial.

### RF-09 — Emergencia

La crea el solicitante (destino: su ubicación) o el despachador que necesita stock (destino: su central, origen: otra). Prioridad alta. Si el destino es una persona y el ítem es bajo fórmula, exige imagen y documento coincidente. Control especial: no se crea.

### RF-10 — Programado

Suministro, cantidad, calendario (días de la semana cada 1 a 4 semanas, un día del mes o fechas sueltas) con fin por fecha o por número de entregas, y la hora de la franja de 1 hora (en punto, de 07:00 a 17:00). El destino es la ubicación del solicitante o la central que pide el abastecimiento. Máximo 3 meses y, bajo fórmula, no más que su vigencia. Las entregas que empezarían en menos de 2 horas no se agendan. El plan guarda la regla y crea todas sus entregas al crearse; cambiar la regla rehace las que no tienen dron. Los planes anteriores (frecuencia única, semanal, quincenal o mensual con 8 semanas) siguen valiendo: su franja es todo el horario operativo y se pueden extender otras 8 semanas. El despachador ve el día agrupado por franja: si la entrega está confirmada, si hay stock, si la fórmula sigue vigente y hasta cuándo tiene que despegar para llegar antes del cierre. Si en una franja ya hay más entregas que drones en la central, el plan se crea igual y lo avisa.

### RF-11 — Elegibilidad

Al autorizar: batería, carga, mantenimiento, clima simulado y ruta sin geovallas. La emergencia gana el dron si compite con un programado. Reserva el dron y no inicia el vuelo.

La batería se evalúa con la misma cuenta del simulador: ida y regreso por el corredor (8 % de fases verticales por tramo más el crucero) y aterrizar todavía con la reserva crítica del 20 %. Con la batería llena, el Wingcopter 198 llega hasta **35,2 km** de ida. Más lejos, el dron no es elegible.

La batería es la de cada dron: al volver guarda con cuánta llegó y en tierra recarga 1,5 % por minuto (de 0 a 100 % en algo más de una hora). Un dron que acaba de volver puede no alcanzar para otra misión larga, y entonces sale otro. El vuelo arranca con esa batería.

Entre los drones que pueden cumplir, sale el que lleva más tiempo en tierra (el que nunca ha volado, primero). Si empatan, el de más batería. Así la flota se alterna y no vuela siempre el mismo.

El clima simulado (RF-32) también decide: un dron no es elegible si su corredor cruza una tormenta, o si en algún tramo el viento sostenido pasa de **15 m/s** o las ráfagas de **20 m/s**. La batería se cuenta con el viento de cada tramo.

**Por qué.** Los 110 km del modelo son el alcance total en crucero. Si la ida y el regreso los consumen enteros, no queda batería para despegar y aterrizar ni reserva: el dron se apagaría volviendo.

Cada decisión queda explicada en el pedido: qué centrales miró el motor, si tenían lote y corredor, cuántos minutos de vuelo y cuánta batería pedía la misión, y qué pasó con cada dron (elegido, elegible o descartado con su motivo). El despachador que puede abrir el pedido la consulta. No guarda datos clínicos.

### RF-12 — Ruta

Corredor a altitud fija, de ida y de retorno si hace falta, sin cruzar geovallas.

El corredor es el camino más corto que pasa a **150 m o más** del borde de toda geovalla. Si la línea recta cumple, es la línea recta. Si no, el planificador infla cada geovalla con ese margen y busca el camino más corto por sus esquinas (grafo de visibilidad con A*, un Dijkstra guiado hacia el destino), así esquiva varias geovallas seguidas o una cóncava. El margen no se exige a la central ni al destino: un destino a 100 m de una geovalla, pero fuera de ella, es válido. Si no hay camino, el dron no es elegible; si el camino existe pero es largo, lo descarta la batería (RF-11).

Para rutas, una geovalla temporal vigente o una tormenta (RF-32, RF-36) cuentan igual que una geovalla del operador. Si una de esas zonas aparece con el dron en el aire y cruza el tramo que falta, la ruta cambia en vuelo (RF-33).

El regreso se planea al salir de destino con las geovallas vigentes. Si una geovalla nueva bloquea la ruta, la rodea. Solo si el dron o la central quedaron dentro de una geovalla nueva, o la central quedó encerrada, el regreso la cruza: tiene que volver igual, y queda registrado.

### RF-13 y RF-14 — Telemetría

El tick empieza después de confirmar la carga: posición, velocidad, altitud, batería, carga, temperatura, latencia y fase, por WebSocket. El operador ve ese paquete en vivo.

### RF-15 — Seguimiento del solicitante

Estado y mapa desde el despegue, ida y retorno. No antes: todavía no hay vuelo.

### RF-16 y RF-24 — Avisos

Cambios de estado, llegada, espera de código, retorno, temperatura, batería y urgencia quieta más de 5 minutos en recibido. El aviso de la cola se calcula al abrirla. Los avisos de las entregas programadas (confirmar, abastecimiento que llega o que hay que despachar, stock que puede faltar, despegue con hora de llegada y entrega omitida o vencida) se guardan en una bandeja por cuenta y se mandan al correo; si el correo falla, el aviso igual queda.

### RF-17 — Frío

Si el ítem lo exige, la temperatura simulada se compara con el rango en ida, espera y retorno. Fuera de rango: alerta, y la cuarentena de [../entregas/productos.md](../entregas/productos.md).

El rango es **2–8 °C** para todo ítem con frío. La carga viaja estable alrededor de 5 °C. Uno de cada diez vuelos con frío (`COLD_CHAIN_FAILURE_RATE`, 10 % por defecto) sufre una falla en un momento al azar de la ida: desde ahí la carga se calienta y sale de rango en unos dos minutos, y sigue caliente en la espera y en el retorno. La alerta sale una vez por pedido y queda marcada en él. Tras una entrega el dron vuelve vacío y ya no se mide. La consola o el modo caos también pueden provocar la falla de la refrigeración en un vuelo con frío (RF-34); desde ahí sigue la misma cuenta.

### RF-18 — Fallback

Si al autorizar ningún dron sirve, hay otra central con stock o un aviso de traslado convencional. El estado es `reasignado`, no un rechazo mudo.

Depende del servicio:

| Servicio | Sin dron elegible en la central que autoriza |
| --- | --- |
| Urgencia a una persona | Pasa a la central activa que llega antes por su corredor y tiene el lote y un dron elegible. Queda `reasignado` y entra primero en su cola. |
| Urgencia entre centrales | Igual, con otra central de origen. Nunca la central que pidió. |
| Programado | Sigue en recibido y se reintenta solo cada 15 minutos mientras el siguiente intento caiga dentro de la franja. Si la franja cierra sin despegue, queda vencido, suelta el dron si ya estaba reservado y busca otra central como una urgencia. Esa central autoriza sin la franja original. |

Un pedido se reasigna **una sola vez**. Si la central que lo recibe tampoco puede, o si ninguna central sirve, queda `reasignado` como **traslado convencional**: es final, ningún dron despega y quien pidió ve hasta tres centrales con el insumo (nombre, dirección, contacto y distancia). La central que recibe un pedido reasignado verifica la fórmula otra vez, y puede autorizarlo o rechazarlo.

### RF-19 y RF-29 — Código y espera

Un solo uso. Se ingresa con el dron en destino. La espera dura 5 minutos. Un código válido cierra `entregado`; el dron se queda 1 minuto más (fase `unloading`) para que retiren el insumo y después despega de regreso. Con el quinto código equivocado el código se bloquea y el dron vuelve en ese momento con el paquete, sin esperar el resto de los 5 minutos.

**Por qué.** Cinco minutos alcanzan para acusar recibo en el punto sin dejar el paquete esperando una ausencia larga. Pasado ese tiempo, el insumo no se queda en campo.

### RF-20 — Flota

Alta y estado de drones sobre el modelo Wingcopter 198. Un dron en misión no cambia de estado hasta cerrarla, salvo por un incidente (RF-34): pasa a en tierra fuera de base o a fuera de servicio.

### RF-21 — Geovallas

Crear, editar y borrar. Una ruta que las cruza, o que pasa a menos de 150 m de su borde, no es válida.

### RF-22 — Historial

El solicitante ve lo suyo. El despachador, lo de su central. El administrador, la plataforma.

### RF-23 — Dashboard

Conteos por medicamento, zona y fecha. Sin identificadores de persona.

La zona es una celda de unos 1 km (0,01°) con al menos 3 pedidos; una celda con menos no se muestra. Los traslados cuentan por central de destino.

### RF-25 — Cuentas institucionales

Crear, listar, suspender y reactivar. El despachador queda en una central. El operador, en una o varias.

### RF-26 — Métricas

Misiones por tipo, tiempo promedio e incidencias.

Cada KPI trae meta y semáforo (verde, ámbar, rojo) y se compara con el periodo anterior de la misma duración (por defecto, los últimos 30 días):

| Grupo | KPI | Verde | Ámbar |
| --- | --- | --- | --- |
| Resultados | Entregas exitosas (entregados / cerrados) | ≥ 90 % | ≥ 75 % |
| Resultados | Urgencia de pedida a entregada | ≤ 30 min | ≤ 45 min |
| Resultados | Urgencia de pedida a autorizada | ≤ 10 min | ≤ 15 min |
| Oportunidades | Demanda sin atender (rechazos y traslado convencional) | ≤ 5 % | ≤ 10 % |
| Oportunidades | Urgencias que esperaron más de 5 min | 0 | ≤ 2 |
| Fallas | Retornos sin entrega | ≤ 5 % | ≤ 10 % |
| Fallas | Alertas de frío | 0 | 1 |
| Fallas | Unidades en cuarentena | 0 | ≤ 5 |
| Fallas | Batería crítica o falla de dron | 0 | 1 |
| Fallas | Códigos bloqueados | 0 | ≤ 2 |
| Fallas | Pedidos reasignados a otra central | ≤ 10 % | ≤ 20 % |
| Deficiencias | Uso de la flota (tiempo en misión / tiempo disponible) | 30–80 % | 15–90 % |
| Deficiencias | Centrales sin dron disponible | 0 | 1 |

Sin meta, solo informativos: misiones, unidades entregadas, km volados, de autorizada a cargada, duración de la ida, drones en mantenimiento y stock que vence en 30 días.

### RF-27 — Fórmula

Hacia una persona y en venta bajo fórmula: sin imagen, o con documento distinto al del paciente, el pedido no se crea. Al autorizar, el despachador verifica la lista de [../entregas/persona.md](../entregas/persona.md). Si no cumple, no autoriza. La imagen tiene acceso restringido. Entre centrales no hay fórmula de paciente.

### RF-28 — Confirmación de carga

El despachador ve el dron asignado. Si el destino es una persona, registra la información de uso y la salida. Si el destino es una central, registra la remisión. Marca la carga, se descuenta el lote que vence primero y empieza la simulación.

### RF-30 — Retorno

Sin código a los 5 minutos: vuelo de regreso, estados `en retorno` y luego `devuelto`. El reingreso sigue [../entregas/productos.md](../entregas/productos.md). En un traslado recibido correctamente, el stock entra en la central de destino, no vuelve al origen.

### RF-31 — Reloj simulado

Un solo reloj para todo el sistema, también para la app: vuelos, batería y recarga en tierra, los 5 minutos del código, la cadena de frío, las franjas y los avisos de los programados, los reintentos, el escalonamiento de urgencias (RU-10), el mantenimiento y las métricas. Velocidades: **pausa, x1, x2, x4 y x8**. Las cambia el administrador desde la consola (RU-32).

La hora simulada es la hora en que se fijó la velocidad, más el tiempo real transcurrido por la velocidad. Al cambiar de velocidad se toma la hora simulada de ese momento como punto de partida. En pausa no avanza: los drones se quedan quietos en el aire y las esperas no corren. El tick sigue cada 2 s reales (RNF-08); a x8 cada tick avanza 16 s simulados. El estado del reloj vive en Redis y se publica por el socket, para que la web y la app muestren cuentas regresivas con esa hora.

**No se aceleran:** la expiración del JWT, los OTP, el bloqueo por intentos de login ni el envío de correos. Son seguridad, no simulación.

Al reiniciar el escenario (RF-40) el reloj vuelve a la hora real, a x1.

**Por qué.** Un vuelo de 15 minutos no cabe en una demostración. Si solo se aceleraran los vuelos, a x8 el dron llegaría en dos minutos y se quedaría cinco minutos reales esperando el código. Un reloj único mantiene coherentes todas las reglas.

### RF-32 — Clima simulado

El clima son celdas: un círculo en el mapa (centro y radio), con un tipo, una intensidad y una duración en hora simulada. Las crea la consola (RU-32) o el modo caos (RF-38); no hay datos de clima reales.

| Tipo | Efecto |
| --- | --- |
| Viento | Dirección y velocidad. Solo cuenta la parte del viento a lo largo del tramo: en contra, la velocidad sobre el suelo es la del dron menos esa parte; a favor, más. El crucero gasta por tiempo en el aire, así que por km gasta en la proporción velocidad en el aire / velocidad sobre el suelo (10 m/s en contra a 150 km/h: 114 km/h y 1,32 veces el consumo). Sobre 15 m/s sostenidos o 20 m/s en ráfagas no se vuela |
| Lluvia | Se vuela, con un 10 % más de consumo en crucero |
| Tormenta | Zona no volable mientras dure: cuenta como geovalla para rutas (RF-12) |

Al autorizar, el motor de decisión mira el clima del corredor de ida y del regreso por el mismo camino (RF-11). La batería se cuenta en km equivalentes: el crucero con viento en contra cuesta como uno más largo. En vuelo, una tormenta que cruza el tramo que falta cambia la ruta (RF-33), y un viento sobre el límite donde va el dron es un incidente (RF-34). Mientras ese protocolo no exista, se avisa y el dron sigue. Una tormenta no impide crear un pedido con destino bajo ella: lo que no deja es volar hasta que pase. Al vencer, la celda desaparece sola y la línea de tiempo lo cuenta.

**Por qué.** El alcance ya pedía clima simulado en la decisión, y estaba fijo en "se puede volar". Los límites de viento (15 m/s sostenido, 20 m/s en ráfagas) son los que publica un distribuidor del Wingcopter 198; la página del fabricante solo dice que resiste vientos fuertes ([../sustentacion/fuentes.md](../sustentacion/fuentes.md)).

### RF-33 — Cambio de ruta en vuelo

Si con el dron en el aire aparece una zona (geovalla del operador, geovalla temporal o tormenta) que cruza el tramo que falta, el planificador traza un corredor nuevo desde la posición actual hasta el mismo destino, con las reglas de RF-12. Si la batería alcanza para terminar con la reserva del 20 %, el dron lo sigue. Si no, corre RF-34 con el protocolo de volver o aterrizar. Si el dron quedó dentro de la zona nueva, sale por el camino más corto y queda registrado.

La ruta vieja se guarda y la consola la muestra punteada debajo de la nueva. El cambio queda en la línea de tiempo (RF-39) y avisa al operador.

**Por qué.** Antes una geovalla nueva solo afectaba la ruta siguiente. Con clima y zonas temporales, dejar el corredor viejo haría volar al dron dentro de una tormenta.

### RF-34 — Incidentes y protocolos

Un incidente es algo que le pasa a un dron en vuelo. Lo lanza la consola sobre un dron (RU-32), lo sortea el modo caos (RF-38) o lo detecta el reloj de vuelo (viento sobre el límite, batería crítica). Cada uno se guarda con su tipo, gravedad, posición, protocolo y resultado.

| Incidente | Efecto | Protocolo |
| --- | --- | --- |
| Batería que se degrada | Sube el consumo | Según alcance (abajo) |
| Falla de 1 motor | Vuelo degradado: más consumo, menos velocidad. El 198 tiene 8 motores | Según alcance |
| Falla de 2 motores | — | Aterrizaje de emergencia |
| Pérdida de GPS, leve | Sigue con el sistema de posición de respaldo | Seguir, con alerta |
| Pérdida de GPS, grave | Sin posición confiable | Aterrizaje de emergencia |
| Pérdida de enlace | La telemetría queda marcada sin enlace | Volver a la central (procedimiento de enlace perdido) |
| Falla de la refrigeración | La carga con frío se calienta (RF-17) | Seguir; alerta de frío y cuarentena |
| Choque leve (ave u obstáculo) | Sube el consumo | Según alcance |
| Choque grave | — | Aterrizaje de emergencia |
| Dron perdido | Sin rastro | El dron queda fuera de servicio |
| Viento sobre el límite | — | Volver a la central o, si no alcanza, aterrizaje de emergencia |

**Según alcance**, con la misma cuenta de batería de RF-11 y el efecto ya aplicado:

1. Si termina la misión (llegar al destino y volver) con la reserva del 20 %: sigue.
2. Si no, pero alcanza a volver a la central con la reserva: vuelve con el paquete.
3. Si tampoco: aterrizaje de emergencia en el punto más cercano fuera de toda geovalla y tormenta.

De regreso, el paso 1 es llegar a la central.

**Después del incidente:**

- **Aterrizaje de emergencia:** el dron queda en tierra fuera de base. Tras el tiempo de rescate simulado vuelve a su central y pasa a mantenimiento. El paquete se recupera con él y queda en cuarentena: no vuelve al stock.
- **Choque grave o dron perdido:** el dron queda fuera de servicio y el paquete se da por perdido.
- **Vuelta a la central con el paquete:** al aterrizar aplica la cuarentena de [../entregas/productos.md](../entregas/productos.md).
- **Misión que no llega a su destino:** el pedido sigue RF-35.

Todo incidente avisa al operador de esas centrales, sale en la línea de tiempo (RF-39) y cuenta en las métricas (RF-26). Quien pidió ve el cambio de estado, no el detalle técnico.

**Por qué.** Antes el aviso era la única respuesta a una falla. Un sistema autónomo tiene que decidir qué hace el dron, con reglas que se puedan explicar. Las de aquí son las de la operación real de drones de entrega: degradar, volver o aterrizar en un lugar seguro.

### RF-35 — Volver a despachar tras un incidente

Si un incidente impide que la misión llegue a su destino:

| Servicio | Qué pasa |
| --- | --- |
| Urgencia (a una persona o entre centrales) | Vuelve al motor de decisión en ese momento, con prioridad de emergencia (RF-11): un dron de la misma central o de otra con el lote. Queda `asignado` → `pendiente de carga` con el dron nuevo y **hay que confirmar la carga otra vez** (RF-28); el lote se descuenta en esa central. Si ninguna puede, aplica RF-18 |
| Programado | Si el siguiente intento cae dentro de la franja, vuelve a recibido y se reintenta como en RF-18. Si no, queda vencido y aplica RF-18 |

El pedido no tiene un estado nuevo: la misión fallida guarda el incidente y el pedido sigue su camino normal con otro dron. Un pedido reasignado por RF-18 se sigue reasignando una sola vez.

**Por qué.** La urgencia es del paciente, no del dron que se cayó. Volver a pasar por la carga mantiene la regla de que ningún dron despega sin el insumo confirmado.

### RF-36 — Eventos de entorno

Los lanza la consola (RU-32) o el modo caos (RF-38), cada uno con una duración en hora simulada:

- **Geovalla temporal:** un polígono con vencimiento (por ejemplo, un evento aéreo), de 5 a 240 minutos simulados. Mientras dure cuenta como geovalla (RF-12, RF-21): no puede cubrir una central y puede cambiar rutas en vuelo (RF-33). Al vencer desaparece sola y la línea de tiempo lo cuenta. La consola puede levantarla antes, pero no toca las geovallas del operador, que no vencen.
- **Central sin energía:** mientras dure, no autoriza ni confirma cargas y sus drones no son elegibles. Sus urgencias pasan a la siguiente central como si hubiera declinado (RU-10). Sus programados se reintentan dentro de la franja (RF-18). Los drones en el aire que vuelven a ella aterrizan igual.
- **Pico de urgencias:** el generador de RF-37 crea varias urgencias seguidas en una zona.
- **Nadie retira el paquete:** en un pedido del receptor simulado, el código no se ingresa y corre RF-30.

### RF-37 — Actores simulados

Para la demostración híbrida (personas reales con la app y el sistema mostrando el flujo solo) hay tres actores. Llaman a **los mismos servicios** que una persona, sin atajos:

- **Despachador automático.** La consola lo enciende o lo apaga. Encendido, en cualquier central activa autoriza y confirma la carga de cualquier pedido, de una persona real o generado, unos segundos simulados después de que le toca. Con fórmula, da la verificación por cumplida. La traza del pedido dice que lo autorizó el despachador automático. Apagado, lo hace un despachador real en la app.
- **Generador de pedidos.** Crea urgencias y programados de solicitantes simulados (cuentas marcadas como simuladas, sin datos de personas reales), con destinos dentro de las zonas del MVP, fuera de geovallas y con insumos que alguna central tiene en stock.
- **Receptor simulado.** En los pedidos generados, ingresa el código a tiempo o deja vencer los 5 minutos, con cierta probabilidad.

**Por qué.** En la presentación no siempre hay alguien en cada rol. Si los actores usan los mismos servicios, lo que se ve en la TV es el motor real decidiendo, no una animación.

### RF-38 — Modo caos

Interruptor de la consola, **apagado por defecto**. Encendido, sortea eventos del catálogo de RF-32, RF-34 y RF-36 con pesos realistas: tormentas más probables en la tarde simulada, choques raros y fallas según las horas de vuelo. Tiene tres intensidades: baja, media y alta. Cada evento sale en la línea de tiempo marcado como caos.

### RF-39 — Línea de tiempo y alertas pendientes

El sistema publica por la sala `radar` del socket cada paso del flujo:

- pedido creado;
- decisión, con la explicación de RF-11 (qué dron eligió y por qué descartó a los otros);
- asignado;
- carga confirmada;
- despegue;
- alerta;
- incidente y protocolo;
- cambio de ruta;
- entrega o retorno;
- cada acción de la consola.

Las últimas se guardan en Redis con un tope, para que una recarga no las pierda. Las alertas abiertas tienen posición: la consola las lista y las enfoca en el mapa hasta que se resuelven. No lleva datos de personas ni el medicamento de una entrega a una persona.

### RF-40 — Acceso a la consola y reinicio

`/control/*` es solo para el administrador y existe solo si el backend arranca con `CONTROL_ENABLED`; en producción va apagado. Cada acción queda en la línea de tiempo.

**Reiniciar el escenario:**

- Borra los pedidos, incidentes, celdas de clima, geovallas temporales y eventos de la demostración.
- Deja la flota y el stock de demostración como en la semilla.
- Apaga el modo caos.
- Devuelve el reloj a la hora real, a x1.

Las cuentas de las personas reales no se borran.


## No funcionales

| ID | Exigencia | Por qué |
| --- | --- | --- |
| RNF-01 | Contraseña con bcrypt | No guardar la clave en claro |
| RNF-02 | HTTPS y WSS | El canal lleva datos de salud y la posición del vuelo |
| RNF-03 | Cada endpoint comprueba el rol | El operador no abre una fórmula; el solicitante no autoriza |
| RNF-04 | Tope de 5 intentos de login y bloqueo temporal. Sin SQL armado en texto ni XSS abierto. Cambiar el correo pide la contraseña actual y un código al correo nuevo; el anterior recibe un aviso | Evita adivinar la clave a fuerza, y que un error de tipeo o un teléfono prestado dejen a alguien sin su cuenta |
| RNF-05 | Consentimiento explícito. La fórmula no va a logs y solo la ve el despachador que autoriza. El dashboard no identifica | [../legal/datos.md](../legal/datos.md) |
| RNF-06 | La imagen de la fórmula se guarda con acceso restringido | Es dato sensible, no un adjunto público |
| RNF-07 | 95 % de las peticiones REST por debajo de 800 ms en carga normal | La cola de urgencia no puede esperar al tablero |
| RNF-08 | Telemetría al menos cada 2 s **reales** en vuelo, sea cual sea la velocidad del reloj simulado (RF-31). En la espera del código puede ir más espaciada | En crucero el mapa tiene que moverse. En el punto, el dato que importa es el código |
| RNF-09 | 99 % en horario de uso. Un mantenimiento se anuncia con al menos 24 h | |
| RNF-10 | Android e iOS, texto y contraste legibles | |
| RNF-11 | Más centrales, drones y misiones sin romper RNF-07. Lo durable va a Postgres. Lo vivo, a Redis | |
| RNF-12 | Si el socket se cae, reconecta y muestra el último estado | |
| RNF-13 | Módulos separados: flota, pedidos, despacho, rutas, geovallas, telemetría | |
| RNF-14 | Versiones de Android e iOS que Flutter soporte al desarrollar | |
| RNF-15 | Español de Colombia. Fechas, horas y unidades de aquí | |
