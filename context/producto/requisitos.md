# Requisitos

Cada requisito dice qué se exige y por qué. Los ID no se renumeran. Los flujos están en [casos-de-uso.md](casos-de-uso.md). Las historias, en [backlog.md](backlog.md).

Roles: [../app/roles.md](../app/roles.md). Entregas: [../entregas/](../entregas/). Norma: [../legal/](../legal/).

No hay rol receptor. La recepción se cierra con el código (RU-07, RU-24).

## Solicitante

### RU-01 — Registro civil

Nombre, tipo y número de documento, celular de 10 dígitos, contraseña y consentimiento. El correo es opcional. Documentos: cédula de ciudadanía, cédula de extranjería o PPT.

**Por qué.** Es la única cuenta que se crea sola. El documento identifica a la persona que va a recibir el medicamento. El consentimiento es obligatorio porque el pedido puede llevar datos de salud (Ley 1581 de 2012). No se admite un documento de menor.

**Se cumple cuando.** Falta uno de esos datos, el documento o el celular ya existen, o no hay consentimiento: la cuenta no se crea. Sin OTP válido queda sin activar.

### RU-02 — Urgencia a mi ubicación

Medicamento, ubicación y una descripción breve, con prioridad alta.

**Por qué.** La urgencia civil no es un traslado entre centrales. El destino es la persona, y el despachador todavía no ha autorizado.

### RU-30 — Entrega periódica a mi ubicación

Medicamento, cantidad, frecuencia y fecha de inicio.

**Por qué.** Hay civiles en zonas de difícil acceso que necesitan el mismo insumo cada semana, quincena o mes. No se modela como un abastecimiento de central.

### RU-25 — Fórmula cuando el ítem la exige

Si el tipo de venta es bajo fórmula, la imagen es obligatoria y el documento de la cuenta es el del paciente. El control especial no se pide por este canal.

**Por qué.** El Decreto 2200 prohíbe dispensar sin fórmula lo que la etiqueta marca como venta bajo fórmula, y prohíbe entregar a una persona distinta de la prescrita. El control especial tiene otro régimen.

### RU-03 — Ver el estado

Estados: recibido, en evaluación, asignado, pendiente de carga, en vuelo, en espera de entrega, entregado, en retorno, devuelto, rechazado o reasignado.

**Por qué.** Autorizar no es despegar. El solicitante tiene que distinguir “ya hay dron reservado” de “ya va en el aire”.

### RU-04 — Mapa en vuelo

Ver el dron en el mapa desde que despega, en la ida y en el retorno.

### RU-05 — Avisos

Aviso cuando el dron está por aterrizar, cuando espera el código o cuando cambia el estado.

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

### RU-11 y RU-14 — Inventario

Cantidad, lote, vencimiento, tipo de venta y si exige frío.

**Por qué.** Sin lote no hay remisión ni dispensación trazable. El tipo de venta decide si hace falta fórmula. El frío decide si el trayecto se monitorea.

### RU-12 — Abastecimiento programado desde otra central

Pide a otra central un plan: suministro, cantidad, frecuencia y fechas. El destino es su central.

### RU-31 — Urgencia de abastecimiento

Pide a otra central un insumo que a la suya le falta, con prioridad alta. El destino es su central.

**Por qué.** RU-12 y RU-31 no los crea el solicitante. Los crea el despachador que necesita el stock. Quien suelta el insumo es el despachador de la otra central.

### RU-29 — Carga antes del vuelo

Después de autorizar ve el identificador del dron, deja la constancia que corresponda (información de uso si el destino es una persona; remisión si el destino es una central) y marca la carga. Solo entonces despega.

**Por qué.** Autorizar reserva. Despegar con la bodega vacía rompería la dispensación y la remisión.

### RU-13 — Histórico de la central

Misiones de emergencia y programadas de su central.

### RU-15 — Alerta de urgencia sin atender

Si una urgencia en su cola supera el tiempo configurado, recibe un aviso.

## Operador de flota

### RU-16 — Centrales asignadas

Entra con la cuenta que creó el administrador y ve una o varias centrales. No se registra solo.

**Por qué.** El técnico no está atado a un solo sitio. El despachador sí, porque el inventario y la firma de salida son de una central.

### RU-17 — Estado del dron

Disponible, en misión, en mantenimiento o fuera de servicio.

### RU-18 — Telemetría

Posición, altitud, velocidad, batería, carga, temperatura, latencia y fase.

### RU-19 — Geovallas

Dibujar, editar y borrar polígonos. Toda ruta nueva los respeta.

### RU-20 y RU-21 — Alertas de vuelo

Temperatura fuera de rango. Batería crítica o falla.

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

## Funcionales

### RF-01 — Registro

El registro público solo crea solicitantes, con los datos de RU-01. Despachador y operador los crea el administrador. La cuenta de administrador inicial no sale de ese formulario.

**Por qué.** Mezclar el alta pública con quien aprueba medicamentos deja la red sin control de la central.

### RF-02 — OTP del solicitante

Seis dígitos, un uso, 10 minutos, al celular. La cuenta civil queda activa solo después.

### RF-03 — Sesión

Correo o celular, más contraseña. El token lleva el rol.

### RF-04 — Cierre de sesión

El cliente deja de usar el token. El servidor lo considera vencido al expirar.

### RF-05 — Recuperar contraseña

Código de 15 minutos al correo o al celular. Si el contacto no existe, el mensaje no lo revela.

### RF-06 y RF-07 — Central

El administrador la crea con nombre, tipo (hospital, clínica, farmacia, banco de sangre o vacunación), ubicación y contacto, y puede suspenderla.

### RF-08 — Inventario

