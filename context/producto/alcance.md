# Alcance y limitaciones (MVP)

## Entorno geográfico

- **MVP:** red regional de unos 45 km alrededor de Valledupar. Abarca los corregimientos del municipio, La Paz, San Diego, Manaure, Pueblo Bello y Agustín Codazzi: 4 nodos, 5 ESE y 12 puntos de entrega ([../negocio/cobertura.md](../negocio/cobertura.md)).
- **La ciudad de Valledupar no recibe vuelos.** Casi toda está dentro del anillo de 9 km del aeropuerto y es zona urbana ([../operacion/espacio-aereo.md](../operacion/espacio-aereo.md)). Abastece a los nodos por carretera, fuera del sistema.
- **Visión posterior:** otras regiones del Caribe con la misma red de nodos. Se reserva en el modelo de datos si es barato (la central ya tiene ubicación y tipo), pero **no** se entrega como producto multirregión.

## Incluido en el MVP

- **Pedidos:** de **emergencia** (prioridad alta) y **programados** (calendario, franja y cantidad).
- **Entrega según [`../entregas/`](../entregas/):** a una persona, en un **punto de entrega autorizado**; entre centrales, de un nodo a una ESE.
- **Flota propia de tres tipos:** Colibrí, Garza y Cóndor, con compartimento de frío opcional y estados de disponibilidad ([../operacion/flota.md](../operacion/flota.md)).
- **Espacio aéreo según el RAC 100:**
  - aeródromo, zonas prohibidas con 2 km de margen, helipuertos, zonas coordinadas (policía municipal y resguardos), zona urbana y restricciones temporales;
  - las zonas legales vienen cargadas y el operador no las borra; el operador puede dibujar geovallas propias ([../operacion/espacio-aereo.md](../operacion/espacio-aereo.md)).
- **Motor de decisión al autorizar:**
  - Filtra los drones por estado, carga, frío, batería sobre el perfil real, techo y corredor legal.
  - Elige por tipo de misión: la urgencia, el que llega antes; el programado, el que gasta menos.
  - Rechaza lo que la norma no permite: de noche, zona urbana o destino fuera de alcance.
  - La emergencia gana el recurso si hay competencia.
  - **No** asume que el insumo ya está a bordo ni inicia el vuelo.
- **Carga.** El despachador ve la **referencia del dron asignado**, coloca el insumo sellado y **marca la carga**. Se emite el **manifiesto numerado** ([../operacion/manifiesto.md](../operacion/manifiesto.md)). Solo entonces arranca la simulación.
- **Vuelo:**
  - Solo de día, de la salida a la puesta del sol, calculadas para la fecha simulada ([../operacion/condiciones-de-vuelo.md](../operacion/condiciones-de-vuelo.md)).
  - Rutas por corredores que evitan las zonas, con tolerancia de 30 m. Siguen el terreno a 90 m sobre el suelo y nunca pasan de 120 m AGL. El terreno sale de una malla SRTM.
- **Seguimiento:**
  - Telemetría en tiempo real en la app, con la identificación remota del dron.
  - Panel de operador: posición, altitud sobre el terreno y sobre el nivel del mar, velocidad, batería, carga, temperatura de la carga, latencia y fase de vuelo.
- **En destino:** el dron **espera 5 minutos** el código de entrega. Si no se ingresa, **regresa al nodo con el paquete**. El reingreso al inventario pasa por la cuarentena de [`../entregas/productos.md`](../entregas/productos.md).
- **Cadena de frío** simulada y alerta si la temperatura sale de rango.
- **Fallback:** alternativa terrestre si ningún dron es elegible, si es de noche (urgencia) o si el solicitante está en zona urbana.
- **Dashboard epidemiológico** simple: qué se pide más y en qué municipio.
- **Datos personales** ([../legal/datos.md](../legal/datos.md)): política de tratamiento versionada, datos de salud opcionales, revocar y suprimir la cuenta, y registro de acceso a fórmulas.
- **Consola de simulación** en la web del administrador, proyectada en una TV (RU-32). Sirve para demostrar que el sistema responde bien ante situaciones realistas:
  - Reloj simulado único para todo el sistema, también para la app: pausa, x1, x2, x4 y x8 (RF-31). El día y la noche siguen ese reloj.
  - Clima simulado por zonas (viento, lluvia, tormenta y niebla) que el motor de decisión, las rutas y el vuelo sí tienen en cuenta (RF-32).
  - Cambio de ruta en pleno vuelo cuando una zona nueva cruza el tramo que falta (RF-33).
  - Incidentes en vuelo, entre ellos la pérdida de enlace C2. Tienen protocolos autónomos: seguir, cambiar de ruta, volver al nodo o aterrizar en un punto seguro. Una urgencia abortada se vuelve a despachar (RF-34, RF-35).
  - Eventos de entorno: restricción temporal (orden público, evento, operativo), central sin energía, pico de urgencias, nadie retira el paquete y dron no identificado (RF-36).
  - Actores simulados (despachador automático, generador de pedidos, receptor) para una demo híbrida con personas reales usando la app (RF-37).
  - Modo caos realista, apagado por defecto (RF-38), línea de tiempo con alertas pendientes (RF-39) y reinicio del escenario (RF-40).
- **Solicitud de urgencia en 3 pasos:**
  - tamizaje opcional con signos de alarma y 123 (RF-41);
  - paciente a cargo (RF-42);
  - fórmula en PDF o hasta 3 fotos, con visor y consulta desde el histórico (RF-27);
  - punto de entrega propuesto a partir del GPS (RU-02).

## Limitaciones explícitas

| Limitación | Implicación |
| --- | --- |
| Dron 100 % simulado | Sin hardware ni API de fabricante. Los tres tipos son modelos propios, con cifras dentro de rangos públicos |
| Clima simulado | Sin OpenWeather ni equivalente. El clima lo crean la consola o el modo caos |
| Incidentes simulados | Sin física de choques ni aerodinámica: cada incidente tiene un efecto simple y nombrado (más consumo, menos velocidad, protocolo) |
| Consola, no gestión | La web no reemplaza la app: no tiene formularios de pedidos, inventario, centrales ni flota |
| Terreno simplificado | Malla de elevación de unos 500 m por celda, con el máximo de cada celda. Sin edificios ni árboles: el margen de 90 m AGL los cubre |
| Licencias y permisos | No se simulan: certificado de explotador, piloto, pólizas, autorizaciones de vuelo, consulta previa ([../legal/cumplimiento.md](../legal/cumplimiento.md)) |
| Zonas de la demo | Ubicadas con datos abiertos (OpenStreetMap, GeoNames), no oficiales |
| Geografía acotada | Una sola región. Multirregión no desplegada |
| Inventario manual | El despachador carga el stock; no hay integración con el sistema del hospital. El abastecimiento de los nodos no se simula |
| No es atención médica | Complementa el **insumo**, no el traslado ni la atención del paciente |

Cualquier issue o PR que viole esta tabla debe rechazarse, salvo que se actualice este documento de forma consciente.
