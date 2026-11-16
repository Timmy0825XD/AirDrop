/**
 * Colores que el mapa necesita en JS (lienzo y capas de MapLibre). Son los
 * mismos tokens de globals.css, en los dos temas de la app.
 */
export type Theme = "dark" | "light";

const DARK = {
  /** El dron de ida es la aeronave neutra; el color se guarda para el estado. */
  outbound: "#ecedee",
  returning: "#e8b45a",
  alert: "#f0958e",
  accent: "#5dbfb4",
  /** Zona restringida. */
  geofence: "#f0958e",
  /** RF-43: zonas legales donde no se vuela. */
  noFly: "#f0958e",
  urban: "#a9aeb3",
  coordinated: "#e8b45a",
  /** RF-45: un punto de entrega disponible y uno que no. */
  point: "#6fcf97",
  pointOff: "#7d848a",
  /** RF-36: geovalla temporal (ámbar, vence sola). */
  zone: "#e8b45a",
  /** RF-32: viento y lluvia (cielo) y tormenta (rojo de peligro). */
  wind: "#8fb4d6",
  rain: "#8fb4d6",
  storm: "#f0958e",
  /** Niebla: gris claro, no volable. */
  fog: "#c3ccd6",
  /** RF-36: un dron no identificado. No es de la red. */
  contact: "#e05ad6",
  /** Ruta de antes de cambiarla en el aire (RF-33). */
  previous: "#a9aeb3",
  /** El fondo bajo los tiles. */
  ground: "#17191b",
  /** Contorno del dron y del bloque de datos, para leerse sobre cualquier calle. */
  ink: "#17191b",
  text: "#ecedee",
  muted: "#a9aeb3",
  /** Placa del nombre de una central (los mismos `--panel` y `--line`). */
  panel: "#222528",
  line: "#3a3f44",
};

const LIGHT: typeof DARK = {
  outbound: "#1b1d1f",
  returning: "#8f5200",
  alert: "#b3261e",
  accent: "#0a4e58",
  geofence: "#b3261e",
  noFly: "#b3261e",
  urban: "#5c6268",
  coordinated: "#8f5200",
  point: "#177a45",
  pointOff: "#7a8086",
  zone: "#8f5200",
  wind: "#2f5f8a",
  rain: "#2f5f8a",
  storm: "#b3261e",
  fog: "#7a8086",
  contact: "#a3239a",
  previous: "#5c6268",
  ground: "#f5f4f1",
  ink: "#ffffff",
  text: "#1b1d1f",
  muted: "#5c6268",
  panel: "#ffffff",
  line: "#dad6cd",
};

/**
 * Los colores vigentes. El mapa los lee al montarse; `setMapTheme` los cambia
 * y el mapa se vuelve a montar con el tema nuevo.
 */
export const COLORS: typeof DARK = { ...DARK };

export function setMapTheme(theme: Theme): void {
  Object.assign(COLORS, theme === "light" ? LIGHT : DARK);
}
