# Casos de uso

Cada ficha dice quién actúa, qué tiene que ser cierto antes, los pasos, qué pasa si algo falla y por qué el caso existe. Los ID no se renumeran. Requisitos: [requisitos.md](requisitos.md).

## Solicitante

### CU-01 — Registrar cuenta

- **Actores:** Solicitante
- **Antes:** No existe una cuenta con ese documento o ese celular
- **Pasos:**
  1. Ingresa nombre, tipo y número de documento, celular, contraseña y consentimiento. El correo es opcional.
  2. El sistema rechaza tarjeta de identidad y cualquier documento que no sea cédula de ciudadanía, cédula de extranjería o PPT.
  3. Crea la cuenta sin activar y envía un OTP de 6 dígitos al celular, vigente 10 minutos.
  4. Si el código es válido, la cuenta queda activa y abre el inicio del solicitante.
- **Si falla:** Documento o celular repetido: error. OTP incorrecto o vencido: no activa y permite reenviar.
- **Después:** Puede iniciar sesión. Todavía no hay pedido.
- **Por qué:** RU-01 y RF-02. Sin consentimiento y sin documento no hay tratamiento de un dato que después puede ser de salud.

### CU-02 — Iniciar sesión

- **Actores:** Solicitante, despachador, operador, administrador
- **Antes:** Cuenta activa. La institucional ya fue creada por el administrador. La de administrador existe desde el arranque.
- **Pasos:**
  1. Ingresa correo o celular, y contraseña.
  2. El sistema entrega un token con el rol.
  3. Abre el inicio de ese rol.
- **Si falla:** Clave incorrecta, hasta 5 intentos. Después, bloqueo temporal.
- **Después:** La sesión solo muestra lo de su rol.
- **Por qué:** RF-03 y RNF-04. El despachador no pasa por el registro público de CU-01.

### CU-03 — Recuperar contraseña

- **Actores:** Cualquier rol con cuenta
- **Antes:** La cuenta existe
- **Pasos:**
  1. Pide recuperación con correo o celular.
  2. Si el contacto existe, llega un código de 15 minutos. Si no existe, el mensaje es el mismo.
  3. Ingresa el código y la clave nueva.
- **Si falla:** Código inválido: puede reintentar. No se dice si la cuenta estaba o no.
- **Después:** La clave anterior deja de servir.
- **Por qué:** RF-05. El mensaje genérico evita confirmar qué celulares están registrados.

### CU-04 — Urgencia civil

- **Actores:** Solicitante
- **Antes:** Sesión activa
- **Pasos:**
  1. Elige el medicamento y escribe una descripción breve.
  2. Si el tipo de venta es bajo fórmula, adjunta la imagen. El documento de la cuenta debe ser el del paciente escrito en la fórmula.
  3. Confirma la ubicación. Si no hay GPS, escribe la dirección.
  4. El pedido queda en `recibido`, con prioridad alta, y entra a la cola de las centrales que pueden atenderlo.
- **Si falla:** Bajo fórmula sin imagen, o documento distinto: no se crea. Control especial: no se crea y se explica que ese canal no existe aquí.
- **Después:** Ningún dron está reservado. El motor de decisión no corre.
- **Por qué:** RU-02 y RU-25. Crear el pedido no es autorizar la salida.

### CU-35 — Entrega periódica civil

- **Actores:** Solicitante
- **Antes:** Sesión activa
- **Pasos:**
  1. Elige medicamento, cantidad, frecuencia (única, semanal, quincenal o mensual) y fecha de inicio.
  2. Si es bajo fórmula, adjunta la imagen y el documento coincide, igual que en CU-04.
  3. Fija la ubicación de entrega.
  4. El sistema genera las ocurrencias. Cada una llega a la cola como un pedido programado, no como urgencia.
