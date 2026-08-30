# Casos de uso

Fichas del documento base, agrupadas por actor. El sistema también inicia CU-26 a CU-32.

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

- **Actores:** Solicitante, Despachador, Operador, Receptor, Administrador
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
- **Normal:** Urgencia → medicamento → ubicación GPS o ajuste → descripción → confirma → estado `recibido`, prioridad alta → motor de decisión y despachadores cercanos
- **Alternativas:** Sin permiso de GPS → dirección manual
- **Post:** Pedido en `recibido`, listo para evaluar

### CU-05 — Consultar estado del pedido

- **Pre:** Al menos un pedido
- **Normal:** “Mi pedido” → estado (recibido, en evaluación, asignado, en vuelo, entregado, rechazado) + datos de la misión
- **Alternativas:** Rechazado por disponibilidad → mostrar alternativa del fallback
- **Post:** Solicitante informado

### CU-06 — Ubicación del dron en tiempo real

- **Pre:** Pedido asignado y dron en vuelo
- **Normal:** Seguimiento → canal de telemetría → mapa + ETA → actualiza solo
- **Alternativas:** Corte de conexión → reconectar; mientras tanto última posición
- **Post:** Seguimiento hasta la entrega

### CU-07 — Generar código de entrega

- **Pre:** Pedido en curso
- **Normal:** “Delegar recepción” → código de un uso → se muestra para compartir
- **Post:** Código válido una vez

### CU-08 — Historial de pedidos

- **Pre:** Algún pedido previo
- **Normal:** Historial → lista por fecha y estado final

---

## Despachador

### CU-09 — Registrar central

- **Pre:** Despachador verificado
- **Normal:** Formulario (nombre, tipo, ubicación, contacto) → estado `pendiente de aprobación` → notifica al admin
- **Post:** Espera aprobación

### CU-10 — Gestionar inventario

- **Pre:** Central aprobada
- **Normal:** Ver existencias → alta (cantidad, vencimiento, frío) → editar o baja
- **Alternativas:** Flag de temperatura → el sistema activará monitoreo en misiones que lo lleven
- **Post:** Inventario usable por decisión y pedidos

### CU-11 — Autorizar pedidos de emergencia

- **Pre:** Pedido de emergencia asignado a la central
- **Normal:** Lista → detalle (medicamento, ubicación) → verifica stock → autoriza → descuenta inventario → motor de decisión
- **Alternativas:** Sin stock → rechaza; el sistema reasigna a otra central cercana con disponibilidad
- **Post:** Pedido autorizado, listo para asignar dron

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
- **Normal:** Reloj desde la asignación → supera límite → push → despachador prioriza
- **Post:** Despachador notificado

---

## Operador de flota

### CU-15 — Registrar dron

- **Normal:** Identificador + `DroneModel` (Wingcopter 198) → estado `disponible`
- **Post:** Candidato para el motor de decisión

### CU-16 — Actualizar disponibilidad

- **Pre:** Dron registrado
- **Normal:** Cambiar a disponible, mantenimiento o fuera de servicio
- **Alternativas:** En misión → no se cambia hasta terminar
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

## Receptor

### CU-21 — Confirmar entrega con código (sin cuenta)

- **Pre:** Dron en el punto; solicitante compartió el código
- **Normal:** Pantalla de confirmación → código → válido → pedido `entregado` → notifica al solicitante
- **Alternativas:** Código incorrecto o ya usado → rechazar, nuevo intento
- **Post:** Pedido entregado; código inválido a futuro

### CU-22 — Consultar entrega (receptor con cuenta)

- **Pre:** Cuenta activa; pedido asignado como destinatario
- **Normal:** Login → entregas → estado y mapa como el solicitante

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
- **Normal:** Conteos por tipo, tiempo promedio de entrega, incidencias

---

## Automatizados (sistema)

### CU-26 — Evaluar elegibilidad

- **Actor:** Motor de decisión
- **Pre:** Pedido autorizado esperando asignación
- **Normal:** Pendientes por prioridad → drones de la central → filtrar por batería, payload, mantenimiento, clima simulado → elegir el más adecuado → marcar `en misión`
- **Alternativas:** Ninguno elegible → CU-31. Emergencia vs programado por el mismo dron → gana emergencia
- **Post:** Dron reservado o fallback

### CU-27 — Calcular ruta

- **Pre:** Dron reservado
- **Normal:** Origen (central) y destino → geovallas → corredor a altitud fija → asociar ruta → enviar a simulación
- **Alternativas:** Sin ruta viable → descartar ese dron y reintentar CU-26 con otro
- **Post:** Ruta lista o nuevo ciclo de elegibilidad

### CU-28 — Simular vuelo y publicar telemetría

- **Actor:** Motor de simulación
- **Pre:** Ruta y dron reservado
- **Normal:** Despegue → ticks (posición, velocidad, altitud, batería por fase) → WSS → transición, crucero, descenso, aterrizaje → estados `en vuelo` luego entrega
- **Alternativas:** Ítem con frío → simular temperatura. Batería crítica → alerta operador
- **Post:** Ruta completada o alerta de anomalía

Nota de consistencia: la confirmación humana (CU-21) marca `entregado` cuando hay receptor; la simulación llega al punto de entrega. En implementación, el estado final `entregado` debe esperar el código si el flujo de recepción está activo (HU-33/34).

### CU-29 — Notificar cambios de estado

- **Actores:** Sistema + solicitante, receptor, despachador según el evento
- **Normal:** Cambio (asignado, en vuelo, por aterrizar, entregado, rechazado) → push a involucrados

### CU-30 — Cadena de frío

- **Pre:** Pedido marcado sensible a temperatura
- **Normal:** Sensor simulado en cada tick → comparar con rango
- **Alternativas:** Fuera de rango → alerta inmediata al operador
- **Post:** Temperatura registrada; operador alertado si hay desviación

### CU-31 — Sugerir alternativa de entrega

- **Pre:** CU-26 sin drones elegibles
- **Normal:** Otra central con stock **o** aviso al despachador para traslado convencional → mostrar al solicitante y notificar despachador → estado `reasignado` (no `rechazado` ciego)
- **Post:** Hay alternativa visible

### CU-32 — Alerta de batería o falla crítica

- **Pre:** Dron en misión
- **Normal:** Monitor de batería y falla simulada → alerta en el panel del operador
- **Post:** Operador informado; puede actuar (en el MVP: visibilidad; no se exige un protocolo de aborto complejo)