Alta, edición y baja con cantidad, lote, vencimiento, frío y tipo de venta: libre, bajo fórmula o control especial.

### RF-09 — Emergencia

La crea el solicitante (destino: su ubicación) o el despachador que necesita stock (destino: su central, origen: otra). Prioridad alta. Si el destino es una persona y el ítem es bajo fórmula, exige imagen y documento coincidente. Control especial: no se crea.

### RF-10 — Programado

Suministro, cantidad, frecuencia (única, semanal, quincenal o mensual) y fecha de inicio. El destino es la ubicación del solicitante o la central que pide el abastecimiento.

### RF-11 — Elegibilidad

Al autorizar: batería, carga, mantenimiento, clima simulado y ruta sin geovallas. La emergencia gana el dron si compite con un programado. Reserva el dron y no inicia el vuelo.

### RF-12 — Ruta

Corredor a altitud fija, de ida y de retorno si hace falta, sin cruzar geovallas.

### RF-13 y RF-14 — Telemetría

El tick empieza después de confirmar la carga: posición, velocidad, altitud, batería, carga, temperatura, latencia y fase, por WebSocket. El operador ve ese paquete en vivo.

### RF-15 — Seguimiento del solicitante

Estado y mapa desde el despegue, ida y retorno. No antes: todavía no hay vuelo.

### RF-16 y RF-24 — Avisos

Cambios de estado, llegada, espera de código, retorno, temperatura, batería y urgencia quieta más del tiempo configurado.

### RF-17 — Frío

Si el ítem lo exige, la temperatura simulada se compara con el rango en ida, espera y retorno. Fuera de rango: alerta, y la cuarentena de [../entregas/productos.md](../entregas/productos.md).

### RF-18 — Fallback

Si al autorizar ningún dron sirve, hay otra central con stock o un aviso de traslado convencional. El estado es `reasignado`, no un rechazo mudo.

### RF-19 y RF-29 — Código y espera

Un solo uso. Se ingresa con el dron en destino. La espera dura 5 minutos. Un código válido cierra `entregado`.

**Por qué.** Cinco minutos alcanzan para acusar recibo en el punto sin dejar el paquete esperando una ausencia larga. Pasado ese tiempo, el insumo no se queda en campo.

### RF-20 — Flota

Alta y estado de drones sobre el modelo Wingcopter 198. Un dron en misión no cambia de estado hasta cerrarla.

### RF-21 — Geovallas

Crear, editar y borrar. Una ruta que las cruza no es válida.

### RF-22 — Historial

El solicitante ve lo suyo. El despachador, lo de su central. El administrador, la plataforma.

### RF-23 — Dashboard

Conteos por medicamento, zona y fecha. Sin identificadores de persona.

### RF-25 — Cuentas institucionales

Crear, listar, suspender y reactivar. El despachador queda en una central. El operador, en una o varias.

### RF-26 — Métricas

Misiones por tipo, tiempo promedio e incidencias.

### RF-27 — Fórmula

Hacia una persona y en venta bajo fórmula: sin imagen, o con documento distinto al del paciente, el pedido no se crea. Al autorizar, el despachador verifica la lista de [../entregas/persona.md](../entregas/persona.md). Si no cumple, no autoriza. La imagen tiene acceso restringido. Entre centrales no hay fórmula de paciente.

### RF-28 — Confirmación de carga

El despachador ve el dron asignado. Si el destino es una persona, registra la información de uso y la salida. Si el destino es una central, registra la remisión. Marca la carga, se descuenta el lote que vence primero y empieza la simulación.

### RF-30 — Retorno

Sin código a los 5 minutos: vuelo de regreso, estados `en retorno` y luego `devuelto`. El reingreso sigue [../entregas/productos.md](../entregas/productos.md). En un traslado recibido correctamente, el stock entra en la central de destino, no vuelve al origen.

## No funcionales

| ID | Exigencia | Por qué |
| --- | --- | --- |
| RNF-01 | Contraseña con bcrypt | No guardar la clave en claro |
| RNF-02 | HTTPS y WSS | El canal lleva datos de salud y la posición del vuelo |
| RNF-03 | Cada endpoint comprueba el rol | El operador no abre una fórmula; el solicitante no autoriza |
| RNF-04 | Tope de 5 intentos de login y bloqueo temporal. Sin SQL armado en texto ni XSS abierto | Evita adivinar la clave a fuerza |
| RNF-05 | Consentimiento explícito. La fórmula no va a logs y solo la ve el despachador que autoriza. El dashboard no identifica | [../legal/datos.md](../legal/datos.md) |
| RNF-06 | La imagen de la fórmula se guarda con acceso restringido | Es dato sensible, no un adjunto público |
| RNF-07 | 95 % de las peticiones REST por debajo de 800 ms en carga normal | La cola de urgencia no puede esperar al tablero |
| RNF-08 | Telemetría al menos cada 2 s en vuelo. En la espera del código puede ir más espaciada | En crucero el mapa tiene que moverse. En el punto, el dato que importa es el código |
| RNF-09 | 99 % en horario de uso. Un mantenimiento se anuncia con al menos 24 h | |
| RNF-10 | Android e iOS, texto y contraste legibles | |
| RNF-11 | Más centrales, drones y misiones sin romper RNF-07. Lo durable va a Postgres. Lo vivo, a Redis | |
| RNF-12 | Si el socket se cae, reconecta y muestra el último estado | |
| RNF-13 | Módulos separados: flota, pedidos, despacho, rutas, geovallas, telemetría | |
| RNF-14 | Versiones de Android e iOS que Flutter soporte al desarrollar | |
| RNF-15 | Español de Colombia. Fechas, horas y unidades de aquí | |
