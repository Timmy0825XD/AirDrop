import { WeatherKind } from '../common/enums/weather-kind.enum';
import {
  isInsideGeofence,
  planCorridor,
  PlannedCorridor,
} from '../routing/routing.rules';
import {
  FlightPhase,
  advanceFlight,
  initialProgress,
} from '../simulation/simulation.rules';
import {
  RAIN_BURN_FACTOR,
  WEATHER_STORM_BLOCKS,
  WEATHER_WIND_BLOCKS,
  WeatherCellView,
  activeCells,
  conditionsAt,
  corridorWeather,
  stormPolygon,
  tailwindKmh,
} from './weather.rules';

const NOW = new Date('2026-11-05T15:00:00.000Z');
const LATER = new Date('2026-11-05T15:30:00.000Z');

/** Ida recta de oeste a este (rumbo 90°), unos 11 km. */
const WEST = { longitude: -73.3, latitude: 10.46 };
const EAST = { longitude: -73.2, latitude: 10.46 };
const eastbound = planCorridor(WEST, EAST, []) as PlannedCorridor;
const model = { maxSpeedKmh: 150, maxRangeKm: 110 };

function cell(overrides: Partial<WeatherCellView>): WeatherCellView {
  return {
    id: 'c1',
    kind: WeatherKind.WIND,
    latitude: 10.46,
    longitude: -73.25,
    radiusKm: 20,
    windSpeedMs: 10,
    windGustMs: 12,
    windFromDeg: 90,
    startsAt: NOW,
    endsAt: LATER,
    ...overrides,
  };
}

/** Vuela el crucero entero, tick a tick, y devuelve tiempo y batería gastada. */
function cruise(weather: WeatherCellView[]) {
  let progress = { ...initialProgress(), phase: FlightPhase.CRUISE };
  let ms = 0;
  const alerts: string[] = [];
  while (progress.phase === FlightPhase.CRUISE && ms < 3_600_000) {
    const step = advanceFlight({
      progress,
      elapsedMs: 2_000,
      corridor: eastbound,
      model,
      loadConfirmedAt: NOW,
      weather,
    })!;
    alerts.push(...step.alerts);
    progress = step.progress;
    ms += 2_000;
  }
  return { ms, spent: 100 - progress.batteryPercent, alerts, progress };
}

