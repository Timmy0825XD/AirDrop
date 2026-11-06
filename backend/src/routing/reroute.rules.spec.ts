import { GeoJsonPolygon } from '../geofences/geofences.rules';
import {
  PlannedCorridor,
  corridorCrossesGeofence,
  haversineKm,
  planCorridor,
  rerouteFromPosition,
  splitCorridorAt,
} from './routing.rules';
import { batteryToFinishPercent } from '../simulation/flight-energy.rules';

const square = (west: number, south: number, east: number, north: number) =>
  ({
    type: 'Polygon' as const,
    coordinates: [
      [
        [west, south],
        [east, south],
        [east, north],
        [west, north],
        [west, south],
      ],
    ],
  }) satisfies GeoJsonPolygon;

/** Ida recta de oeste a este, unos 11 km, a la latitud de Valledupar. */
const HUB = { longitude: -73.3, latitude: 10.46 };
const DESTINATION = { longitude: -73.2, latitude: 10.46 };
const straight = planCorridor(HUB, DESTINATION, []) as PlannedCorridor;

/** Una zona nueva atravesada en la mitad del camino. */
const middleFence = square(-73.255, 10.45, -73.245, 10.47);

describe('cambio de ruta en vuelo (RF-33)', () => {
  it('corta el corredor en el punto donde va el dron', () => {
    const split = splitCorridorAt(straight, 3);
    expect(haversineKm(HUB, split.at)).toBeCloseTo(3, 3);
    expect(split.flown[0]).toEqual(straight.coordinates[0]);
    expect(split.remaining[split.remaining.length - 1]).toEqual(
      straight.coordinates[straight.coordinates.length - 1],
    );
    expect(split.flown[split.flown.length - 1]).toEqual(split.remaining[0]);
  });

  it('si la zona nueva no toca lo que falta, el dron sigue igual', () => {
    const behind = square(-73.29, 10.45, -73.28, 10.47);
    // A 5 km del inicio la zona ya quedó atrás.
    expect(rerouteFromPosition(straight, 5, [behind])).toEqual({
      kind: 'clear',
    });
  });

  it('rodea la zona desde donde va, sin cambiar lo que ya voló', () => {
    const outcome = rerouteFromPosition(straight, 2, [middleFence]);
    if (outcome.kind !== 'rerouted') throw new Error(outcome.kind);
    const split = splitCorridorAt(outcome.corridor, 2);
    // El punto del dron no salta: a 2 km sigue en el mismo lugar.
    expect(haversineKm(split.at, splitCorridorAt(straight, 2).at)).toBeLessThan(
      0.001,
    );
    expect(
      corridorCrossesGeofence(
        { ...outcome.corridor, coordinates: split.remaining },
        [middleFence],
      ),
    ).toBe(false);
    expect(outcome.corridor.coordinates.at(-1)).toEqual(
      straight.coordinates.at(-1),
    );
    expect(outcome.addedKm).toBeGreaterThan(0);
    expect(outcome.crossesGeofence).toBe(false);
    expect(outcome.corridor.distanceKm).toBeCloseTo(2 + outcome.remainingKm, 1);
  });

  it('si el dron quedó dentro de la zona, sale cruzándola y queda marcado', () => {
    const around = square(-73.29, 10.45, -73.27, 10.47);
    // A 2 km del inicio el dron está dentro de la zona nueva.
    const outcome = rerouteFromPosition(straight, 2, [around]);
    expect(outcome.kind).toBe('rerouted');
    if (outcome.kind === 'rerouted') {
      expect(outcome.crossesGeofence).toBe(true);
    }
  });

  it('la batería para terminar cuenta lo que falta, el regreso si va de ida y la reserva', () => {
    const outbound = batteryToFinishPercent({
      remainingKm: 11,
      returnKm: 11,
      maxRangeKm: 110,
    });
    // 10 % de crucero, 4 % de bajar y aterrizar, 18 % del regreso y 20 % de reserva.
    expect(outbound).toBeCloseTo(52, 5);
    expect(
      batteryToFinishPercent({
        remainingKm: 11,
        returnKm: null,
        maxRangeKm: 110,
      }),
    ).toBeCloseTo(34, 5);
  });
});
