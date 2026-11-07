# AirDrop Radar (web)

Vista web en tiempo real del ecosistema, tipo Flightradar, y **consola de simulación** para proyectar en una TV (RU-32). Solo para el **administrador**. Muestra las centrales en el mapa, los drones en vuelo y, al tocar uno, su ruta. Desde la consola se maneja el reloj del sistema y se sigue cada paso del flujo.

- **Reloj simulado (RF-31):** en la barra, la hora del sistema y los botones Pausa, x1, x2, x4 y x8. Cambian el reloj de todo el sistema, también el de la app en los celulares.
- **Línea de tiempo (RF-39):** a la izquierda, plegable, cada paso del flujo con el más reciente arriba. Incluye la decisión del motor con su explicación. Al tocar un paso, el mapa va a donde pasó y, si el dron sigue volando, abre su vuelo.
- **Alertas pendientes (RF-39):** arriba, las alertas de vuelo abiertas. Al tocar una, el mapa va al dron.
- **Reiniciar (RF-40):** deja el escenario de `pnpm seed:demo` como al empezar. Pide confirmación porque borra todos los pedidos de las centrales de la demo.

- **Eventos sobre el mapa (CU-38):** abajo, una barra flotante como la de la app: Viento, Lluvia, Tormenta, Zona temporal y Pico. Se elige uno, se toca el mapa en el centro y una tarjeta pide el radio, la duración y, para el viento, la fuerza y de dónde sopla; el círculo se ve antes de lanzarlo. Cada clima o zona activa lleva un chip en el mapa; al tocarlo, un panel la describe y permite terminarla.
- **Incidentes (RF-34):** en el panel de un dron en vuelo, el catálogo de fallas, choques y pérdidas. Los graves piden un segundo toque. El sistema decide qué hace el dron; el aviso dice qué eligió.
- **Apagón (RF-36):** en el panel de una central, dejarla sin energía por un tiempo o devolvérsela.
- **Pico de urgencias (RF-36):** en la barra de eventos. Se toca el centro, se ajusta el radio (hasta 3 km) y cuántas urgencias (de 2 a 15), y el generador las crea seguidas dentro del círculo. El aviso dice cuántas salieron y, si faltó alguna, por qué.
- **Actores simulados (RF-37, CU-39):** el botón con el robot de la barra superior. Enciende o apaga el despachador automático (autoriza a los 10 s y confirma la carga a los 20 s, en cualquier central) y el flujo continuo de pedidos (uno cada 3 min de reloj, 70 % urgencias), y genera una urgencia o un programado a pedido. El número en el botón dice cuántos están encendidos. El receptor simulado no tiene interruptor: siempre atiende los pedidos generados.
- **Modo caos (RF-38, CU-40):** en la misma tarjeta, abajo. Apagado por defecto. Encendido sortea clima, fallas, choques y eventos del entorno; la intensidad baja, media o alta pone un evento cada ~15, ~8 o ~4 min de reloj. Lo grave (dron perdido, choque grave, dos motores, apagón) solo sale en alta. Con el caos encendido, el botón de la barra se pone rojo y dice "Caos · media"; cada evento sorteado sale en la línea de tiempo con la marca **Caos**.

- **Centrales:** un cuadro sólido con el ícono de su tipo y, debajo, su nombre con dos cifras: drones en vuelo y pedidos en cola. Tipos: (hospital, clínica, farmacia, banco de sangre, vacunación). Elegida toma el azul de selección. Sin energía, se apaga en ámbar con un rayo tachado. Al tocarlo, un panel a la derecha con su flota (drones y estado), pedidos en marcha, inventario (vencimientos, cadena de frío y cuarentena) y contacto.
- **Drones en vuelo:** la silueta del dron (claro de ida, ámbar de regreso, rojo con alerta) con su bloque de datos al lado, que se desliza entre cada dato de telemetría y gira hacia donde va. Sin enlace se ve atenuado: su posición es estimada. Un dron caído o aterrizado de emergencia queda marcado donde bajó, con la cuenta del rescate.
- **Un dron elegido:** panel con batería, velocidad, altitud, temperatura, ETA, fase, alertas y la ruta de ida (línea continua) y de regreso (discontinua) sobre el mapa. Si la ruta cambió en el aire, la de antes queda punteada en gris.
- **Zonas restringidas:** las geovallas del operador en rosado, con un interruptor arriba. Las temporales, en ámbar, con lo que les falta para vencer. El clima, en círculos: viento y lluvia en azul cielo (el viento con su flecha) y la tormenta en rosado, latiendo.
- Se cierra el panel con la `✕`, con `Esc` o tocando el mapa vacío.