describe('clima simulado (RF-32)', () => {
  it('una celda rige desde que empieza hasta que termina', () => {
    const live = cell({});
    expect(activeCells([live], NOW)).toEqual([live]);
    expect(activeCells([live], LATER)).toEqual([]);
  });

  it('el viento del este frena a quien va al este y empuja a quien va al oeste', () => {
    const fromEast = cell({ windFromDeg: 90, windSpeedMs: 10 });
    expect(tailwindKmh(fromEast, 90)).toBeCloseTo(-36, 5);
    expect(tailwindKmh(fromEast, 270)).toBeCloseTo(36, 5);
    // De costado no suma ni resta.
    expect(tailwindKmh(fromEast, 0)).toBeCloseTo(0, 5);
  });

  it('con 10 m/s en contra el dron va a 114 km/h sobre el suelo', () => {
    const here = conditionsAt([cell({})], WEST, 90, 150);
    expect(here.groundSpeedKmh).toBeCloseTo(114, 5);
    expect(here.overLimit).toBe(false);
  });

  it('sobre 15 m/s o con ráfagas de más de 20 m/s no se vuela', () => {
    expect(
      conditionsAt([cell({ windSpeedMs: 16, windGustMs: 16 })], WEST, 90, 150)
        .overLimit,
    ).toBe(true);
    expect(
      conditionsAt([cell({ windSpeedMs: 12, windGustMs: 21 })], WEST, 90, 150)
        .overLimit,
    ).toBe(true);
  });

  it('en contra, el crucero cuesta como uno más largo; a favor, como uno más corto', () => {
    const headwind = corridorWeather(eastbound, [cell({})], 150);
    const tailwind = corridorWeather(
      eastbound,
      [cell({ windFromDeg: 270 })],
      150,
    );
    expect(headwind.energyKm).toBeCloseTo(
      eastbound.distanceKm * (150 / 114),
      1,
    );
    expect(tailwind.energyKm).toBeCloseTo(
      eastbound.distanceKm * (150 / 186),
      1,
    );
    expect(headwind.flyable).toBe(true);
  });

  it('la lluvia suma un 10 % y se puede volar', () => {
    const rain = corridorWeather(
      eastbound,
      [cell({ kind: WeatherKind.RAIN, windSpeedMs: null, windFromDeg: null })],
      150,
    );
    expect(rain.energyKm).toBeCloseTo(
      eastbound.distanceKm * RAIN_BURN_FACTOR,
      1,
    );
    expect(rain.flyable).toBe(true);
  });

  it('una tormenta o un viento sobre el límite en el corredor no dejan volar', () => {
    expect(
      corridorWeather(
        eastbound,
        [cell({ kind: WeatherKind.STORM, radiusKm: 1 })],
        150,
      ).reason,
    ).toBe(WEATHER_STORM_BLOCKS);
    expect(
      corridorWeather(
        eastbound,
        [cell({ windSpeedMs: 17, windGustMs: 22 })],
        150,
      ).reason,
    ).toBe(WEATHER_WIND_BLOCKS);
  });

  it('la tormenta, como polígono, encierra su centro y no lo que queda fuera del radio', () => {
    const storm = stormPolygon(cell({ kind: WeatherKind.STORM, radiusKm: 2 }));
    expect(storm.coordinates[0]).toHaveLength(17);
    expect(
      isInsideGeofence({ longitude: -73.25, latitude: 10.46 }, [storm]),
    ).toBe(true);
    expect(
      isInsideGeofence({ longitude: -73.2, latitude: 10.46 }, [storm]),
    ).toBe(false);
  });
});

describe('el vuelo con clima (RF-32)', () => {
  it('sin clima, el crucero dura distancia / velocidad y gasta lo de siempre', () => {
    const calm = cruise([]);
    expect(calm.ms).toBeCloseTo((eastbound.distanceKm / 150) * 3_600_000, -4);
    // El último tick ya empieza a bajar: suma hasta el 1 % del descenso.
    const cruiseOnly = (eastbound.distanceKm / 110) * 100;
    expect(calm.spent).toBeGreaterThanOrEqual(cruiseOnly - 1e-9);
    expect(calm.spent).toBeLessThan(cruiseOnly + 1);
  });

  it('con viento en contra tarda más, gasta más y no llega antes de tiempo', () => {
    const calm = cruise([]);
    const windy = cruise([cell({})]);
    expect(windy.ms).toBeGreaterThan(calm.ms * 1.25);
    expect(windy.spent).toBeCloseTo(calm.spent * (150 / 114), 0);
    // Termina el crucero en el final del corredor, no a mitad de camino.
    expect(windy.progress.cruiseKm).toBe(eastbound.distanceKm);
  });

  it('con lluvia gasta un 10 % más en el mismo tiempo', () => {
    const calm = cruise([]);
    const rain = cruise([
      cell({ kind: WeatherKind.RAIN, windSpeedMs: null, windFromDeg: null }),
    ]);
    expect(rain.ms).toBe(calm.ms);
    expect(rain.spent).toBeCloseTo(calm.spent * RAIN_BURN_FACTOR, 1);
  });

  it('con viento sobre el límite avisa una sola vez y sigue (el protocolo es RF-34)', () => {
    const storm = cruise([cell({ windSpeedMs: 17, windGustMs: 22 })]);
    expect(storm.alerts.filter((kind) => kind === 'wind_limit')).toHaveLength(
      1,
    );
    expect(storm.progress.phase).not.toBe(FlightPhase.CRUISE);
  });
});
