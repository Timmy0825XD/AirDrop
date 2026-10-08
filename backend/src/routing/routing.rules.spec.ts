import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { CORRIDOR_ALTITUDE_M, planOutboundCorridor } from './routing.rules';

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

describe('planOutboundCorridor', () => {
  const origin = { longitude: -73.3, latitude: 10.4 };
  const destination = { longitude: -73.2, latitude: 10.4 };

  it('keeps a direct corridor at fixed altitude when nothing blocks it', () => {
    const corridor = planOutboundCorridor(origin, destination, [
      square(-73.1, 10.5, -73.05, 10.55),
    ]);
    expect(corridor?.altitudeM).toBe(CORRIDOR_ALTITUDE_M);
    expect(corridor?.distanceKm).toBeGreaterThan(0);
    expect(corridor?.coordinates).toEqual([
      [origin.longitude, origin.latitude],
      [destination.longitude, destination.latitude],
    ]);
  });

  it('detours north or south around a geofence on the direct line', () => {
    const fence = square(-73.26, 10.39, -73.24, 10.41);
    const corridor = planOutboundCorridor(origin, destination, [fence]);
    expect(corridor).not.toBeNull();
    expect(corridor?.coordinates).toHaveLength(3);
    const [, waypoint] = corridor?.coordinates ?? [];
    expect(waypoint[1] > 10.41 || waypoint[1] < 10.39).toBe(true);
    expect(corridor?.altitudeM).toBe(CORRIDOR_ALTITUDE_M);
  });

  it('returns null when every detour still crosses a geofence', () => {
    const blocking = square(-73.26, 10.39, -73.24, 10.41);
    const northWall = square(-73.4, 10.42, -73.1, 11);
    const southWall = square(-73.4, 9.8, -73.1, 10.38);
    expect(
      planOutboundCorridor(origin, destination, [
        blocking,
        northWall,
        southWall,
      ]),
    ).toBeNull();
  });

  it('returns null when the origin sits inside a geofence', () => {
    expect(
      planOutboundCorridor(origin, destination, [
        square(-73.31, 10.39, -73.29, 10.41),
      ]),
    ).toBeNull();
  });
});
