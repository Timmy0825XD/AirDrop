import { IncidentKind } from '../common/enums/incident-kind.enum';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { Random } from './sim-actors.rules';

/**
 * RF-38: el modo caos. Reglas puras: cada cuánto sortea, qué familia, qué
 * evento y dónde. Quien aplica el evento es su dominio (clima, geovallas,
 * centrales, reloj de vuelo, generador), igual que si lo lanzara la consola.
 */

export type ChaosIntensity = 'low' | 'medium' | 'high';

export const CHAOS_INTENSITIES: ChaosIntensity[] = ['low', 'medium', 'high'];

/** Un evento cada ~15, ~8 o ~4 min simulados, según la intensidad. */
export const CHAOS_EVERY_MS: Record<ChaosIntensity, number> = {
  low: 15 * 60_000,
  medium: 8 * 60_000,
  high: 4 * 60_000,
};

/** Cada cuánto mira si ya le toca (ms simulados). */
export const CHAOS_SWEEP_MS = 10_000;

export const CHAOS_STATE_KEY = 'control:chaos';

export type ChaosState = {
  enabled: boolean;
  intensity: ChaosIntensity;
  /** Quien lo encendió: los eventos quedan a su nombre, como los de la consola. */
  enabledByUserId: string | null;
};

export const CHAOS_OFF: ChaosState = {
  enabled: false,
  intensity: 'medium',
  enabledByUserId: null,
};

export type ChaosChange = { enabled?: boolean; intensity?: ChaosIntensity };

export const INTENSITY_LABEL: Record<ChaosIntensity, string> = {
  low: 'baja',
  medium: 'media',
  high: 'alta',
};

export function parseChaosState(raw: string | null): ChaosState {
  if (!raw) {
    return { ...CHAOS_OFF };
  }
  try {
    const value = JSON.parse(raw) as Partial<ChaosState>;
    return {
      enabled: value.enabled === true,
      intensity: CHAOS_INTENSITIES.includes(value.intensity as ChaosIntensity)
        ? (value.intensity as ChaosIntensity)
        : CHAOS_OFF.intensity,
      enabledByUserId:
        typeof value.enabledByUserId === 'string'
          ? value.enabledByUserId
          : null,
    };
  } catch {
    return { ...CHAOS_OFF };
  }
}

export function applyChaosChange(
  state: ChaosState,
  change: ChaosChange,
  userId: string,
): ChaosState {
  const enabled = change.enabled ?? state.enabled;
  return {
    enabled,
    intensity: change.intensity ?? state.intensity,
    enabledByUserId: enabled ? userId : null,
  };
}

/** Lo que cambió, dicho para la línea de tiempo. */
export function chaosChangeText(
  before: ChaosState,
  after: ChaosState,
): string | null {
  if (!after.enabled) {
    return before.enabled ? 'Modo caos apagado' : null;
  }
  if (!before.enabled) {
    return `Modo caos encendido, intensidad ${INTENSITY_LABEL[after.intensity]}`;
  }
  return before.intensity !== after.intensity
    ? `Modo caos a intensidad ${INTENSITY_LABEL[after.intensity]}`
    : null;
}

/** El próximo sorteo: el promedio de la intensidad, entre la mitad y 1,5 veces. */
export function nextChaosAt(
  now: Date,
  intensity: ChaosIntensity,
  random: Random,
): Date {
  const every = CHAOS_EVERY_MS[intensity];
  return new Date(now.getTime() + Math.round(every * (0.5 + random())));
}

export type ChaosFamily = 'weather' | 'drone' | 'collision' | 'environment';

/** Clima 40, dron 35, entorno 20, choques 5. */
export const FAMILY_WEIGHTS: Record<ChaosFamily, number> = {
  weather: 40,
  drone: 35,
  environment: 20,
  collision: 5,
};

/** Los graves (pierden flota o apagan una central) son el 10 % de su familia. */
export const SEVERE_SHARE = 0.1;

export type EnvironmentKind =
  'temporary_geofence' | 'surge' | 'no_show' | 'hub_outage';

export type ChaosEvent =
  | { family: 'weather'; kind: WeatherKind }
  | { family: 'drone' | 'collision'; kind: IncidentKind }
  | { family: 'environment'; kind: EnvironmentKind };

/** Elige uno según su peso. Los pesos en 0 no salen nunca. */
export function weighted<T>(
  options: ReadonlyArray<readonly [T, number]>,
  random: Random,
): T {
  const usable = options.filter(([, weight]) => weight > 0);
  const total = usable.reduce((sum, [, weight]) => sum + weight, 0);
  let point = random() * total;
  for (const [value, weight] of usable) {
    point -= weight;
    if (point < 0) {
      return value;
    }
  }
  return usable[usable.length - 1][0];
}