## Cómo correrla

Requisitos: Node 20 o superior y pnpm. El backend (`backend/`) corriendo en `http://localhost:3000`, con Redis (sin Redis no hay telemetría y los drones no se mueven).

```powershell
cd web
pnpm install
pnpm dev          # http://localhost:3001
```

Entrar con la cuenta del **administrador** (`ADMIN_EMAIL` y `ADMIN_PASSWORD` del `.env` del backend). Otro rol recibe "El radar es solo para el administrador".

La consola necesita el backend con `CONTROL_ENABLED=true`. Sin esa variable el radar funciona igual, y la barra dice "Consola apagada".

| Variable (opcional) | Para qué |
| --- | --- |
| `NEXT_PUBLIC_API_URL` | Dirección del backend. Por defecto `http://localhost:3000` |
| `NEXT_PUBLIC_TILES_URL` | Plantilla de mapa base `{z}/{y}/{x}`. Por defecto, mapa oscuro de Esri (sin API key) |

Las `NEXT_PUBLIC_*` se leen al **arrancar** o al hacer `pnpm build`: si se cambian, hay que reiniciar.

### Modo demostración

`http://localhost:3001/?demo=1` abre el radar **sin backend ni sesión**, con tres centrales y dos drones inventados que vuelan solos. Su consola es un ensayo: el reloj, los interruptores de los actores y del caos (que ahí no sortea nada) y el reinicio solo cambian lo que se ve en ese navegador y no mandan nada al backend. Generar pedidos, incidentes y apagones necesita el backend. Sirve para ensayar o como plan B si algo falla en la presentación. La barra superior dice **Modo demostración** todo el tiempo para que nadie lo tome por datos reales.

Para tener drones de verdad en el mapa: `pnpm seed:demo` en `backend/`, arrancar Nest con Redis y despachar un pedido (autorizar y confirmar la carga) con el despachador de una central, o encender el despachador automático y generar una urgencia desde la consola.

## Apariencia

"Carta aeronáutica": una consola de operación sobre un mapa, oscura porque se proyecta en una TV. No copia la app Flutter.

- **Estructura en franjas:** una barra fina arriba (marca, hora simulada grande con su velocidad, estado y mandos), un riel fijo a la izquierda (tres cifras de la flota y la línea de tiempo como bitácora), el mapa al resto y el inspector a la derecha solo cuando se elige algo. La leyenda está plegada en un botón junto a los mandos del mapa.
- **Superficies sólidas** con líneas finas de 1 px; sin vidrio, brillos ni degradados. Botones de 8 px de radio, paneles de 12.
- **Tipografía:** Geist para todo y Geist Mono para las cifras (hora, identificadores, métricas), con números tabulares.
- **Color con trabajo:** azul señal para lo elegido y las acciones; magenta de carta, rayado, para las zonas restringidas; verde, ámbar y rojo solo para el estado. El mapa base de Esri va apagado y sin color para que resalte lo vivo.
- **Dron:** una silueta vectorial (`src/lib/drone-shape.ts`, la misma del ícono y la marca) que apunta a su rumbo, con su bloque de datos al lado (identificador; altura, velocidad y batería) unido por una línea guía, como en un radar. Se lee sin pasar el mouse.
- **Íconos** dibujados a mano en una cuadrícula de 24 con un solo trazo (`src/components/icons.tsx`).
- **Movimiento** solo para estado: entradas cortas (180–220 ms, `ease-out` fuerte), botones que ceden al presionarlos y el anillo del dron que espera rescate. Con "reducir movimiento" se apagan.

Los tokens viven en `src/app/globals.css` (y `src/lib/theme.ts` para el mapa). Las skills de diseño usadas (`impeccable` y las de Emil Kowalski) están en `web/.claude/skills/`.

## Cómo está hecha

