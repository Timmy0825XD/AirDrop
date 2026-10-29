// MapLibre carga su worker desde una URL: con Turbopack no la resuelve solo,
// así que se sirve desde /public (carpeta ignorada por git, se regenera).
import { copyFileSync, mkdirSync } from "node:fs";

const from = new URL("../node_modules/maplibre-gl/dist/", import.meta.url);
const to = new URL("../public/maplibre/", import.meta.url);
mkdirSync(to, { recursive: true });
for (const file of ["maplibre-gl-worker.mjs", "maplibre-gl-shared.mjs"]) {
  copyFileSync(new URL(file, from), new URL(file, to));
}