/** Sin drones en el aire no hay fallas ni choques: su peso se reparte. */
export function pickFamily(random: Random, anyAirborne: boolean): ChaosFamily {
  return weighted(
    [
      ['weather', FAMILY_WEIGHTS.weather],
      ['drone', anyAirborne ? FAMILY_WEIGHTS.drone : 0],
      ['environment', FAMILY_WEIGHTS.environment],
      ['collision', anyAirborne ? FAMILY_WEIGHTS.collision : 0],
    ],
    random,
  );
}

/** Hora de Colombia (UTC−5, sin horario de verano). */
export function colombiaHour(now: Date): number {
  return (now.getUTCHours() + 24 - 5) % 24;
}

/** Las tormentas, tres veces más probables de 14:00 a 18:00 (la tarde). */
export function weatherWeights(
  now: Date,
): ReadonlyArray<readonly [WeatherKind, number]> {
  const hour = colombiaHour(now);
  const afternoon = hour >= 14 && hour < 18;
  return [
    [WeatherKind.WIND, 40],
    [WeatherKind.RAIN, 40],
    [WeatherKind.STORM, afternoon ? 60 : 20],
  ];
}

/** Reparte el 10 % de la familia entre los graves, si la intensidad los admite. */
function withSevere<T>(
  normal: ReadonlyArray<readonly [T, number]>,
  severe: readonly T[],
  allowSevere: boolean,
): Array<readonly [T, number]> {
  const base = normal.filter(([, weight]) => weight > 0);
  if (!allowSevere || !severe.length) {
    return [...base];
  }
  const total = base.reduce((sum, [, weight]) => sum + weight, 0);
  const each = (total * SEVERE_SHARE) / (1 - SEVERE_SHARE) / severe.length;
  return [...base, ...severe.map((kind) => [kind, each] as const)];
}

export function droneWeights(
  intensity: ChaosIntensity,
  coldLoad: boolean,
): Array<readonly [IncidentKind, number]> {
  return withSevere(
    [
      [IncidentKind.BATTERY_DEGRADED, 25],
      [IncidentKind.MOTOR_FAILURE, 20],
      [IncidentKind.GPS_LOSS_MINOR, 20],
      [IncidentKind.LINK_LOSS, 15],
      [IncidentKind.GPS_LOSS_MAJOR, 10],
      [IncidentKind.COOLING_FAILURE, coldLoad ? 10 : 0],
    ],
    [IncidentKind.DUAL_MOTOR_FAILURE, IncidentKind.DRONE_LOST],
    intensity === 'high',
  );
}

export function collisionWeights(
  intensity: ChaosIntensity,
): Array<readonly [IncidentKind, number]> {
  return withSevere(
    [[IncidentKind.COLLISION_MINOR, 1]],
    [IncidentKind.COLLISION_MAJOR],
    intensity === 'high',
  );
}

export function environmentWeights(
  intensity: ChaosIntensity,
): Array<readonly [EnvironmentKind, number]> {
  return withSevere<EnvironmentKind>(
    [
      ['temporary_geofence', 40],
      ['surge', 30],
      ['no_show', 30],
    ],
    ['hub_outage'],
    intensity === 'high',
  );
}

export function pickEvent(
  family: ChaosFamily,
  intensity: ChaosIntensity,
  now: Date,
  coldLoad: boolean,
  random: Random,
): ChaosEvent {
  if (family === 'weather') {
    return { family, kind: weighted(weatherWeights(now), random) };
  }
  if (family === 'drone') {
    return {
      family,
      kind: weighted(droneWeights(intensity, coldLoad), random),
    };
  }
  if (family === 'collision') {
    return { family, kind: weighted(collisionWeights(intensity), random) };
  }
  return { family, kind: weighted(environmentWeights(intensity), random) };
}

/**
 * La falla le cae al dron más gastado: el que lleva más vuelos desde su
 * último mantenimiento. Entre iguales, al azar.
 */
export function pickWornDrone<T extends { flightsSinceMaintenance: number }>(
  drones: readonly T[],
  random: Random,
): T | null {
  if (!drones.length) {
    return null;
  }
  const most = Math.max(
    ...drones.map((drone) => drone.flightsSinceMaintenance),
  );
  const worn = drones.filter((drone) => drone.flightsSinceMaintenance === most);
  return worn[Math.min(worn.length - 1, Math.floor(random() * worn.length))];
}