```
src/
  app/                 página única (Next.js App Router)
  components/
    RadarApp.tsx       sesión o demostración
    Dashboard.tsx      mapa + barra + línea de tiempo + alertas + panel
    ClockControl.tsx   hora simulada, velocidades y reinicio
    EventDock.tsx      barra y tarjeta para lanzar clima y zonas (CU-38)
    EventPanel.tsx     el clima o la zona elegidos, y terminarlos
    IncidentActions.tsx el catálogo de incidentes de un dron (RF-34)
    BrandMark.tsx      el dron de la marca, como en la app
    TimelinePanel.tsx  línea de tiempo (RF-39)
    AlertsTray.tsx     alertas pendientes
    ResetDialog.tsx    confirmación del reinicio
    map/               RadarMap, marcadores (central, clima, zona, rescate), ícono y movimiento del dron
    icons.tsx          íconos de trazo (dron, tipos de central, métricas)
    ui.tsx             piezas compartidas (estados, cifras, botones, panel)
    Legend.tsx         leyenda de colores del mapa
    HubPanel.tsx       panel de la central
    FlightPanel.tsx    panel del vuelo
  lib/
    source.ts          de dónde vienen los datos (REST + socket) y su contrato
    demo.ts            el mismo contrato, con datos simulados
    use-radar.ts       estado del radar: foto inicial + eventos del socket
    use-console.ts     estado y órdenes de la consola
    sim-time.ts        hora simulada en pantalla
    geo.ts             círculos en el mapa (clima y zona de 16 lados) y la rosa de los vientos
    use-polled.ts      recarga de los paneles
```

- **Datos:** `GET /radar/snapshot` al abrir y cada 30 s, y el socket `/telemetry` para todo lo demás. Se entra a la sala del radar con `subscribe-radar` (solo admin) y llegan `radar-telemetry`, `radar-status`, `radar-alert`, `radar-timeline`, `radar-reset`, `radar-weather`, `radar-geofence`, `radar-incident`, `radar-hub-outage` y `radar-reroute`; `clock` llega a todos. Es el **mismo** WebSocket de la app móvil, no hay un segundo canal.
- **Consola:** `GET`/`PUT /control/clock`, `GET /control/timeline` al abrir, `GET /control/alerts` cada 5 s y `POST /control/reset`. Eventos: `GET`/`POST /control/weather` y `DELETE /control/weather/:id`; `GET`/`POST /control/geofences` y `DELETE /control/geofences/:id`; `GET /control/incidents` y `POST /control/drones/:droneId/incidents`; `POST`/`DELETE /control/hubs/:hubId/outage`. Actores: `GET`/`PUT /control/actors` (también llega por el socket como `radar-actors`), `POST /control/actors/orders` y `POST /control/actors/surge`. Caos: `GET`/`PUT /control/chaos` (también `radar-chaos` por el socket). El clima y los incidentes se releen cuando el socket avisa (y cada 30 s); las zonas temporales y los apagones vienen en el snapshot. La hora la manda el backend; entre un aviso y otro, `lib/sim-time.ts` la avanza con la velocidad que trae.
- **Detalle:** `GET /radar/hubs/:id` (cada 5 s mientras el panel está abierto) y `GET /radar/flights/:orderId` (la ruta, cada 8 s).
- **Eficiencia:** los mensajes del socket se agrupan y se repinta unas 4 veces por segundo, no en cada mensaje. Los drones van en una capa WebGL del mapa que se actualiza con un bucle propio (~30 cuadros por segundo) sin pasar por React, así 50 vuelos no repintan el árbol de componentes; si ningún dron se mueve, el bucle no toca el mapa. Los marcadores de central no se repintan con cada dato del socket. El mapa solo dibuja la ruta del vuelo elegido.
- **Privacidad:** el radar no muestra a quién va una entrega ni, si va a una persona, qué medicamento lleva. En los traslados entre centrales sí dice el insumo. La ruta de un vuelo a una persona termina en su punto de entrega.

### Mapa base y worker

`scripts/copy-maplibre.mjs` copia el worker de MapLibre a `public/maplibre/` antes de `dev` y `build` (esa carpeta se ignora en git). Sin eso el mapa no carga con Turbopack.

El mapa base de Esri necesita internet. Sin conexión, las centrales y los drones se ven pero sobre fondo vacío.

## Comandos

```powershell
pnpm dev      # desarrollo en :3001
pnpm build    # compilación de producción
pnpm start    # sirve la compilación en :3001
pnpm lint
```