- **Si falla:** Las mismas exclusiones de fórmula y de control especial que CU-04.
- **Después:** Hay un plan. Cada fecha espera autorización. No hay vuelo todavía.
- **Por qué:** RU-30. El periódico civil no se pide desde la cuenta de una central.

### CU-05 — Consultar estado

- **Actores:** Solicitante
- **Antes:** Tiene al menos un pedido
- **Pasos:** Abre el pedido y ve el estado, y el identificador del dron cuando ya hubo asignación.
- **Si falla:** Si el estado es `reasignado`, ve la alternativa de CU-31.
- **Después:** Sabe si el dron está reservado, en el aire o de regreso.
- **Por qué:** RU-03. `pendiente de carga` no significa que ya despegó.

### CU-06 — Mapa

- **Actores:** Solicitante
- **Antes:** La carga ya se confirmó y el dron va de ida o de regreso
- **Pasos:** Abre el seguimiento. El mapa y la llegada estimada se actualizan con la telemetría.
- **Si falla:** Si se corta el canal, reconecta y mientras muestra la última posición.
- **Después:** El seguimiento termina al entregar o al volver a la central.
- **Por qué:** RU-04. Antes de la carga no hay posición de vuelo que mostrar.

### CU-07 — Generar código

- **Actores:** Solicitante, o el despachador de destino si el pedido es entre centrales
- **Antes:** El pedido ya está asignado o más adelante, y todavía no se ha usado el código
- **Pasos:** Pide el código. El sistema muestra uno de un solo uso.
- **Después:** Quien está en el punto puede ingresarlo en CU-21. No nace un usuario receptor.
- **Por qué:** RU-07.

### CU-08 — Historial

- **Actores:** Solicitante
- **Antes:** Tiene pedidos cerrados o en curso
- **Pasos:** Abre la lista ordenada por fecha y estado final.
- **Por qué:** RU-08. Solo ve los suyos.

### CU-21 — Confirmar con el código

- **Actores:** Solicitante, si el destino es su ubicación. Despachador de la central que pidió, si el destino es esa central.
- **Antes:** El dron está en `en espera de entrega` y el código sigue vigente
- **Pasos:**
  1. Ingresa el código.
  2. Si es válido y es una entrega a persona, el pedido pasa a `entregado`.
  3. Si es válido y es un traslado, además compara cantidad, lote, vencimiento, sello y temperatura con la remisión. Si coincide y no hubo alerta de frío, el inventario entra en la central de destino y el pedido pasa a `entregado`.
  4. Se avisa a quien pidió y a quien despachó. El dron deja la misión.
- **Si falla:** Código incorrecto o ya usado: no cierra y permite otro intento dentro de los 5 minutos. Si la remisión no coincide o hubo alerta de frío: no ingresa el stock y sigue CU-34. A los 5 minutos sin código válido: CU-34.
- **Después:** El código no vuelve a servir.
- **Por qué:** RU-24 y RF-19. Aterrizar no es entregar. En un traslado, recibir es ingresar inventario, no solo marcar un estado.

## Despachador

### CU-09 — Entrar a su central

- **Actores:** Despachador
- **Antes:** El administrador lo creó y lo asignó a una central activa
- **Pasos:** Inicia sesión y ve solo esa central, su inventario y su cola.
- **Después:** No puede crear otra central ni ver la cola de otra.
- **Por qué:** RU-09. La firma de salida es de un solo establecimiento.

### CU-10 — Inventario

- **Actores:** Despachador
- **Antes:** Su central está activa
- **Pasos:**
  1. Lista existencias.
  2. Da de alta cantidad, lote, vencimiento, tipo de venta y si exige frío.
  3. Puede corregir o dar de baja.
- **Después:** Ese ítem ya puede pedirse. Si lleva frío, las misiones que lo lleven monitorean temperatura.
- **Por qué:** RU-11 y RU-14. Sin lote el sistema no sabe qué unidad sale.

### CU-11 — Autorizar una urgencia

