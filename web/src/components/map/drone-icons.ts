import type { Map as MaplibreMap } from "maplibre-gl";
import { COLORS } from "@/lib/theme";

export const ICON_OUTBOUND = "drone-outbound";
export const ICON_RETURN = "drone-return";
export const ICON_ALERT = "drone-alert";
export const ICON_WIND = "wind-arrow";

/** Se dibuja en 64 unidades (el disco mide 44) y al doble de resolución. */
const UNITS = 64;
const PIXEL_RATIO = 2;
/** El dron de la marca mide 34 dentro del disco, como en la app. */
const MARK = 34;

/**
 * El dron sobre el mapa, como `DroneMarker` de la app: un disco grafito con
 * el borde y el brillo del color de la misión (turquesa de ida, ámbar de
 * regreso, rosado con alerta) y, dentro, el dron de la marca visto desde
 * arriba (`drone_mark.dart`, grilla de 160). Apunta al norte; el mapa lo gira
 * con `icon-rotate`.
 */
function draw(color: string): ImageData {
  const canvas = document.createElement("canvas");
  canvas.width = UNITS * PIXEL_RATIO;
  canvas.height = UNITS * PIXEL_RATIO;
  const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
  ctx.scale(PIXEL_RATIO, PIXEL_RATIO);
  ctx.translate(UNITS / 2, UNITS / 2);

  // El disco con el brillo del acento.
  ctx.save();
  ctx.shadowColor = withAlpha(color, 0.6);
  ctx.shadowBlur = 16;
  ctx.beginPath();
  ctx.arc(0, 0, 22, 0, Math.PI * 2);
  ctx.fillStyle = COLORS.disc;
  ctx.fill();
  ctx.restore();
  ctx.lineWidth = 1.5;
  ctx.strokeStyle = withAlpha(color, 0.8);
  ctx.stroke();

  // El dron de la marca, en la grilla de 160.
  ctx.save();
  ctx.scale(MARK / 160, MARK / 160);
  const box = (x: number, y: number, w: number, h: number, r: number, fill: string) => {
    ctx.beginPath();
    ctx.roundRect(x, y, w, h, r);
    ctx.fillStyle = fill;
    ctx.fill();
  };
  box(-70, -6, 140, 12, 6, COLORS.markWing);
  box(-8, -40, 16, 80, 8, COLORS.markBody);
  box(-4, -30, 8, 10, 3, withAlpha(color, 0.85));
  box(-40, -52, 7, 104, 3.5, COLORS.markBoom);
  box(33, -52, 7, 104, 3.5, COLORS.markBoom);
  for (const [x, y] of [
    [-36.5, -52],
    [36.5, -52],
    [-36.5, 52],
    [36.5, 52],
  ]) {
    const glow = ctx.createRadialGradient(x, y, 0, x, y, 17);
    glow.addColorStop(0, withAlpha(color, 0.35));
    glow.addColorStop(1, withAlpha(color, 0));
    ctx.beginPath();
    ctx.arc(x, y, 17, 0, Math.PI * 2);
    ctx.fillStyle = glow;
    ctx.fill();
    box(x - 15.5, y - 1.5, 31, 3, 1.5, withAlpha(color, 0.85));
  }
  // Luces de navegación: roja a la izquierda, verde a la derecha.
  for (const [x, light] of [
    [-70, COLORS.port],
    [70, COLORS.starboard],
  ] as const) {
    ctx.beginPath();
    ctx.arc(x, 0, 6, 0, Math.PI * 2);
    ctx.fillStyle = light;
    ctx.fill();
  }
  ctx.restore();

  return ctx.getImageData(0, 0, canvas.width, canvas.height);
}

/** Flecha hacia el norte: hacia dónde empuja el viento (RF-32). */
function drawArrow(): ImageData {
  const size = 40;
  const canvas = document.createElement("canvas");
  canvas.width = size * PIXEL_RATIO;
  canvas.height = size * PIXEL_RATIO;
  const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
  ctx.scale(PIXEL_RATIO, PIXEL_RATIO);
  ctx.translate(size / 2, size / 2);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.strokeStyle = COLORS.wind;
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(0, 14);
  ctx.lineTo(0, -12);
  ctx.moveTo(-8, -4);
  ctx.lineTo(0, -13);
  ctx.lineTo(8, -4);
  ctx.stroke();
  return ctx.getImageData(0, 0, canvas.width, canvas.height);
}

function withAlpha(hex: string, alpha: number): string {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${n >> 16}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

/** Registra los tres íconos del dron (ida, regreso y con alerta) y la flecha del viento. */
export function addDroneIcons(map: MaplibreMap) {
  const icons: Array<[string, string]> = [
    [ICON_OUTBOUND, COLORS.outbound],
    [ICON_RETURN, COLORS.returning],
    [ICON_ALERT, COLORS.alert],
  ];
  for (const [name, color] of icons) {
    if (!map.hasImage(name)) map.addImage(name, draw(color), { pixelRatio: PIXEL_RATIO });
  }
  if (!map.hasImage(ICON_WIND)) {
    map.addImage(ICON_WIND, drawArrow(), { pixelRatio: PIXEL_RATIO });
  }
}
