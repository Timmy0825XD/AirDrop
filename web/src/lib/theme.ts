/**
 * Colores que el mapa necesita en JS (lienzo y capas de MapLibre). Son los
 * mismos de globals.css y de la paleta oscura de la app Flutter.
 */
export const COLORS = {
  outbound: "#6ed6d9",
  returning: "#fbbf6a",
  alert: "#ff8fa3",
  accent: "#4fc3c9",
  geofence: "#ff8fa3",
  /** RF-36: geovalla temporal (ámbar, vence sola). */
  zone: "#fbbf6a",
  /** RF-32: viento y lluvia (cielo) y tormenta (rosado de peligro). */
  wind: "#a9c8e6",
  rain: "#a9c8e6",
  storm: "#ff8fa3",
  /** Ruta de antes de cambiarla en el aire (RF-33). */
  previous: "#a6b4ba",
  /** Fondo del mapa bajo los tiles: tiñe el gris de Esri hacia el grafito. */
  mapTint: "#0d181c",
  ink: "#0b0e10",
  /** El disco del dron sobre el mapa (`backdrop.last` al 85 %). */
  disc: "rgba(11, 14, 16, 0.85)",
  /** El dron de la marca en oscuro (DroneMark de la app). */
  markBody: "#eef3f5",
  markWing: "#d4dde1",
  markBoom: "#a6b4ba",
  port: "#ff8fa3",
  starboard: "#4ade80",
  shadow: "rgba(0, 0, 0, 0.55)",
} as const;
