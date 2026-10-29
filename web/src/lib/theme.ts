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
  /** Fondo del mapa bajo los tiles: tiñe el gris de Esri hacia el grafito. */
  mapTint: "#0d181c",
  ink: "#0b0e10",
  /** Cuerpo grafito y metal del dron (droneShell y droneMetal de la app). */
  shell: ["#5a636b", "#2b3136", "#121517"],
  metal: "#3a4248",
  /** Disco translúcido de las hélices y sombra del ícono. */
  rotor: "rgba(11, 14, 16, 0.72)",
  shadow: "rgba(0, 0, 0, 0.55)",
} as const;
