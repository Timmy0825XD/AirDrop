import { DaylightService } from './daylight.service';

/** Para pruebas que no tratan de la hora: siempre es de día (antes de RF-44). */
export const ALWAYS_DAY = {
  fits: () => true,
  isDaylight: () => true,
  sun: (now: Date) => ({
    date: now.toISOString().slice(0, 10),
    sunrise: new Date(now.getTime() - 6 * 3_600_000),
    sunset: new Date(now.getTime() + 6 * 3_600_000),
  }),
} as unknown as DaylightService;
