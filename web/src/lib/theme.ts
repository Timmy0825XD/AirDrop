/**
 * Colores que el mapa necesita en JS (lienzo y capas de MapLibre). Son los
 * mismos tokens de globals.css: la carta aeronáutica.
 */
export const COLORS = {
  /** El dron de ida es la aeronave neutra; el color se guarda para el estado. */
  outbound: "#e7ecf1",
  returning: "#f0b445",
  alert: "#ff6b6b",
  accent: "#7aa7ff",
  /** Zona restringida: el magenta de las cartas. */
  geofence: "#e05ad6",
  /** RF-36: geovalla temporal (ámbar, vence sola). */
  zone: "#f0b445",
  /** RF-32: viento y lluvia (cielo) y tormenta (rojo de peligro). */
  wind: "#8ec5ff",
  rain: "#8ec5ff",
  storm: "#ff6b6b",
  /** Ruta de antes de cambiarla en el aire (RF-33). */
  previous: "#8c99a6",
  /** El fondo bajo los tiles: el mapa se apaga hacia el grafito de la consola. */
  ground: "#090c10",
  /** Contorno del dron y del bloque de datos, para leerse sobre cualquier calle. */
  ink: "#090c10",
  text: "#e7ecf1",
  muted: "#8c99a6",
  /** Placa del nombre de una central (los mismos `--panel` y `--line`). */
  panel: "#0f141a",
  line: "#2a333e",
} as const;
