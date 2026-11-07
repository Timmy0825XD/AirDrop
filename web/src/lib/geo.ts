/** Geometría pequeña para la consola: círculos en el mapa y rumbos. */

const KM_PER_LAT = 110.574;

/**
 * Un círculo de `radiusKm` alrededor del punto, como polígono GeoJSON cerrado
 * (`[longitud, latitud]`). Con 16 lados es la geovalla temporal que se manda
 * al backend (RF-36), igual que la tormenta del backend (`stormPolygon`).
 */
export function circlePolygon(
  latitude: number,
  longitude: number,
  radiusKm: number,
  sides = 48,
): { type: "Polygon"; coordinates: number[][][] } {
  const kmPerLng = 111.32 * Math.cos((latitude * Math.PI) / 180);
  const ring: number[][] = [];
  for (let i = 0; i < sides; i += 1) {
    const angle = (2 * Math.PI * i) / sides;
    ring.push([
      round6(longitude + (radiusKm * Math.sin(angle)) / kmPerLng),
      round6(latitude + (radiusKm * Math.cos(angle)) / KM_PER_LAT),
    ]);
  }
  ring.push(ring[0]);
  return { type: "Polygon", coordinates: [ring] };
}

/** El centro de un polígono (promedio de sus vértices sin repetir el cierre). */
export function polygonCenter(coordinates: number[][][]): [number, number] | null {
  const ring = coordinates[0] ?? [];
  const points = ring.length > 1 ? ring.slice(0, -1) : ring;
  if (!points.length) return null;
  const lng = points.reduce((sum, p) => sum + p[0], 0) / points.length;
  const lat = points.reduce((sum, p) => sum + p[1], 0) / points.length;
  return [lng, lat];
}

/** Los ocho rumbos de la rosa, de dónde sopla el viento. */
export const COMPASS = [
  { deg: 0, short: "N", long: "norte" },
  { deg: 45, short: "NE", long: "noreste" },
  { deg: 90, short: "E", long: "este" },
  { deg: 135, short: "SE", long: "sureste" },
  { deg: 180, short: "S", long: "sur" },
  { deg: 225, short: "SO", long: "suroeste" },
  { deg: 270, short: "O", long: "oeste" },
  { deg: 315, short: "NO", long: "noroeste" },
] as const;

export function compassOf(degrees: number) {
  return COMPASS[Math.round((((degrees % 360) + 360) % 360) / 45) % 8];
}

function round6(value: number) {
  return Math.round(value * 1e6) / 1e6;
}
