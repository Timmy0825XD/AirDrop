# Casos de uso

Fichas del documento base, agrupadas por actor. El sistema también inicia CU-26 a CU-34.

Formato de cada ficha: actores, precondiciones, flujo normal, alternativas, poscondiciones.

---

## Solicitante

### CU-01 — Registrar cuenta de solicitante

Persona crea cuenta para reportar pedidos.

- **Actores:** Solicitante
- **Pre:** Celular o correo válido; no hay cuenta previa con ese dato
- **Normal:** Formulario (nombre, correo o celular, contraseña) → validar unicidad → cuenta no verificada → OTP 6 dígitos → ingreso del código (10 min) → cuenta activa → pantalla principal
- **Alternativas:** Contacto ya registrado → error. OTP malo o vencido → rechazar y permitir reenvío
- **Post:** Cuenta activa; puede iniciar sesión

### CU-02 — Iniciar sesión

- **Actores:** Solicitante, Despachador, Operador, Administrador
- **Pre:** Cuenta activa y verificada
- **Normal:** Credenciales → validar → JWT con rol → home del rol
- **Alternativas:** Credenciales incorrectas (hasta 5 intentos). Tras el límite, bloqueo temporal
- **Post:** Autenticado según rol

### CU-03 — Recuperar contraseña

- **Actores:** Todos los roles de usuario
- **Pre:** Cuenta registrada
- **Normal:** “Olvidé mi contraseña” → contacto → código 15 min → código + nueva clave → confirma
- **Alternativas:** Contacto inexistente → mensaje genérico (no revelar si existe). Código inválido → reintento
- **Post:** Contraseña nueva; la anterior deja de valer

### CU-04 — Registrar pedido de emergencia

- **Actores:** Solicitante
- **Pre:** Sesión activa
- **Normal:** Urgencia → medicamento → si el ítem **exige receta**, adjuntar imagen → ubicación GPS o ajuste → descripción → confirma → estado `recibido`, prioridad alta → notifica a despachadores cercanos
- **Alternativas:** Sin permiso de GPS → dirección manual. Ítem con receta y sin imagen → no se crea el pedido
- **Post:** Pedido en `recibido`, listo para que el despachador lo evalúe. **El motor de decisión no corre aún.**

### CU-05 — Consultar estado del pedido

- **Pre:** Al menos un pedido
- **Normal:** “Mi pedido” → estado (`recibido`, `en evaluación`, `asignado`, `pendiente de carga`, `en vuelo`, `en espera de entrega`, `entregado`, `en retorno`, `devuelto`, `rechazado`, `reasignado`) + datos de la misión (incluido identificador del dron cuando ya hay asignación)
- **Alternativas:** Rechazado por disponibilidad → mostrar alternativa del fallback
- **Post:** Solicitante informado

### CU-06 — Ubicación del dron en tiempo real

- **Pre:** Pedido con carga confirmada y dron en vuelo (ida o retorno)
- **Normal:** Seguimiento → canal de telemetría → mapa + ETA → actualiza solo
- **Alternativas:** Corte de conexión → reconectar; mientras tanto última posición
- **Post:** Seguimiento hasta entrega o hasta que el dron vuelve a la central

### CU-07 — Generar código de entrega

- **Pre:** Pedido en curso (asignado o posterior)
- **Normal:** “Código de entrega” → código de un uso → se muestra para usarlo en destino o compartirlo
- **Post:** Código válido una vez; no crea un usuario receptor

### CU-08 — Historial de pedidos

- **Pre:** Algún pedido previo
- **Normal:** Historial → lista por fecha y estado final

### CU-21 — Confirmar entrega con código

Sustituye el antiguo flujo de “receptor”. No hay rol de receptor.

- **Actores:** Solicitante (sesión) o quien tenga el código en la pantalla de confirmación
- **Pre:** Dron en el punto (`en espera de entrega`); hay código vigente
- **Normal:** Ingresar código → válido → pedido `entregado` → notifica al solicitante y al despachador; el dron queda libre según reglas de flota (en el MVP: misión cerrada en destino)
- **Alternativas:** Código incorrecto o ya usado → rechazar, nuevo intento. Timeout de 5 min → CU-34
- **Post:** Pedido entregado; código inválido a futuro

---

## Despachador

### CU-09 — Registrar central

