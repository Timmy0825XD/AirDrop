import {
  REGION_REFERENCE,
  colombiaDate,
  fitsDaylight,
  isDaylight,
  sunTimes,
} from './daylight.rules';

/** Hora de Colombia de un instante, "HH:MM". */
function colombiaClock(instant: Date): string {
  return new Date(instant.getTime() - 5 * 3_600_000)
    .toISOString()
    .slice(11, 16);
}

const minutes = (clock: string) => {
  const [h, m] = clock.split(':').map(Number);
  return h * 60 + m;
};

describe('Salida y puesta del sol en Valledupar (RF-44, NOAA)', () => {
  // Referencia independiente: api.sunrise-sunset.org para 10.435 N,
  // 73.249 W, en hora de Colombia (±3 min).
  it.each([
    ['2026-01-15', '06:15', '17:50'],
    ['2026-06-21', '05:33', '18:17'],
    ['2026-11-14', '05:48', '17:27'],
  ])('%s: sale ~%s y se pone ~%s', (date, sunrise, sunset) => {
    const sun = sunTimes(new Date(`${date}T17:00:00.000Z`), REGION_REFERENCE);
    expect(sun.date).toBe(date);
    expect(
      Math.abs(minutes(colombiaClock(sun.sunrise)) - minutes(sunrise)),
    ).toBeLessThanOrEqual(3);
    expect(
      Math.abs(minutes(colombiaClock(sun.sunset)) - minutes(sunset)),
    ).toBeLessThanOrEqual(3);
  });

  it('la fecha es la de Colombia, no la UTC', () => {
    // 2026-11-15 02:00 UTC es todavía el 14 en Colombia (21:00).
    expect(colombiaDate(new Date('2026-11-15T02:00:00.000Z'))).toBe(
      '2026-11-14',
    );
  });

  it('a mediodía hay luz; a las 21:00 no', () => {
    expect(
      isDaylight(new Date('2026-11-14T17:00:00.000Z'), REGION_REFERENCE),
    ).toBe(true);
    expect(
      isDaylight(new Date('2026-11-15T02:00:00.000Z'), REGION_REFERENCE),
    ).toBe(false);
  });

  it('un vuelo de 40 min a las 16:55 no cabe antes de la puesta (17:27); a las 16:30 sí', () => {
    const forty = 40 * 60_000;
    expect(
      fitsDaylight(
        new Date('2026-11-14T21:55:00.000Z'),
        REGION_REFERENCE,
        forty,
      ),
    ).toBe(false);
    expect(
      fitsDaylight(
        new Date('2026-11-14T21:30:00.000Z'),
        REGION_REFERENCE,
        forty,
      ),
    ).toBe(true);
  });

  it('antes de la salida del sol no se despacha', () => {
    expect(
      fitsDaylight(
        new Date('2026-11-14T10:00:00.000Z'),
        REGION_REFERENCE,
        60_000,
      ),
    ).toBe(false);
  });
});
