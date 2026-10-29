import type { Map as MaplibreMap } from "maplibre-gl";
import { COLORS } from "@/lib/theme";

export const ICON_OUTBOUND = "drone-outbound";
export const ICON_RETURN = "drone-return";
export const ICON_ALERT = "drone-alert";

/** Se dibuja en 48 unidades y al doble de resolución para pantallas nítidas. */
const UNITS = 48;
const PIXEL_RATIO = 2;

/** Brazos en X: el centro de cada hélice. */
const ROTORS: Array<[number, number]> = [
  [-12.5, -12.5],
  [12.5, -12.5],
  [-12.5, 12.5],
  [12.5, 12.5],
];

/** El mismo color, un 25 % más oscuro: el final del degradado del cuerpo. */
function shade(hex: string): string {
  const n = parseInt(hex.slice(1), 16);
  const c = (v: number) => Math.round(v * 0.75);
  return `rgb(${c(n >> 16)}, ${c((n >> 8) & 255)}, ${c(n & 255)})`;
}

/**
 * Un cuadricóptero visto desde arriba: cuerpo del color de la misión, hélices
 * teñidas y una flecha en la nariz. Apunta al norte; el mapa lo gira con
 * `icon-rotate`.
 */
function draw(color: string): ImageData {
  const canvas = document.createElement("canvas");
  canvas.width = UNITS * PIXEL_RATIO;
  canvas.height = UNITS * PIXEL_RATIO;
  const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
  ctx.scale(PIXEL_RATIO, PIXEL_RATIO);
  ctx.translate(UNITS / 2, UNITS / 2);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";

  // Sombra suave para despegarlo del mapa.
  ctx.shadowColor = COLORS.shadow;
  ctx.shadowBlur = 4;
  ctx.shadowOffsetY = 1.5;

  // Brazos: un trazo oscuro y encima el metal.
  for (const width of [5, 3]) {
    ctx.strokeStyle = width === 5 ? COLORS.ink : COLORS.metal;
    ctx.lineWidth = width;
    ctx.beginPath();
    for (const [x, y] of ROTORS) {
      ctx.moveTo(0, 0);
      ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.shadowColor = "transparent";
  }

  // Hélices: disco teñido del color, aro y motor al centro.
  for (const [x, y] of ROTORS) {
    ctx.beginPath();
    ctx.arc(x, y, 8.5, 0, Math.PI * 2);
    ctx.fillStyle = COLORS.rotor;
    ctx.fill();
    ctx.globalAlpha = 0.28;
    ctx.fillStyle = color;
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.lineWidth = 2;
    ctx.strokeStyle = color;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(x, y, 2.6, 0, Math.PI * 2);
    ctx.fillStyle = COLORS.shell[1];
    ctx.fill();
  }

  // Cuerpo: cápsula del color con borde grafito, como el disco del dron
  // en la app (acento en degradado).
  const body = ctx.createLinearGradient(-7, -10, 7, 10);
  body.addColorStop(0, color);
  body.addColorStop(1, shade(color));
  ctx.beginPath();
  ctx.roundRect(-7.5, -10.5, 15, 21, 6);
  ctx.fillStyle = body;
  ctx.fill();
  ctx.lineWidth = 2;
  ctx.strokeStyle = COLORS.ink;
  ctx.stroke();

  // Nariz: hacia dónde va.
  ctx.beginPath();
  ctx.moveTo(0, -7.5);
  ctx.lineTo(4.5, -0.5);
  ctx.lineTo(0, -2.6);
  ctx.lineTo(-4.5, -0.5);
  ctx.closePath();
  ctx.fillStyle = COLORS.ink;
  ctx.fill();

  // Luz de cola.
  ctx.beginPath();
  ctx.arc(0, 5, 1.7, 0, Math.PI * 2);
  ctx.fillStyle = COLORS.ink;
  ctx.fill();

  return ctx.getImageData(0, 0, canvas.width, canvas.height);
}

/** Registra los tres íconos del dron (ida, regreso y con alerta). */
export function addDroneIcons(map: MaplibreMap) {
  const icons: Array<[string, string]> = [
    [ICON_OUTBOUND, COLORS.outbound],
    [ICON_RETURN, COLORS.returning],
    [ICON_ALERT, COLORS.alert],
  ];
  for (const [name, color] of icons) {
    if (!map.hasImage(name)) map.addImage(name, draw(color), { pixelRatio: PIXEL_RATIO });
  }
}