- **Pre:** Despachador verificado
- **Normal:** Formulario (nombre, tipo, ubicación, contacto) → estado `pendiente de aprobación` → notifica al admin
- **Post:** Espera aprobación

### CU-10 — Gestionar inventario

- **Pre:** Central aprobada
- **Normal:** Ver existencias → alta (cantidad, vencimiento, frío, **exige receta**) → editar o baja
- **Alternativas:** Flag de temperatura → el sistema activará monitoreo en misiones que lo lleven
- **Post:** Inventario usable por decisión y pedidos

### CU-11 — Autorizar pedidos de emergencia

- **Pre:** Pedido de emergencia asignado a la central (cola del despachador)
- **Normal:** Lista → detalle (medicamento, ubicación, receta si aplica) → verifica stock → **autoriza** → el sistema ejecuta el motor de decisión (CU-26) y calcula ruta (CU-27) → muestra al despachador la **referencia del dron** (identificador y modelo) → pedido `pendiente de carga`
- **Alternativas:** Sin stock → rechaza; el sistema reasigna a otra central cercana con disponibilidad. Sin dron elegible → CU-31. Receta ilegible o incompleta → puede rechazar con motivo
- **Post:** Dron **reservado**. Inventario **aún no** se descuenta. El vuelo **no** ha empezado.

### CU-22 — Confirmar carga en el dron

- **Actores:** Despachador
- **Pre:** Pedido `pendiente de carga`; dron asignado visible
- **Normal:** El despachador coloca el medicamento o insumo en el dron indicado → marca “carga lista” → se descuenta inventario → estado `en vuelo` (tras despegue simulado) → arranca CU-28
- **Alternativas:** El despachador no confirma; el dron permanece reservado hasta que confirme, cancele o el pedido se reasigne según reglas de la cola
- **Post:** Reloj de simulación activo; solicitante puede seguir el mapa

### CU-12 — Crear plan de reabastecimiento

- **Pre:** Central activa
- **Normal:** Suministro, cantidad, frecuencia (única, semanal, quincenal, mensual), inicio, centro destino → el sistema genera los pedidos programados
- **Alternativas:** Destino no existe → registrarlo como punto de entrega
- **Post:** Plan activo; pedidos en las fechas definidas

### CU-13 — Histórico de misiones de la central

- **Pre:** Alguna misión despachada
- **Normal:** Lista emergencia y programadas, estado final y fecha

### CU-14 — Alerta de pedido de emergencia sin atender

- **Actores:** Despachador, Sistema
- **Pre:** Pedido de emergencia asignado sin autorizar
- **Normal:** Reloj desde la asignación a la cola → supera límite → push → despachador prioriza
- **Post:** Despachador notificado

---

## Operador de flota

### CU-15 — Registrar dron

- **Normal:** Identificador + `DroneModel` (Wingcopter 198) → estado `disponible`
- **Post:** Candidato para el motor de decisión

### CU-16 — Actualizar disponibilidad

- **Pre:** Dron registrado
- **Normal:** Cambiar a disponible, mantenimiento o fuera de servicio
- **Alternativas:** En misión (reservado, en vuelo, en espera o en retorno) → no se cambia hasta terminar
- **Post:** Estado visible para decisión

### CU-17 — Registrar mantenimiento

- **Normal:** Motivo + fecha estimada de fin → `fuera de servicio` hasta esa fecha
- **Post:** Excluido de asignaciones

### CU-18 — Definir geovallas

- **Normal:** Polígono en el mapa + nombre y motivo → aplica al instante en rutas
- **Alternativas:** Editar o eliminar existentes
- **Post:** Ninguna ruta nueva atraviesa esa zona

### CU-19 — Telemetría detallada

- **Pre:** Dron en misión
- **Normal:** Canal en vivo: posición, altitud, velocidad, batería, payload, temperatura, ping, fase
- **Alternativas:** Pérdida de enlace → reintento; si persiste, notificar
- **Post:** Visibilidad operativa

### CU-20 — Dashboard epidemiológico

- **Pre:** Pedidos históricos
- **Normal:** Agregar por medicamento, ubicación y fecha → visualizaciones

---

## Administrador

### CU-23 — Aprobar central

- **Pre:** Central en pendiente
- **Normal:** Detalle → aprueba → activa y notifica al despachador
- **Alternativas:** Rechazo con motivo
- **Post:** Central operativa o solicitud rechazada

