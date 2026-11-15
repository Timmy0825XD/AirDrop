import { LngLat, haversineKm } from '../routing/routing.rules';
import { Random } from './sim-actors.rules';

/** RF-36: cuánto cruza la región un dron no identificado, en minutos simulados. */
export const UNIDENTIFIED_MIN_MINUTES = 5;
export const UNIDENTIFIED_MAX_MINUTES = 30;
/** RF-36: a menos de esto de un corredor activo, el radar avisa. */
export const NEAR_CORRIDOR_KM = 1;
/** Medio largo del cruce cuando la consola no dice por dónde. */
export const CROSSING_HALF_KM = 12;
/** Centro de la red regional (`context/negocio/cobertura.md`). */
export const REGION_CENTER: LngLat = { latitude: 10.4, longitude: -73.25 };

export type UnidentifiedContact = {
  id: string;
  from: LngLat;
  to: LngLat;
  startedAtMs: number;
  endsAtMs: number;
  /** Matrícula del dron propio cuyo corredor tiene cerca, o `null`. */
  nearIdentifier: string | null;
};

const KM_PER_LAT = 110.574;

function kmPerLng(latitude: number): number {
  return 111.32 * Math.cos((latitude * Math.PI) / 180);
}

/** Dónde va, en línea recta y a velocidad constante. */
export function contactPosition(
  contact: Pick<UnidentifiedContact, 'from' | 'to' | 'startedAtMs' | 'endsAtMs'>,
  nowMs: number,
): LngLat {
  const span = contact.endsAtMs - contact.startedAtMs;
  const t =
    span <= 0 ? 1 : Math.max(0, Math.min(1, (nowMs - contact.startedAtMs) / span));
  return {
    latitude: round6(
      contact.from.latitude + (contact.to.latitude - contact.from.latitude) * t,
    ),
    longitude: round6(
      contact.from.longitude +
        (contact.to.longitude - contact.from.longitude) * t,
    ),
  };
}

/** Distancia en km del punto a la polilínea `[lng, lat][]` (plano local). */
export function distanceToPathKm(
  point: LngLat,
  coordinates: number[][],
): number {
  if (!coordinates.length) {
    return Infinity;
  }
  const lngKm = kmPerLng(point.latitude);
  const xy = ([lng, lat]: number[]) => ({
    x: (lng - point.longitude) * lngKm,
    y: (lat - point.latitude) * KM_PER_LAT,
  });
  if (coordinates.length === 1) {
    const only = xy(coordinates[0]);
    return Math.hypot(only.x, only.y);
  }
  let best = Infinity;
  for (let index = 1; index < coordinates.length; index += 1) {
    const a = xy(coordinates[index - 1]);
    const b = xy(coordinates[index]);
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const lengthSq = dx * dx + dy * dy;
    const t =
      lengthSq === 0
        ? 0
        : Math.max(0, Math.min(1, -(a.x * dx + a.y * dy) / lengthSq));
    best = Math.min(best, Math.hypot(a.x + t * dx, a.y + t * dy));
  }
  return best;
}

/** El primer corredor activo que queda a menos de 1 km, si hay uno. */
export function nearCorridor<T extends { coordinates: number[][] }>(
  point: LngLat,
  corridors: T[],
): T | null {
  return (
    corridors.find(
      (corridor) =>
        distanceToPathKm(point, corridor.coordinates) <= NEAR_CORRIDOR_KM,
    ) ?? null
  );
}

/** Un cruce recto que pasa por `through`, en una dirección al azar. */
export function crossingThrough(
  through: LngLat,
  random: Random,
  halfKm = CROSSING_HALF_KM,
): { from: LngLat; to: LngLat } {
  const angle = random() * 2 * Math.PI;
  const dLat = (Math.sin(angle) * halfKm) / KM_PER_LAT;
  const dLng = (Math.cos(angle) * halfKm) / kmPerLng(through.latitude);
  return {
    from: {
      latitude: round6(through.latitude - dLat),
      longitude: round6(through.longitude - dLng),
    },
    to: {
      latitude: round6(through.latitude + dLat),
      longitude: round6(through.longitude + dLng),
    },
  };
}

export function randomContactMinutes(random: Random): number {
  return (
    UNIDENTIFIED_MIN_MINUTES +
    Math.floor(
      random() * (UNIDENTIFIED_MAX_MINUTES - UNIDENTIFIED_MIN_MINUTES + 1),
    )
  );
}

export function contactSpeedKmh(contact: UnidentifiedContact): number {
  const hours = (contact.endsAtMs - contact.startedAtMs) / 3_600_000;
  return hours > 0
    ? Math.round(haversineKm(contact.from, contact.to) / hours)
    : 0;
}

function round6(value: number): number {
  return Math.round(value * 1e6) / 1e6;
}