- **Actores:** Despachador de la central que tiene el insumo
- **Antes:** Hay una urgencia en su cola. Puede venir de un solicitante o de otra central.
- **Pasos:**
  1. Abre detalle: medicamento, destino y, si el destino es una persona, la fórmula.
  2. Si hay fórmula, comprueba la lista de [../entregas/persona.md](../entregas/persona.md). Si es un traslado, comprueba que el pedido no traiga fórmula de paciente y que existan unidades selladas.
  3. Elige el lote que vence primero y que no esté vencido.
  4. Autoriza. Corre CU-26 y CU-27.
  5. Ve el identificador y el modelo del dron. El pedido queda en `pendiente de carga`.
- **Si falla:** Sin stock: rechaza y el sistema busca otra central. Fórmula ilegible, incompleta o vencida: rechaza con motivo y no autoriza. Sin dron elegible: CU-31.
- **Después:** El dron está reservado. El inventario sigue igual. El vuelo no ha empezado.
- **Por qué:** RU-10. Autorizar es la decisión del profesional. Cargar es otro acto.

### CU-36 — Urgencia entre centrales

- **Actores:** Despachador de la central que necesita el insumo
- **Antes:** Su central está activa y elige otra central activa como origen
- **Pasos:**
  1. Elige medicamento y cantidad. No adjunta fórmula.
  2. El pedido queda en `recibido`, prioridad alta, destino su central, origen la otra.
  3. Entra a la cola del despachador de origen, que sigue CU-11.
- **Si falla:** Origen inexistente, suspendido o igual al destino: no se crea. Control especial: no se crea.
- **Después:** Nadie ha reservado un dron todavía.
- **Por qué:** RU-31. Quien necesita el stock no es quien lo suelta.

### CU-22 — Confirmar carga

- **Actores:** Despachador de la central de origen
- **Antes:** El pedido está en `pendiente de carga` y el dron asignado se ve en pantalla
- **Pasos:**
  1. Coloca el insumo en ese dron.
  2. Si el destino es una persona, deja constancia de la información de uso y de la salida (paciente, medicamento, lote, cantidad, destino).
  3. Si el destino es una central, deja la remisión (origen, destino, medicamento, lote, vencimiento, cantidad). No adjunta consejo de uso para un paciente.
  4. Marca la carga. Se descuenta ese lote. El estado pasa a `en vuelo` cuando la simulación despega (CU-28).
- **Si falla:** Si no confirma, el dron sigue reservado. Puede cancelar según la cola. No hay telemetría de vuelo.
- **Después:** El reloj de simulación corre. Quien pidió puede abrir el mapa.
- **Por qué:** RU-29 y RF-28. El descuento ocurre al salir, no al autorizar.

### CU-12 — Plan entre centrales

- **Actores:** Despachador de la central que necesita el insumo
- **Antes:** Su central y la de origen están activas
- **Pasos:**
  1. Elige origen, medicamento, cantidad, frecuencia y fecha de inicio.
  2. El sistema crea las ocurrencias con destino en su central.
  3. En cada fecha, el despachador de origen autoriza y carga como en CU-11 y CU-22.
  4. Quien pidió recibe con CU-21. Si la remisión cuadra, el inventario entra en su central.
- **Si falla:** Origen inactivo: el plan no se crea.
- **Después:** El plan queda activo. Ninguna ocurrencia despega sola.
- **Por qué:** RU-12. La frecuencia no salta la autorización de cada salida.

### CU-13 — Histórico de la central

- **Actores:** Despachador
- **Antes:** Su central tuvo misiones
- **Pasos:** Lista emergencias y programadas con estado final y fecha.
- **Por qué:** RU-13. No ve el histórico de otra central.

### CU-14 — Urgencia quieta

- **Actores:** Sistema y despachador
- **Antes:** Una urgencia está en su cola sin autorizar
- **Pasos:** Al pasar el tiempo configurado, llega un aviso.
- **Después:** Sigue en cola. El aviso no autoriza solo.
- **Por qué:** RU-15.

