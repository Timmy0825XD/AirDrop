import { WeatherKind } from '../common/enums/weather-kind.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat, PlannedCorridor, haversineKm } from '../routing/routing.rules';

/**
 * RF-32: clima simulado por celdas. Una celda es un círculo (centro y radio)
 * con un tipo y una duración en hora simulada. Las crea la consola o el modo
 * caos; no hay datos de clima reales.
 *
 * El viento se modela con física simple: el dron vuela a su velocidad en el
 * aire y el viento le suma o le resta a lo largo del tramo. El consumo del
 * crucero va con el tiempo en el aire, así que por km sube en la proporción
 * velocidad en el aire / velocidad sobre el suelo. La lluvia suma un 10 %.
 */

/** Límites del Wingcopter 198 (fuente 19 de `context/sustentacion/fuentes.md`). */
export const WIND_SUSTAINED_LIMIT_MS = 15;
export const WIND_GUST_LIMIT_MS = 20;

/** RF-32: con lluvia el crucero gasta un 10 % más. */
export const RAIN_BURN_FACTOR = 1.1;

/** La tormenta, para rutas, es un polígono de 16 lados. */
export const STORM_POLYGON_SIDES = 16;

/** Con viento en contra el dron nunca baja de esta fracción de su velocidad. */
const MIN_GROUND_SPEED_RATIO = 0.3;

/** Cada cuánto se mira el clima a lo largo de un corredor. */
const SAMPLE_KM = 0.25;

export const WEATHER_STORM_BLOCKS =
  'Hay una tormenta sobre el corredor: no se vuela hasta que pase.';
export const WEATHER_WIND_BLOCKS =
  'El viento pasa de 15 m/s sostenidos o 20 m/s en ráfagas sobre el corredor.';

export type WeatherCellView = {
  id: string;
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  /** Solo viento: velocidad sostenida y de ráfaga, en m/s. */
  windSpeedMs: number | null;
  windGustMs: number | null;
  /** Solo viento: de dónde sopla, en grados (0 = del norte, 90 = del este). */
  windFromDeg: number | null;
  startsAt: Date;
  endsAt: Date;
};

export function isActive(cell: WeatherCellView, now: Date): boolean {
  return cell.startsAt <= now && now < cell.endsAt;
}

export function activeCells(
  cells: WeatherCellView[],
  now: Date,
): WeatherCellView[] {
  return cells.filter((cell) => isActive(cell, now));
}

export function cellContains(cell: WeatherCellView, point: LngLat): boolean {
  return (
    haversineKm(
      { longitude: cell.longitude, latitude: cell.latitude },
      point,
    ) <= cell.radiusKm
  );
}

/** La tormenta como polígono cerrado, para que el planificador la rodee. */
export function stormPolygon(cell: WeatherCellView): GeoJsonPolygon {
  const latDegPerKm = 1 / 111.32;
  const lngDegPerKm = 1 / (111.32 * Math.cos((cell.latitude * Math.PI) / 180));
  const ring: number[][] = [];
  for (let side = 0; side < STORM_POLYGON_SIDES; side += 1) {
    const angle = (2 * Math.PI * side) / STORM_POLYGON_SIDES;
    ring.push([
      cell.longitude + Math.cos(angle) * cell.radiusKm * lngDegPerKm,
      cell.latitude + Math.sin(angle) * cell.radiusKm * latDegPerKm,
    ]);
  }
  ring.push(ring[0]);
  return { type: 'Polygon', coordinates: [ring] };
}

export function stormPolygons(cells: WeatherCellView[]): GeoJsonPolygon[] {
  return cells
    .filter((cell) => cell.kind === WeatherKind.STORM)
    .map(stormPolygon);
}

/** Rumbo de `from` a `to`, en grados (0 = norte, 90 = este). */
export function bearingDeg(from: LngLat, to: LngLat): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const y =
    Math.sin(toRad(to.longitude - from.longitude)) *
    Math.cos(toRad(to.latitude));
  const x =
    Math.cos(toRad(from.latitude)) * Math.sin(toRad(to.latitude)) -
    Math.sin(toRad(from.latitude)) *
      Math.cos(toRad(to.latitude)) *
      Math.cos(toRad(to.longitude - from.longitude));
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

/**
 * Cuánto empuja el viento a lo largo del tramo, en km/h: positivo a favor,
 * negativo en contra. El viento que sopla "del norte" va hacia el sur.
 */
