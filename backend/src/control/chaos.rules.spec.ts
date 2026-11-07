import { IncidentKind } from '../common/enums/incident-kind.enum';
import { WeatherKind } from '../common/enums/weather-kind.enum';
import {
  CHAOS_EVERY_MS,
  CHAOS_OFF,
  applyChaosChange,
  chaosChangeText,
  chaosWeather,
  circlePolygon,
  collisionWeights,
  droneWeights,
  environmentWeights,
  nextChaosAt,
  parseChaosState,
  pickFamily,
  pickWornDrone,
  weatherWeights,
  weighted,
} from './chaos.rules';

const NOW = new Date('2026-11-06T15:00:00.000Z'); // 10:00 en Colombia

function share<T>(
  options: ReadonlyArray<readonly [T, number]>,
  kind: T,
): number {
  const total = options.reduce((sum, [, weight]) => sum + weight, 0);
  const found = options.find(([value]) => value === kind);
  return found ? found[1] / total : 0;
}

describe('chaos.rules (RF-38)', () => {
  it('arranca apagado, también si Redis trae algo roto', () => {
    expect(parseChaosState(null)).toEqual(CHAOS_OFF);
    expect(parseChaosState('{"enabled":true,"intensity":"furioso"}')).toEqual({
      enabled: true,
      intensity: 'medium',
      enabledByUserId: null,
    });
  });

  it('al encender guarda quién fue y lo cuenta; al apagar lo olvida', () => {
    const on = applyChaosChange(
      CHAOS_OFF,
      { enabled: true, intensity: 'high' },
      'admin',
    );
    expect(on).toEqual({
      enabled: true,
      intensity: 'high',
      enabledByUserId: 'admin',
    });
    expect(chaosChangeText(CHAOS_OFF, on)).toBe(
      'Modo caos encendido, intensidad alta',
    );
    const off = applyChaosChange(on, { enabled: false }, 'admin');
    expect(off.enabledByUserId).toBeNull();
    expect(chaosChangeText(on, off)).toBe('Modo caos apagado');
  });

  it('sortea cada ~15, ~8 o ~4 min simulados, entre la mitad y 1,5 veces', () => {
    expect(CHAOS_EVERY_MS).toEqual({
      low: 900_000,
      medium: 480_000,
      high: 240_000,
    });
    expect(nextChaosAt(NOW, 'high', () => 0).getTime() - NOW.getTime()).toBe(
      120_000,
    );
    expect(
      nextChaosAt(NOW, 'low', () => 0.999).getTime() - NOW.getTime(),
    ).toBeCloseTo(1_349_100, -3);
  });

  it('elige según el peso y nunca lo que pesa 0', () => {
    const options = [
      ['a', 1],
      ['b', 0],
      ['c', 3],
    ] as const;
    expect(weighted(options, () => 0)).toBe('a');
    expect(weighted(options, () => 0.3)).toBe('c');
    expect(weighted(options, () => 0.999)).toBe('c');
  });

  it('sin drones en el aire no sortea fallas ni choques', () => {
    for (const value of [0, 0.4, 0.6, 0.9, 0.999]) {
      expect(['weather', 'environment']).toContain(
        pickFamily(() => value, false),
      );
    }
    // Clima 40 de 100: lo que pasa de 0,4 ya es dron.
    expect(pickFamily(() => 0.41, true)).toBe('drone');
  });

  it('las tormentas son tres veces más probables en la tarde', () => {
    const morning = weatherWeights(NOW);
    const afternoon = weatherWeights(new Date('2026-11-06T20:00:00.000Z')); // 15:00
    expect(morning.find(([kind]) => kind === WeatherKind.STORM)?.[1]).toBe(20);
    expect(afternoon.find(([kind]) => kind === WeatherKind.STORM)?.[1]).toBe(
      60,
    );
  });

  it('los graves solo salen en alta, y ahí son el 10 % de su familia', () => {
    const medium = droneWeights('medium', false);
    expect(share(medium, IncidentKind.DUAL_MOTOR_FAILURE)).toBe(0);
    expect(share(medium, IncidentKind.DRONE_LOST)).toBe(0);
    const high = droneWeights('high', false);
    expect(
      share(high, IncidentKind.DUAL_MOTOR_FAILURE) +
        share(high, IncidentKind.DRONE_LOST),
    ).toBeCloseTo(0.1);
    expect(share(collisionWeights('low'), IncidentKind.COLLISION_MAJOR)).toBe(
      0,
    );
    expect(
      share(collisionWeights('high'), IncidentKind.COLLISION_MAJOR),
    ).toBeCloseTo(0.1);
    expect(share(environmentWeights('medium'), 'hub_outage')).toBe(0);
    expect(share(environmentWeights('high'), 'hub_outage')).toBeCloseTo(0.1);
  });

  it('la falla del frío solo si el dron lleva carga fría', () => {
    expect(
      share(droneWeights('low', false), IncidentKind.COOLING_FAILURE),
    ).toBe(0);
    expect(
      share(droneWeights('low', true), IncidentKind.COOLING_FAILURE),
    ).toBeGreaterThan(0);
  });

  it('la falla le cae al dron con más vuelos desde su mantenimiento', () => {
    const drones = [
      { id: 'nuevo', flightsSinceMaintenance: 3 },
      { id: 'gastado', flightsSinceMaintenance: 41 },
    ];
    expect(pickWornDrone(drones, () => 0)?.id).toBe('gastado');
    expect(pickWornDrone([], () => 0)).toBeNull();
  });

  it('el viento del caos va de 8 a 22 m/s con ráfagas un 30 % más', () => {
    const wind = chaosWeather(
      WeatherKind.WIND,
      { latitude: 10.47, longitude: -73.25 },
      () => 0.999,
    );
    expect(wind.windSpeedMs).toBe(22);
    expect(wind.windGustMs).toBe(29);
    expect(wind.radiusKm).toBeLessThanOrEqual(3.5);
    const rain = chaosWeather(
      WeatherKind.RAIN,
      { latitude: 10.47, longitude: -73.25 },
      () => 0,
    );
    expect(rain).not.toHaveProperty('windSpeedMs');
    expect(rain.radiusKm).toBe(1.5);
  });

  it('la zona temporal es un polígono cerrado de 16 lados', () => {
    const ring = circlePolygon({ latitude: 10.47, longitude: -73.25 }, 1)
      .coordinates[0];
    expect(ring).toHaveLength(17);
    expect(ring[16]).toEqual(ring[0]);
  });
});