## Operador

### CU-15 — Alta de dron

- **Actores:** Operador, en una central que tiene asignada
- **Antes:** Esa central está activa
- **Pasos:** Registra identificador y modelo Wingcopter 198. El estado inicial es `disponible`.
- **Después:** Entra a los candidatos de CU-26.
- **Por qué:** RU-17 y RF-20.

### CU-16 — Cambiar disponibilidad

- **Actores:** Operador
- **Antes:** El dron existe y pertenece a una central suya
- **Pasos:** Lo pasa a disponible, mantenimiento o fuera de servicio.
- **Si falla:** Si está reservado, en vuelo, en espera o de regreso, el cambio espera a que la misión cierre.
- **Por qué:** Un dron en el aire no se saca de la misión desde el tablero de estados.

### CU-17 — Mantenimiento

- **Actores:** Operador
- **Pasos:** Anota el motivo y la fecha estimada de fin. El dron queda fuera de servicio hasta entonces y CU-26 no lo elige.
- **Por qué:** RU-22.

### CU-18 — Geovallas

- **Actores:** Operador
- **Pasos:** Dibuja un polígono, le pone nombre y motivo. Puede editarlo o borrarlo. Las rutas que se calculen después no lo cruzan.
- **Por qué:** RU-19. Una geovalla no reescribe una misión que ya va en el aire; sí impide la siguiente ruta, incluida la de retorno si todavía no se calculó.

### CU-19 — Telemetría

- **Actores:** Operador
- **Antes:** Un dron de sus centrales está en misión de vuelo
- **Pasos:** Ve posición, altitud, velocidad, batería, carga, temperatura, latencia y fase.
- **Si falla:** Si el enlace se pierde, reintenta. Si sigue caído, queda el aviso.
- **Por qué:** RU-18. El solicitante ve el mapa. El operador ve el paquete completo.

### CU-20 — Dashboard

- **Actores:** Operador
- **Antes:** Hay pedidos históricos
- **Pasos:** Ve conteos por medicamento, zona y fecha. La pantalla no muestra documento, nombre ni dirección.
- **Por qué:** RU-23 y RNF-05.

## Administrador

### CU-23 — Crear o suspender central

- **Actores:** Administrador
- **Antes:** Sesión de administrador
- **Pasos:**
  1. Registra nombre, tipo, ubicación y contacto. La central queda activa.
  2. Desde el detalle puede suspenderla. Suspendida, no despacha ni pide.
- **Después:** No queda una solicitud “pendiente de aprobación” de un despachador, porque el despachador no crea centrales.
- **Por qué:** RU-26.

### CU-24 — Crear cuentas institucionales

- **Actores:** Administrador
- **Pasos:**
  1. Crea un despachador con correo institucional y exactamente una central activa.
  2. Crea un operador con correo institucional y una o varias centrales activas.
  3. Puede suspender o reactivar cualquiera de las dos.
- **Después:** Entran por CU-02, sin OTP de registro. Suspender les quita el acceso.
- **Por qué:** RU-27. La capacitación para aprobar salidas no se autodeclara en el registro público.

### CU-25 — Métricas

- **Actores:** Administrador
- **Antes:** Hay misiones
- **Pasos:** Ve conteos por tipo, tiempo promedio e incidencias, incluidos los retornos sin entrega.
- **Por qué:** RU-28. No abre imágenes de fórmula.

## Sistema

### CU-26 — Elegir dron

- **Actor:** Motor de decisión
- **Antes:** Un despachador autorizó y el pedido espera asignación
- **Pasos:**
  1. Toma los drones de la central de origen.
  2. Descarta los que no cumplan batería, carga, mantenimiento, clima simulado o ruta.
  3. Si una emergencia y un programado compiten por el mismo dron, se queda la emergencia.
  4. Reserva el elegido y deja el pedido en `pendiente de carga`.
