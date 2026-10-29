import type { Map as MaplibreMap } from "maplibre-gl";
import { COLORS } from "@/lib/theme";

export const ICON_OUTBOUND = "drone-outbound";
export const ICON_RETURN = "drone-return";
export const ICON_ALERT = "drone-alert";

const SIZE = 64;

/** Un avión que apunta al norte; el mapa lo gira con `icon-rotate`. */
function draw(color: string): ImageData {
  const canvas = document.createElement("canvas");
  canvas.width = SIZE;
  canvas.height = SIZE;
  const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
  const half: Array<[number, number]> = [
    [0, -26],
    [6, -8],
    [26, 6],
    [26, 12],
    [6, 8],
    [5, 20],
    [12, 25],
    [12, 29],
    [0, 26],
  ];
  ctx.translate(SIZE / 2, SIZE / 2);
  ctx.beginPath();
  half.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)));
  [...half].reverse().forEach(([x, y]) => ctx.lineTo(-x, y));
  ctx.closePath();
  ctx.fillStyle = color;
  ctx.strokeStyle = COLORS.ink;
  ctx.lineWidth = 3;
  ctx.lineJoin = "round";
  ctx.stroke();
  ctx.fill();
  return ctx.getImageData(0, 0, SIZE, SIZE);
}

/** Registra los tres íconos del dron (ida, regreso y con alerta). */
export function addDroneIcons(map: MaplibreMap) {
  const icons: Array<[string, string]> = [
    [ICON_OUTBOUND, COLORS.outbound],
    [ICON_RETURN, COLORS.returning],
    [ICON_ALERT, COLORS.alert],
  ];
  for (const [name, color] of icons) {
    if (!map.hasImage(name)) map.addImage(name, draw(color));
  }
}