export function tailwindKmh(cell: WeatherCellView, trackDeg: number): number {
  if (cell.windSpeedMs == null || cell.windFromDeg == null) {
    return 0;
  }
  const towardDeg = (cell.windFromDeg + 180) % 360;
  const angle = ((towardDeg - trackDeg) * Math.PI) / 180;
  return cell.windSpeedMs * 3.6 * Math.cos(angle);
}

export type FlightConditions = {
  groundSpeedKmh: number;
  /**
   * Multiplica el gasto de crucero por tiempo: la lluvia lo sube un 10 %.
   * El viento no entra aquí: cambia la velocidad, y con ella los km por tick.
   */
  burnFactor: number;
  windMs: number;
  gustMs: number;
  overLimit: boolean;
};

/** Las condiciones donde va el dron, con su rumbo y su velocidad en el aire. */
export function conditionsAt(
  cells: WeatherCellView[],
  point: LngLat,
  trackDeg: number,
  airspeedKmh: number,
): FlightConditions {
  let tailwind = 0;
  let windMs = 0;
  let gustMs = 0;
  let rain = false;
  for (const cell of cells) {
    if (!cellContains(cell, point)) {
      continue;
    }
    if (cell.kind === WeatherKind.RAIN || cell.kind === WeatherKind.STORM) {
      rain = true;
    }
    if (cell.kind === WeatherKind.WIND && (cell.windSpeedMs ?? 0) > windMs) {
      // Si se pisan dos celdas de viento, manda la más fuerte.
      windMs = cell.windSpeedMs ?? 0;
      gustMs = cell.windGustMs ?? windMs;
      tailwind = tailwindKmh(cell, trackDeg);
    }
  }
  return {
    groundSpeedKmh: Math.max(
      airspeedKmh * MIN_GROUND_SPEED_RATIO,
      airspeedKmh + tailwind,
    ),
    burnFactor: rain ? RAIN_BURN_FACTOR : 1,
    windMs,
    gustMs,
    overLimit: windMs > WIND_SUSTAINED_LIMIT_MS || gustMs > WIND_GUST_LIMIT_MS,
  };
}

export type CorridorWeather = {
  /** El clima deja volar todo el corredor. */
  flyable: boolean;
  reason: string | null;
  /**
   * Km que "cuesta" el crucero con el clima: los del corredor por
   * velocidad en el aire / velocidad sobre el suelo, y por la lluvia.
   */
  energyKm: number;
  cruiseMs: number;
};

/** RF-11 y RF-32: el clima a lo largo de un corredor, muestreado cada 250 m. */
export function corridorWeather(
  corridor: PlannedCorridor,
  cells: WeatherCellView[],
  airspeedKmh: number,
): CorridorWeather {
  let energyKm = 0;
  let cruiseMs = 0;
  let overLimit = false;
  let storm = false;
  const coordinates = corridor.coordinates;
  for (let index = 1; index < coordinates.length; index += 1) {
    const start = toLngLat(coordinates[index - 1]);
    const end = toLngLat(coordinates[index]);
    const segmentKm = haversineKm(start, end);
    const track = bearingDeg(start, end);
    const samples = Math.max(1, Math.ceil(segmentKm / SAMPLE_KM));
    for (let step = 0; step < samples; step += 1) {
      const ratio = (step + 0.5) / samples;
      const point = {
        longitude: start.longitude + (end.longitude - start.longitude) * ratio,
        latitude: start.latitude + (end.latitude - start.latitude) * ratio,
      };
      const km = segmentKm / samples;
      const here = conditionsAt(cells, point, track, airspeedKmh);
      storm ||= cells.some(
        (cell) => cell.kind === WeatherKind.STORM && cellContains(cell, point),
      );
      overLimit ||= here.overLimit;
      const hours = km / here.groundSpeedKmh;
      cruiseMs += hours * 3_600_000;
      energyKm += hours * airspeedKmh * here.burnFactor;
    }
  }
  const reason = storm
    ? WEATHER_STORM_BLOCKS
    : overLimit
      ? WEATHER_WIND_BLOCKS
      : null;
  return {
    flyable: reason == null,
    reason,
    energyKm: Math.round(energyKm * 100) / 100,
    cruiseMs,
  };
}

function toLngLat(pair: [number, number]): LngLat {
  return { longitude: pair[0], latitude: pair[1] };
}
