import { BadRequestException } from '@nestjs/common';
import { assertGeoJsonPolygon } from './geofences.rules';

const closedRing = [
  [-73.26, 10.46],
  [-73.25, 10.46],
  [-73.25, 10.47],
  [-73.26, 10.47],
  [-73.26, 10.46],
];

describe('assertGeoJsonPolygon', () => {
  it('accepts a closed GeoJSON polygon', () => {
    const polygon = assertGeoJsonPolygon({
      type: 'Polygon',
      coordinates: [closedRing],
    });
    expect(polygon.coordinates[0]).toHaveLength(5);
  });

  it('rejects an open ring', () => {
    expect(() =>
      assertGeoJsonPolygon({
        type: 'Polygon',
        coordinates: [closedRing.slice(0, 4)],
      }),
    ).toThrow(BadRequestException);
  });
});
