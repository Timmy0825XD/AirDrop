import type { Map as MaplibreMap } from "maplibre-gl";
import { DRONE_BODY, DRONE_ROTOR_R, DRONE_ROTORS, DRONE_WINGS } from "@/lib/drone-shape";
import { COLORS } from "@/lib/theme";

export const ICON_OUTBOUND = "drone-outbound";
export const ICON_RETURN = "drone-return";
export const ICON_ALERT = "drone-alert";
export const ICON_WIND = "wind-arrow";
/** Rayado de las zonas restringidas, como en una carta aeronáutica. */
export const PATTERN_HATCH = "hatch-magenta";

const PIXEL_RATIO = 2;
/** El dron mide 32 px en pantalla: se lee en la TV sin tapar las calles. */
const DRONE_PX = 32;

function canvas(width: number, height: number) {
  const element = document.createElement("canvas");
  element.width = Math.ceil(width * PIXEL_RATIO);
  element.height = Math.ceil(height * PIXEL_RATIO);
  const ctx = element.getContext("2d") as CanvasRenderingContext2D;
  ctx.scale(PIXEL_RATIO, PIXEL_RATIO);
  return ctx;
}

/**
 * La silueta del dron (la de `drone-shape.ts`), rellena con el color de su
 * estado y con un contorno del fondo para separarla del mapa. Apunta al
 * norte; el mapa la gira con `icon-rotate`.
 */
function drawDrone(color: string): ImageData {
  const ctx = canvas(DRONE_PX, DRONE_PX);
  ctx.scale(DRONE_PX / 24, DRONE_PX / 24);
  const shapes = [
    new Path2D(DRONE_BODY),
    ...DRONE_WINGS.map((wing) => new Path2D(wing)),
    ...DRONE_ROTORS.map(([cx, cy]) => {
      const rotor = new Path2D();
      rotor.arc(cx, cy, DRONE_ROTOR_R, 0, Math.PI * 2);
      return rotor;
    }),
  ];
  ctx.lineJoin = "round";
  ctx.strokeStyle = COLORS.ink;
  ctx.lineWidth = 1.6;
  for (const shape of shapes) ctx.stroke(shape);
  ctx.fillStyle = color;
  for (const shape of shapes) ctx.fill(shape);
  return ctx.getImageData(0, 0, DRONE_PX * PIXEL_RATIO, DRONE_PX * PIXEL_RATIO);
}

/** Flecha hacia el norte: hacia dónde empuja el viento (RF-32). */
function drawArrow(): ImageData {
  const size = 36;
  const ctx = canvas(size, size);
  ctx.translate(size / 2, size / 2);
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  ctx.strokeStyle = COLORS.wind;
  ctx.lineWidth = 2.2;
  ctx.beginPath();
  ctx.moveTo(0, 13);
  ctx.lineTo(0, -12);
  ctx.moveTo(-6.5, -5.5);
  ctx.lineTo(0, -12);
  ctx.lineTo(6.5, -5.5);
  ctx.stroke();
  return ctx.getImageData(0, 0, size * PIXEL_RATIO, size * PIXEL_RATIO);
}

/** Líneas a 45° que se repiten: el relleno de una zona restringida. */
function drawHatch(): ImageData {
  const size = 10;
  const ctx = canvas(size, size);
  ctx.strokeStyle = withAlpha(COLORS.geofence, 0.42);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  for (const offset of [-size, 0, size]) {
    ctx.moveTo(offset, size);
    ctx.lineTo(offset + size, 0);
  }
  ctx.stroke();
  return ctx.getImageData(0, 0, size * PIXEL_RATIO, size * PIXEL_RATIO);
}