- **Si falla:** Ninguno sirve: CU-31.
- **Después:** No hay telemetría de vuelo y el dron no se mueve.
- **Por qué:** RF-11. La decisión ocurre al autorizar, no al despegar.

### CU-27 — Calcular ruta

- **Actor:** Sistema
- **Antes:** Hay un dron reservado
- **Pasos:** Traza el corredor de ida entre la central de origen y el destino, a altitud fija, fuera de las geovallas. El regreso se calcula si luego corre CU-34.
- **Si falla:** Si ese dron no tiene camino, vuelve a CU-26 con otro.
- **Después:** La simulación espera CU-22.
- **Por qué:** RF-12.

### CU-28 — Volar

- **Actor:** Motor de simulación
- **Antes:** Hay ruta y la carga ya se confirmó
- **Pasos:** Despega, publica ticks, recorre las fases y aterriza. El pedido pasa a `en espera de entrega` y corre CU-33.
- **Si falla:** Con frío, cada tick lleva temperatura (CU-30). Con batería crítica, corre CU-32.
- **Después:** Está en el punto y el pedido no está `entregado`.
- **Por qué:** RF-13. La simulación no entrega sola.

### CU-29 — Avisar

- **Actores:** Sistema, y según el evento el solicitante, el despachador o el operador
- **Pasos:** En cada cambio de estado, llegada, espera, retorno o alerta, envía el aviso a quien participa en ese pedido.
- **Por qué:** RF-16. El operador recibe alertas de vuelo, no la fórmula.

### CU-30 — Frío

- **Actor:** Sistema
- **Antes:** El ítem exige frío y la simulación está en ida, espera o retorno
- **Pasos:** Compara la temperatura simulada con el rango en cada tick.
- **Si falla:** Fuera de rango: alerta al operador y marca la misión. Esa marca impide reingresar el insumo.
- **Por qué:** RF-17.

### CU-31 — Alternativa

- **Actor:** Sistema
- **Antes:** CU-26 no encontró dron, en el momento de autorizar
- **Pasos:** Muestra otra central con stock o avisa que toca un traslado convencional. El estado queda `reasignado`.
- **Después:** Quien pidió ve la alternativa. Ningún dron despegó vacío.
- **Por qué:** RU-06. El rechazo mudo no es una respuesta.

### CU-32 — Batería o falla

- **Actor:** Sistema
- **Antes:** El dron va en vuelo, de ida o de regreso
- **Pasos:** Avisa en el panel del operador.
- **Después:** En este MVP el aviso es la acción. No hay un protocolo de aborto aparte.
- **Por qué:** RU-21.

### CU-33 — Esperar el código

- **Actor:** Sistema
- **Antes:** El dron aterrizó en el destino
- **Pasos:** Deja el pedido en `en espera de entrega` durante 5 minutos. Si llega CU-21 con código válido, cierra la espera.
- **Si falla:** A los 5 minutos sin código válido, corre CU-34.
- **Por qué:** RF-29.

### CU-34 — Regresar con el paquete

- **Actor:** Motor de simulación
- **Antes:** CU-33 venció, o CU-21 rechazó la recepción de un traslado
- **Pasos:**
  1. El pedido pasa a `en retorno`.
  2. Vuela a la central de origen con las mismas reglas de geovalla y telemetría.
  3. Al aterrizar, el pedido queda `devuelto` y el dron sale de la misión.
  4. Sin alerta de temperatura y con empaque íntegro, el insumo reingresa en origen.
  5. Con alerta de temperatura, o si el despachador marca el empaque comprometido, queda en cuarentena y no vuelve al inventario.
- **Si falla:** Batería crítica en el regreso: CU-32.
- **Después:** La misión cerró sin entrega. El insumo no queda en el punto.
- **Por qué:** RF-30. Volver no es lo mismo que reponer el estante: el frío comprometido no se dispensa otra vez.
