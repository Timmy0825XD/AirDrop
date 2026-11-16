import type { LayerSpecification, StyleSpecification } from "maplibre-gl";
import type { Theme } from "@/lib/theme";

/**
 * El fondo del mapa: teselas vectoriales de OpenFreeMap (gratis, sin clave),
 * repintadas con los colores de la app. Vectorial quiere decir calles y
 * nombres nítidos en cualquier zoom. Si OpenFreeMap no responde, queda el
 * gris de Esri (raster) para que el radar no se quede sin fondo.
 */

const OPENFREEMAP = "https://tiles.openfreemap.org/styles";
const ESRI = "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas";

type Palette = {
  ground: string;
  water: string;
  green: string;
  building: string;
  minor: string;
  major: string;
  motorway: string;
  casing: string;
  label: string;
  waterLabel: string;
  halo: string;
  border: string;
};

/** Iguales a `--ground` y vecinos de la app: el mapa es el fondo, no compite. */
const PALETTES: Record<Theme, Palette> = {
  dark: {
    ground: "#1d2023",
    water: "#22323a",
    green: "#1f2629",
    building: "#25292d",
    minor: "#2b2f33",
    major: "#353a3f",
    motorway: "#41474d",
    casing: "#1d2023",
    label: "#8e959b",
    waterLabel: "#5f7d86",
    halo: "#1d2023",
    border: "#4a5056",
  },
  light: {
    ground: "#efece5",
    water: "#c6dbdf",
    green: "#e3e6da",
    building: "#e2ded5",
    minor: "#ffffff",
    major: "#ffffff",
    motorway: "#fbf3df",
    casing: "#d6d1c6",
    label: "#5c6268",
    waterLabel: "#4f7a83",
    halo: "#efece5",
    border: "#a9a397",
  },
};

/** El color de una capa del estilo base según lo que dibuja. */
function recolor(layer: LayerSpecification, p: Palette): LayerSpecification {
  const id = layer.id;
  const paint = { ...(("paint" in layer && layer.paint) || {}) } as Record<string, unknown>;
  const is = (...words: string[]) => words.some((word) => id.includes(word));
  switch (layer.type) {
    case "background":
      paint["background-color"] = p.ground;
      break;
    case "fill":
      if (is("water")) paint["fill-color"] = p.water;
      else if (is("building", "aeroway")) paint["fill-color"] = p.building;
      else if (is("park", "wood", "grass", "landcover", "landuse")) paint["fill-color"] = p.green;
      else paint["fill-color"] = p.ground;
      delete paint["fill-outline-color"];
      break;
    case "line":
      if (is("water")) paint["line-color"] = p.water;
      else if (is("boundary")) paint["line-color"] = p.border;
      else if (is("casing")) paint["line-color"] = p.casing;
      else if (is("motorway", "trunk")) paint["line-color"] = p.motorway;
      else if (is("major", "primary", "secondary", "tertiary", "aeroway")) paint["line-color"] = p.major;
      else paint["line-color"] = p.minor;
      break;
    case "symbol":
      if ("text-color" in paint || "text-field" in (layer.layout ?? {})) {
        paint["text-color"] = is("water") ? p.waterLabel : p.label;
        paint["text-halo-color"] = p.halo;
        paint["text-halo-width"] = 1.2;
        paint["text-halo-blur"] = 0.4;
      }
      // Los íconos del estilo (escudos de vía, puntos de pueblo) sobran en el radar.
      paint["icon-opacity"] = 0;
      break;
    case "raster":
      // El relieve sombreado, apenas: da forma a la Sierra sin ensuciar.
      paint["raster-opacity"] = 0.12;
      break;
  }
  return { ...layer, paint } as LayerSpecification;
}

/** El estilo vectorial del tema, ya con los colores de la app. */
export async function loadVectorStyle(theme: Theme): Promise<StyleSpecification> {
  const url = process.env.NEXT_PUBLIC_MAP_STYLE_URL ?? `${OPENFREEMAP}/${theme === "light" ? "positron" : "dark"}`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Estilo del mapa: ${response.status}`);
  const style = (await response.json()) as StyleSpecification;
  const palette = PALETTES[theme];
  return { ...style, layers: style.layers.map((layer) => recolor(layer, palette)) };
}

/** El respaldo: el gris de Esri en raster, del tono del tema. */
export function fallbackStyle(theme: Theme): StyleSpecification {
  const tone = theme === "light" ? "Light" : "Dark";
  const light = theme === "light";
  return {
    version: 8,
    sources: {
      base: {
        type: "raster",
        tiles: [`${ESRI}/World_${tone}_Gray_Base/MapServer/tile/{z}/{y}/{x}`],
        tileSize: 256,
        maxzoom: 16,
        attribution: "Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors",
      },
      labels: {
        type: "raster",
        tiles: [`${ESRI}/World_${tone}_Gray_Reference/MapServer/tile/{z}/{y}/{x}`],
        tileSize: 256,
        maxzoom: 16,
      },
    },
    layers: [
      { id: "ground", type: "background", paint: { "background-color": PALETTES[theme].ground } },
      {
        id: "base",
        type: "raster",
        source: "base",
        paint: {
          "raster-opacity": light ? 0.85 : 0.6,
          "raster-saturation": -1,
          "raster-brightness-max": light ? 1 : 0.72,
        },
      },
      {
        id: "labels",
        type: "raster",
        source: "labels",
        paint: { "raster-opacity": light ? 0.8 : 0.55, "raster-saturation": -1 },
      },
    ],
  };
}