export function withAlpha(hex: string, alpha: number): string {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${n >> 16}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

/** Registra los tres drones (ida, regreso y con alerta), la flecha y el rayado. */
export function addDroneIcons(map: MaplibreMap) {
  const icons: Array<[string, string]> = [
    [ICON_OUTBOUND, COLORS.outbound],
    [ICON_RETURN, COLORS.returning],
    [ICON_ALERT, COLORS.alert],
  ];
  for (const [name, color] of icons) {
    if (!map.hasImage(name)) map.addImage(name, drawDrone(color), { pixelRatio: PIXEL_RATIO });
  }
  if (!map.hasImage(ICON_WIND)) {
    map.addImage(ICON_WIND, drawArrow(), { pixelRatio: PIXEL_RATIO });
  }
  if (!map.hasImage(PATTERN_HATCH)) {
    map.addImage(PATTERN_HATCH, drawHatch(), { pixelRatio: PIXEL_RATIO });
  }
}

/* El bloque de datos de cada dron, como en un radar. */

/** Del centro del dron sale la línea guía hacia el noreste. */
export const LEADER = { dx: 22, dy: 18 };
const LINE_1 = 15;
const LINE_2 = 13;
const GAP = 4;

export type DataBlock = { title: string; detail: string; color: string };

/** Las fuentes que usan los bloques y las placas, para pedirlas antes de dibujar. */
export const BLOCK_FONTS = () => [
  `600 ${LINE_1}px ${mono()}`,
  `500 ${LINE_2}px ${mono()}`,
  `500 ${PLATE_NAME}px ${sans()}`,
  `500 ${PLATE_DETAIL}px ${mono()}`,
];

let sansFamily: string | null = null;
function sans(): string {
  if (sansFamily) return sansFamily;
  const declared = getComputedStyle(document.documentElement).getPropertyValue("--font-geist").trim();
  sansFamily = declared || "system-ui, sans-serif";
  return sansFamily;
}

let monoFamily: string | null = null;
/** La familia de Geist Mono que cargó next/font (su nombre lleva un sufijo). */
function mono(): string {
  if (monoFamily) return monoFamily;
  const declared = getComputedStyle(document.documentElement)
    .getPropertyValue("--font-geist-mono")
    .trim();
  monoFamily = declared || "ui-monospace, monospace";
  return monoFamily;
}

/**
 * Dibuja la línea guía y las dos líneas de texto (identificador; altura,
 * velocidad y batería) sin caja: el texto lleva un contorno del fondo para
 * leerse sobre el mapa. La imagen se ancla abajo a la izquierda, en el dron.
 */
export function drawDataBlock(block: DataBlock): { image: ImageData; width: number; height: number } {
  const probe = canvas(1, 1);
  const family = mono();
  probe.font = `600 ${LINE_1}px ${family}`;
  const titleWidth = probe.measureText(block.title).width;
  probe.font = `500 ${LINE_2}px ${family}`;
  const detailWidth = probe.measureText(block.detail).width;

  const textLeft = LEADER.dx + 6;
  const width = Math.ceil(textLeft + Math.max(titleWidth, detailWidth) + 4);
  const height = Math.ceil(LEADER.dy + LINE_1 + GAP + LINE_2 / 2 + 4);
  const ctx = canvas(width, height);

  // Línea guía: del dron (abajo a la izquierda) al pie del bloque.
  const baseY = height;
  const elbowY = baseY - LEADER.dy;
  ctx.lineCap = "round";
  ctx.strokeStyle = COLORS.ink;
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(1, baseY - 1);
  ctx.lineTo(LEADER.dx, elbowY);
  ctx.stroke();
  ctx.strokeStyle = withAlpha(block.color, 0.75);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  ctx.moveTo(1, baseY - 1);
  ctx.lineTo(LEADER.dx, elbowY);
  ctx.stroke();

  const write = (text: string, y: number, font: string, color: string) => {
    ctx.font = font;
    ctx.lineJoin = "round";
    ctx.strokeStyle = COLORS.ink;
    ctx.lineWidth = 3;
    ctx.strokeText(text, textLeft, y);
    ctx.fillStyle = color;
    ctx.fillText(text, textLeft, y);
  };
  const titleY = elbowY - LINE_2 - GAP + 2;
  write(block.title, titleY, `600 ${LINE_1}px ${family}`, block.color);
  write(block.detail, elbowY + 3, `500 ${LINE_2}px ${family}`, COLORS.muted);

  return {
    image: ctx.getImageData(0, 0, width * PIXEL_RATIO, height * PIXEL_RATIO),
    width,
    height,
  };
}

/* La placa con el nombre de una central, debajo de su cuadro. */

const PLATE_NAME = 13;
const PLATE_DETAIL = 12;

export type HubPlate = { name: string; detail: string | null; detailColor: string };

/**
 * El nombre de la central (y, si hay, cuántos vuelan o esperan) en una placa
 * sólida. Va en una capa del mapa, no en HTML: así cede su lugar cuando
 * choca con el bloque de datos de un dron.
 */
export function drawHubPlate(plate: HubPlate): ImageData {
  const probe = canvas(1, 1);
  probe.font = `500 ${PLATE_NAME}px ${sans()}`;
  const nameWidth = probe.measureText(plate.name).width;
  probe.font = `500 ${PLATE_DETAIL}px ${mono()}`;
  const detailWidth = plate.detail ? probe.measureText(plate.detail).width : 0;
  const padX = 8;
  const gap = plate.detail ? 17 : 0;
  const width = Math.ceil(padX * 2 + nameWidth + gap + detailWidth) + 2;
  const height = 26;
  const ctx = canvas(width, height);

  ctx.beginPath();
  ctx.roundRect(0.5, 0.5, width - 1, height - 1, 6);
  ctx.fillStyle = withAlpha(COLORS.panel, 0.94);
  ctx.fill();
  ctx.strokeStyle = COLORS.line;
  ctx.lineWidth = 1;
  ctx.stroke();

  ctx.textBaseline = "middle";
  ctx.font = `500 ${PLATE_NAME}px ${sans()}`;
  ctx.fillStyle = COLORS.text;
  ctx.fillText(plate.name, padX + 1, height / 2 + 0.5);
  if (plate.detail) {
    const x = padX + 1 + nameWidth + gap / 2;
    ctx.fillStyle = COLORS.line;
    ctx.fillRect(Math.round(x), 6, 1, height - 12);
    ctx.font = `500 ${PLATE_DETAIL}px ${mono()}`;
    ctx.fillStyle = plate.detailColor;
    ctx.fillText(plate.detail, x + gap / 2, height / 2 + 0.5);
  }
  return ctx.getImageData(0, 0, width * PIXEL_RATIO, height * PIXEL_RATIO);
}

export { PIXEL_RATIO };
