import { REGION_REFERENCE, sunTimes } from './daylight.rules';
import { DaylightService } from './daylight.service';

// 14-nov-2026 en Valledupar: sale ~05:48 y se pone ~17:27 (hora de Colombia).
const NOON = new Date('2026-11-14T17:00:00.000Z'); // 12:00
const NIGHT = new Date('2026-11-15T02:00:00.000Z'); // 21:00
const NEAR_SUNSET = new Date('2026-11-14T22:10:00.000Z'); // 17:10
const MIN = 60_000;

describe('DaylightService (RF-44): no hay despegue de noche', () => {
  const daylight = new DaylightService();

  it('sin punto usa la referencia de la región', () => {
    expect(daylight.sun(NOON)).toEqual(sunTimes(NOON, REGION_REFERENCE));
    expect(daylight.isDaylight(NOON)).toBe(true);
    expect(daylight.isDaylight(NIGHT)).toBe(false);
  });

  it('la misión cabe a mediodía y no cabe de noche', () => {
    expect(daylight.fits(NOON, REGION_REFERENCE, 30 * MIN)).toBe(true);
    expect(daylight.fits(NIGHT, REGION_REFERENCE, 30 * MIN)).toBe(false);
  });

  it('de día, una misión que terminaría después de la puesta no cabe', () => {
    expect(daylight.isDaylight(NEAR_SUNSET)).toBe(true);
    expect(daylight.fits(NEAR_SUNSET, REGION_REFERENCE, 5 * MIN)).toBe(true);
    expect(daylight.fits(NEAR_SUNSET, REGION_REFERENCE, 60 * MIN)).toBe(false);
  });
});