const DURATIONS_MIN = [15, 30, 45, 60];

export function pickDuration(random: Random): number {
  return DURATIONS_MIN[
    Math.min(
      DURATIONS_MIN.length - 1,
      Math.floor(random() * DURATIONS_MIN.length),
    )
  ];
}

/** Lo que se le pide a `WeatherService`; el viento lleva fuerza y dirección. */
export type ChaosWeatherInput = {
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  durationMin: number;
  windSpeedMs?: number;
  windGustMs?: number;
  windFromDeg?: number;
};

/** Una celda de clima del caos: entre 1,5 y 3,5 km; viento de 8 a 22 m/s. */
export function chaosWeather(
  kind: WeatherKind,
  center: { latitude: number; longitude: number },
  random: Random,
): ChaosWeatherInput {
  const radiusKm = Math.round((1.5 + random() * 2) * 10) / 10;
  const base = {
    kind,
    latitude: center.latitude,
    longitude: center.longitude,
    radiusKm,
    durationMin: pickDuration(random),
  };
  if (kind !== WeatherKind.WIND) {
    return base;
  }
  const windSpeedMs = Math.round(8 + random() * 14);
  return {
    ...base,
    windSpeedMs,
    windGustMs: Math.min(50, Math.round(windSpeedMs * 1.3)),
    windFromDeg: 45 * Math.floor(random() * 8),
  };
}

/** De 3 a 5 urgencias en el pico del caos (a mano llega a 15). */
export function chaosSurgeCount(random: Random): number {
  return 3 + Math.min(2, Math.floor(random() * 3));
}

/** Apagón del caos: de 15 a 45 minutos. */
export function chaosOutageMinutes(random: Random): number {
  return 15 + Math.min(30, Math.floor(random() * 31));
}

/** Un círculo de 16 lados, como la geovalla temporal que dibuja la web. */
export function circlePolygon(
  center: { latitude: number; longitude: number },
  radiusKm: number,
): GeoJsonPolygon {
  const latDegPerKm = 1 / 111.32;
  const lngDegPerKm =
    1 / (111.32 * Math.cos((center.latitude * Math.PI) / 180));
  const ring: number[][] = [];
  for (let side = 0; side < 16; side += 1) {
    const angle = (2 * Math.PI * side) / 16;
    ring.push([
      round6(center.longitude + Math.cos(angle) * radiusKm * lngDegPerKm),
      round6(center.latitude + Math.sin(angle) * radiusKm * latDegPerKm),
    ]);
  }
  ring.push(ring[0]);
  return { type: 'Polygon', coordinates: [ring] };
}

function round6(value: number): number {
  return Math.round(value * 1e6) / 1e6;
}

const WEATHER_TITLE: Record<WeatherKind, string> = {
  [WeatherKind.WIND]: 'viento',
  [WeatherKind.RAIN]: 'lluvia',
  [WeatherKind.STORM]: 'tormenta',
};

const ENVIRONMENT_TITLE: Record<EnvironmentKind, string> = {
  temporary_geofence: 'zona restringida temporal',
  surge: 'pico de urgencias',
  no_show: 'nadie retirará un paquete',
  hub_outage: 'central sin energía',
};

const INCIDENT_TITLE: Partial<Record<IncidentKind, string>> = {
  [IncidentKind.BATTERY_DEGRADED]: 'batería degradada',
  [IncidentKind.MOTOR_FAILURE]: 'falla de un motor',
  [IncidentKind.DUAL_MOTOR_FAILURE]: 'falla de dos motores',
  [IncidentKind.GPS_LOSS_MINOR]: 'pérdida parcial de GPS',
  [IncidentKind.GPS_LOSS_MAJOR]: 'pérdida total de GPS',
  [IncidentKind.LINK_LOSS]: 'pérdida de enlace',
  [IncidentKind.COOLING_FAILURE]: 'falla de la refrigeración',
  [IncidentKind.COLLISION_MINOR]: 'choque leve',
  [IncidentKind.COLLISION_MAJOR]: 'choque grave',
  [IncidentKind.DRONE_LOST]: 'dron perdido',
};

/** "Caos: tormenta", para la línea de tiempo. */
export function chaosTitle(event: ChaosEvent): string {
  if (event.family === 'weather') {
    return `Caos: ${WEATHER_TITLE[event.kind]}`;
  }
  if (event.family === 'environment') {
    return `Caos: ${ENVIRONMENT_TITLE[event.kind]}`;
  }
  return `Caos: ${INCIDENT_TITLE[event.kind] ?? event.kind}`;
}
