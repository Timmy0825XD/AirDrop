# AirDrop Radar (web)

Vista web en tiempo real del ecosistema, tipo Flightradar: las centrales en el mapa, los drones en vuelo y, al tocar uno, su ruta. Es solo lectura y solo para el **administrador**.

- **Centrales:** un mosaico de vidrio con el ícono de su tipo (hospital, clínica, farmacia, banco de sangre, vacunación) y cuántos drones tiene en vuelo. Al tocarlo, un panel a la derecha con su flota (drones y estado), pedidos en marcha, inventario (vencimientos, cadena de frío y cuarentena) y contacto.
- **Drones en vuelo:** un cuadricóptero visto desde arriba (turquesa de ida, ámbar de regreso, rosado con alerta), que se desliza entre cada dato de telemetría y gira hacia donde va. Sin ruta, hasta que se elige uno.
- **Un dron elegido:** panel con batería, velocidad, altitud, temperatura, ETA, fase, alertas y la ruta de ida (línea continua) y de regreso (discontinua) sobre el mapa.
- **Zonas restringidas:** las geovallas, con un interruptor arriba.
- Se cierra el panel con la `✕`, con `Esc` o tocando el mapa vacío.

## Cómo correrla

Requisitos: Node 20 o superior y pnpm. El backend (`backend/`) corriendo en `http://localhost:3000`, con Redis (sin Redis no hay telemetría y los drones no se mueven).

```powershell
cd web
pnpm install
pnpm dev          # http://localhost:3001
```

Entrar con la cuenta del **administrador** (`ADMIN_EMAIL` y `ADMIN_PASSWORD` del `.env` del backend). Otro rol recibe "El radar es solo para el administrador".

| Variable (opcional) | Para qué |
| --- | --- |
| `NEXT_PUBLIC_API_URL` | Dirección del backend. Por defecto `http://localhost:3000` |
| `NEXT_PUBLIC_TILES_URL` | Plantilla de mapa base `{z}/{y}/{x}`. Por defecto, mapa oscuro de Esri (sin API key) |

Las `NEXT_PUBLIC_*` se leen al **arrancar** o al hacer `pnpm build`: si se cambian, hay que reiniciar.

### Modo demostración

`http://localhost:3001/?demo=1` abre el radar **sin backend ni sesión**, con tres centrales y dos drones inventados que vuelan solos. Sirve para ensayar o como plan B si algo falla en la presentación. La barra superior dice **Modo demostración** todo el tiempo para que nadie lo tome por datos reales.

Para tener drones de verdad en el mapa: `pnpm seed:demo` en `backend/`, arrancar Nest con Redis y despachar un pedido (autorizar y confirmar la carga) con el despachador de una central.

## Apariencia

La misma identidad de la app Flutter, "Grafito y turquesa": fondo grafito con velos de cielo y turquesa, vidrio esmerilado en la barra y los paneles, acento turquesa en degradado y la tipografía Space Grotesk. Los colores viven en `src/app/globals.css` (y `src/lib/theme.ts` para el mapa) y copian `frontend/lib/theme/app_palette.dart`.

## Cómo está hecha

```
src/
  app/                 página única (Next.js App Router)
  components/
    RadarApp.tsx       sesión o demostración
    Dashboard.tsx      mapa + barra + panel
    map/               RadarMap, marcadores de central, ícono y movimiento del dron
    icons.tsx          íconos de trazo (dron, tipos de central, métricas)
    ui.tsx             piezas de vidrio compartidas (pastillas, cifras, panel)
    Legend.tsx         leyenda de colores del mapa
    HubPanel.tsx       panel de la central
    FlightPanel.tsx    panel del vuelo
  lib/
    source.ts          de dónde vienen los datos (REST + socket) y su contrato
    demo.ts            el mismo contrato, con datos simulados
    use-radar.ts       estado del radar: foto inicial + eventos del socket
    use-polled.ts      recarga de los paneles
```

- **Datos:** `GET /radar/snapshot` al abrir y cada 30 s, y el socket `/telemetry` para todo lo demás. Se entra a la sala del radar con `subscribe-radar` (solo admin) y llegan `radar-telemetry`, `radar-status` y `radar-alert`. Es el **mismo** WebSocket de la app móvil, no hay un segundo canal.
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
