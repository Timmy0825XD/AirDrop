# Rendimiento

Lo que miden RNF-07 (95 % de las peticiones REST bajo 800 ms) y RNF-08 (telemetría cada 2 s reales en vuelo), y los límites del despliegue donde se presenta.

## Despliegue de la demo

| Pieza | Plan | Límite que importa |
| --- | --- | --- |
| Backend | Azure App Service B1 Linux (Chile Central), con crédito de Azure for Students | 1,75 GB de RAM, Always On y WebSockets activos: no se duerme. Sin disco persistente para datos |
| Base de datos | Supabase free (São Paulo) | Conexiones limitadas; cada consulta cruza de Chile a São Paulo |
| Caché y estado vivo | Upstash free | 500.000 comandos al mes |
| Correo | Brevo (API HTTP) | El correo va por la API HTTP, sin depender de puertos SMTP |

## Riesgos y qué hacer

| Riesgo | Efecto | Medida |
| --- | --- | --- |
| Reinicio del servicio | Un despliegue o reinicio borra el reloj y los vuelos en memoria; el arranque tarda cerca de 1 min | No desplegar durante la presentación; abrir `/health` antes de empezar |
| Latencia entre regiones | Cada consulta suma el viaje Chile ↔ São Paulo. El tick recorre los vuelos uno por uno | **Medir el p95 en Azure** con varios vuelos. Si no cumple: menos consultas por tick (estado del vuelo en memoria y Redis; Postgres solo en cambios de fase) |
| Cupo de Upstash | Cada vuelo hace unos 2 comandos por tick, unas 3.600 por hora de vuelo. Con el modo caos y 15 drones, unas 27.000 por hora de demo | Vigilar el consumo en el panel de Upstash. El cupo alcanza para las pruebas y la presentación, no para dejarlo corriendo |
| Subida de la fórmula | Hasta 3 archivos de 5 MB en el cuerpo de la petición, en una instancia de 1,75 GB | Pasar a subida directa al storage si aparece un error de memoria |
| Malla de terreno | Muestrear el perfil de cada ruta | La malla vive en memoria (unas decenas de miles de celdas) y se consulta sin ir a la base |

## Cómo se mide

- **REST:** p95 de los endpoints de la cola, el detalle del pedido y la autorización, con 5 a 15 vuelos activos.
- **Telemetría:** intervalo real entre ticks en el cliente, con el reloj a x1 y a x8.
- **Resultado:** se registra en `historial/` con la fecha, el entorno y las cifras.
