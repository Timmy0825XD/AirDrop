# Actores y modelo de negocio

## Propuesta de valor

- **Urgencia:** despacho de un medicamento crítico en minutos, sin depender de vía, conductor o ambulancia.
- **Programado:** flujo periódico de sangre, vacunas e insumos a centros de difícil acceso; menos traslados de última hora.
- En ambos: **trazabilidad** de la misión, **cadena de frío** cuando aplica, **respaldo** si el dron no es viable.
- Subproducto: **dashboard epidemiológico** (inventario y puntos de atención a futuro).

## Actores

| Actor | Quién | Qué hace en el sistema |
| --- | --- | --- |
| Solicitante | Paciente, acompañante, personal de puesto rural | Registra el pedido (con receta en imagen si aplica), sigue estado y mapa, genera e ingresa el código de entrega |
| Despachador | Rol en hospital, clínica o farmacia (central) | Inventario, autoriza, carga el insumo en el dron asignado, planes programados |
| Operador de flota | Responsable de drones | Estados, geovallas, telemetría, mantenimiento |
| Administrador | Operación de la plataforma | Aprueba centrales, cuentas institucionales, métricas |

No existe el rol **receptor**. Quien está en el punto de entrega usa el **código de un uso** (pantalla de confirmación, con o sin sesión de solicitante); no hay un tipo de cuenta aparte.

## Lienzo resumido

| Bloque | Contenido |
| --- | --- |
| Segmentos | IPS con distancias críticas; bancos de sangre y PAI; EPS y secretarías; farmacias/centrales de despacho |
| Valor | Tiempo, continuidad de stock, trazabilidad, frío, fallback, datos agregados |
| Canales | App móvil por rol + push |
| Relación | Soporte a centrales, geovallas e inventario, dashboard incluido |
| Ingresos (modelo) | Tarifa por misión de emergencia; suscripción de reabastecimiento (frecuencia/volumen); telemetría y dashboard en el paquete |
| Recursos clave | App, motores de decisión y simulación, datos operativos |
| Actividades | Flota simulada, decisión y rutas, plataforma, protocolo de frío |
| Socios | IPS como centrales; a futuro salud pública |
| Costos | Desarrollo, nube (datos + telemetría), soporte |

El MVP **no** implementa pasarela de pagos. El canvas explica el proyecto; el software demuestra operación y decisión.
