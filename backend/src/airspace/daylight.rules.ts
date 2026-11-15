import { LngLat } from '../routing/routing.rules';

/**
 * RF-44: solo de día (RAC 100.220(a)(3), `context/operacion/condiciones-de-vuelo.md`).
 * Salida y puesta del sol con las ecuaciones de la calculadora solar de la
 * NOAA (Global Monitoring Laboratory), sin API. Precisión de un par de
 * minutos, de sobra para una ventana de vuelo.
 */

/** Colombia no tiene horario de verano: UTC−5 todo el año. */
const COLOMBIA_OFFSET_MS = -5 * 60 * 60 * 1000;
/** El sol "sale" cuando su borde superior toca el horizonte, con refracción. */
const SUNRISE_ZENITH_DEG = 90.833;

export const NIGHT_NO_FLIGHT =
  'No se vuela de noche: el dron no alcanza a volver al nodo antes de la puesta del sol (RAC 100.220).';

export const NIGHT_EMERGENCY =
  'Es de noche y la norma no deja volar entregas: va la alternativa terrestre (RAC 100.220).';

/** Centro de referencia de la región para la hora del sol (ARP de SKVP). */
export const REGION_REFERENCE: LngLat = {
  latitude: 10.43513,
  longitude: -73.2494,
};

export type SunTimes = {
  /** Fecha de calendario en Colombia (AAAA-MM-DD). */
  date: string;
  sunrise: Date;
  sunset: Date;
};

const rad = (deg: number) => (deg * Math.PI) / 180;
const deg = (value: number) => (value * 180) / Math.PI;

/** La fecha de calendario en Colombia del instante dado. */
export function colombiaDate(now: Date): string {
  return new Date(now.getTime() + COLOMBIA_OFFSET_MS)
    .toISOString()
    .slice(0, 10);
}

/** Salida y puesta del sol en `point` el día de Colombia que contiene `now`. */
export function sunTimes(now: Date, point: LngLat): SunTimes {
  const date = colombiaDate(now);
  // Mediodía en Colombia de ese día: 17:00 UTC.
  const noonUtc = new Date(`${date}T17:00:00.000Z`);
  const julianDay = noonUtc.getTime() / 86_400_000 + 2440587.5;
  const t = (julianDay - 2451545) / 36525;
  const meanLong =
    (((280.46646 + t * (36000.76983 + t * 0.0003032)) % 360) + 360) % 360;
  const meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  const eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  const center =
    Math.sin(rad(meanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
    Math.sin(rad(2 * meanAnomaly)) * (0.019993 - 0.000101 * t) +
    Math.sin(rad(3 * meanAnomaly)) * 0.000289;
  const trueLong = meanLong + center;
  const omega = 125.04 - 1934.136 * t;
  const apparentLong = trueLong - 0.00569 - 0.00478 * Math.sin(rad(omega));
  const meanObliquity =
    23 +
    (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  const obliquity = meanObliquity + 0.00256 * Math.cos(rad(omega));
  const declination = deg(
    Math.asin(Math.sin(rad(obliquity)) * Math.sin(rad(apparentLong))),
  );
  const y = Math.tan(rad(obliquity / 2)) ** 2;
  const equationOfTimeMin =
    4 *
    deg(
      y * Math.sin(2 * rad(meanLong)) -
        2 * eccentricity * Math.sin(rad(meanAnomaly)) +
        4 *
          eccentricity *
          y *
          Math.sin(rad(meanAnomaly)) *
          Math.cos(2 * rad(meanLong)) -
        0.5 * y * y * Math.sin(4 * rad(meanLong)) -
        1.25 * eccentricity * eccentricity * Math.sin(2 * rad(meanAnomaly)),
    );
  const hourAngle = deg(
    Math.acos(
      Math.cos(rad(SUNRISE_ZENITH_DEG)) /
        (Math.cos(rad(point.latitude)) * Math.cos(rad(declination))) -
        Math.tan(rad(point.latitude)) * Math.tan(rad(declination)),
    ),
  );
  const solarNoonMin = 720 - 4 * point.longitude - equationOfTimeMin;
  const midnightUtc = Date.parse(`${date}T00:00:00.000Z`);
  return {
    date,
    sunrise: new Date(midnightUtc + (solarNoonMin - 4 * hourAngle) * 60_000),
    sunset: new Date(midnightUtc + (solarNoonMin + 4 * hourAngle) * 60_000),
  };
}

/** ¿Hay luz del día en `point` ahora? */
export function isDaylight(now: Date, point: LngLat): boolean {
  const sun = sunTimes(now, point);
  return now >= sun.sunrise && now <= sun.sunset;
}

/**
 * RF-44: se despacha solo si despega con sol y aterriza de regreso en el
 * nodo antes de la puesta: `missionMs` es ida, espera y regreso.
 */
export function fitsDaylight(
  now: Date,
  point: LngLat,
  missionMs: number,
): boolean {
  const sun = sunTimes(now, point);
  return (
    now >= sun.sunrise && now.getTime() + missionMs <= sun.sunset.getTime()
  );
}