### CU-24 — Cuentas institucionales

- **Normal:** Lista → suspender o reactivar
- **Post:** Afecta el acceso

### CU-25 — Métricas generales

- **Pre:** Hay misiones
- **Normal:** Conteos por tipo, tiempo promedio de entrega, incidencias (incluidos retornos sin entrega)

---

## Automatizados (sistema)

### CU-26 — Evaluar elegibilidad

- **Actor:** Motor de decisión
- **Pre:** Pedido **autorizado** por el despachador, esperando asignación
- **Normal:** Drones de la central → filtrar por batería, payload, mantenimiento, clima simulado y ruta viable → elegir el más adecuado → marcar dron `en misión` (reservado) → pedido `pendiente de carga`
- **Alternativas:** Ninguno elegible → CU-31. Emergencia vs programado por el mismo dron → gana emergencia
- **Post:** Dron reservado **o** fallback. **No** se publica telemetría de vuelo ni se mueve el dron.

### CU-27 — Calcular ruta

- **Pre:** Dron reservado (CU-26)
- **Normal:** Origen (central) y destino → geovallas → corredor a altitud fija de ida → asociar ruta. El tramo de **retorno** se calcula si luego aplica CU-34
- **Alternativas:** Sin ruta viable → descartar ese dron y reintentar CU-26 con otro
- **Post:** Ruta de ida lista. La simulación espera CU-22

### CU-28 — Simular vuelo y publicar telemetría

- **Actor:** Motor de simulación
- **Pre:** Ruta lista **y** carga confirmada (CU-22)
- **Normal:** Despegue → ticks (posición, velocidad, altitud, batería por fase) → WSS → transición, crucero, descenso, aterrizaje en destino → estado `en espera de entrega` → CU-33
- **Alternativas:** Ítem con frío → simular temperatura. Batería crítica → alerta operador
- **Post:** Dron en el punto, **sin** marcar `entregado`

El estado `entregado` **solo** lo pone CU-21 (código válido). La simulación no “entrega sola” al aterrizar.

### CU-29 — Notificar cambios de estado

- **Actores:** Sistema + solicitante, despachador (y operador si hay alerta) según el evento
- **Normal:** Cambio (asignado, pendiente de carga, en vuelo, en espera de entrega, entregado, en retorno, devuelto, rechazado) → push a involucrados

### CU-30 — Cadena de frío

- **Pre:** Pedido marcado sensible a temperatura; simulación activa (ida, espera o retorno)
- **Normal:** Sensor simulado en cada tick de vuelo → comparar con rango
- **Alternativas:** Fuera de rango → alerta inmediata al operador
- **Post:** Temperatura registrada; operador alertado si hay desviación

### CU-31 — Sugerir alternativa de entrega

- **Pre:** CU-26 sin drones elegibles (en la autorización, no “después de un despegue ficticio”)
- **Normal:** Otra central con stock **o** aviso al despachador para traslado convencional → mostrar al solicitante y notificar despachador → estado `reasignado` (no `rechazado` ciego)
- **Post:** Hay alternativa visible; ningún dron quedó en vuelo vacío

### CU-32 — Alerta de batería o falla crítica

- **Pre:** Dron en misión de vuelo
- **Normal:** Monitor de batería y falla simulada → alerta en el panel del operador
- **Post:** Operador informado; puede actuar (en el MVP: visibilidad; no se exige un protocolo de aborto complejo)

### CU-33 — Esperar código de entrega

- **Actor:** Sistema
- **Pre:** Dron en destino tras CU-28
- **Normal:** Pedido `en espera de entrega` → ventana de **5 minutos** → si llega CU-21 con código válido, se cierra la espera
- **Alternativas:** Transcurren 5 minutos sin código válido → CU-34
- **Post:** Entrega confirmada **o** inicia retorno

### CU-34 — Devolver el paquete a la central

- **Actor:** Motor de simulación
- **Pre:** Timeout de CU-33
- **Normal:** Pedido `en retorno` → calcular/usar ruta de regreso (mismas reglas de geovallas) → ticks de telemetría → aterrizaje en la central → pedido `devuelto`; inventario de la central se **reincorpora** (el paquete volvió); dron deja de estar `en misión`
- **Alternativas:** Batería crítica en retorno → alerta operador (CU-32)
- **Post:** Insumo otra vez en la central; misión cerrada sin entrega
