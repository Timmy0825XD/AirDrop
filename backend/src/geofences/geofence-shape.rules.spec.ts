import { GeofenceShape } from '../common/enums/geofence-shape.enum';
import { isInsideGeofence } from '../routing/routing.rules';
import {
  POLYGON_REPEATED_VERTEX,
  POLYGON_SELF_INTERSECTS,
  RADIUS_OUT_OF_RANGE,
  VERTICES_OUT_OF_RANGE,
  circleSides,
  toGeofenceGeometry,
} from './geofence-shape.rules';

const center = { latitude: 10.47, longitude: -73.25 };

const square = [
  { latitude: 10.46, longitude: -73.25 },
  { latitude: 10.46, longitude: -73.24 },
  { latitude: 10.47, longitude: -73.24 },
  { latitude: 10.47, longitude: -73.25 },
];

describe('Forma de una geovalla (RF-21)', () => {
  it('un círculo guarda centro y radio, y su polígono lo contiene', () => {
    const geometry = toGeofenceGeometry({
      shape: GeofenceShape.CIRCLE,
      center,
      radiusM: 300,
    });
    expect(geometry).toMatchObject({ shape: 'circle', center, radiusM: 300 });
    const ring = geometry.polygon.coordinates[0];
    expect(ring).toHaveLength(circleSides(300) + 1);
    expect(ring[0]).toEqual(ring[ring.length - 1]);
    // A 290 m del centro, hacia el norte, sigue dentro.
    expect(
      isInsideGeofence({ latitude: 10.4726, longitude: -73.25 }, [
        geometry.polygon,
      ]),
    ).toBe(true);
  });

  it.each([49, 5001, 120.5, undefined])(
    'un radio de %p m se rechaza',
    (radiusM) => {
      expect(() =>
        toGeofenceGeometry({ shape: GeofenceShape.CIRCLE, center, radiusM }),
      ).toThrow(RADIUS_OUT_OF_RANGE);
    },
  );

  it('los bordes del rango valen: 50 m y 5 km', () => {
    for (const radiusM of [50, 5000]) {
      expect(() =>
        toGeofenceGeometry({ shape: GeofenceShape.CIRCLE, center, radiusM }),
      ).not.toThrow();
    }
  });

  it('un círculo sin centro se rechaza', () => {
    expect(() =>
      toGeofenceGeometry({ shape: GeofenceShape.CIRCLE, radiusM: 100 }),
    ).toThrow('El círculo necesita su centro.');
  });

  it('un polígono de vértices se cierra solo', () => {
    const geometry = toGeofenceGeometry({
      shape: GeofenceShape.POLYGON,
      vertices: square,
    });
    expect(geometry).toMatchObject({
      shape: 'polygon',
      center: null,
      radiusM: null,
    });
    const ring = geometry.polygon.coordinates[0];
    expect(ring).toHaveLength(5);
    expect(ring[0]).toEqual([-73.25, 10.46]);
    expect(ring[4]).toEqual(ring[0]);
  });

  it('menos de 3 o más de 50 vértices se rechaza', () => {
    expect(() =>
      toGeofenceGeometry({
        shape: GeofenceShape.POLYGON,
        vertices: square.slice(0, 2),
      }),
    ).toThrow(VERTICES_OUT_OF_RANGE);
    const many = Array.from({ length: 51 }, (_, i) => ({
      latitude: 10.47 + 0.01 * Math.sin((2 * Math.PI * i) / 51),
      longitude: -73.25 + 0.01 * Math.cos((2 * Math.PI * i) / 51),
    }));
    expect(() =>
      toGeofenceGeometry({ shape: GeofenceShape.POLYGON, vertices: many }),
    ).toThrow(VERTICES_OUT_OF_RANGE);
    expect(() =>
      toGeofenceGeometry({
        shape: GeofenceShape.POLYGON,
        vertices: many.slice(0, 50),
      }),
    ).not.toThrow();
  });

  it('un polígono en forma de corbatín (lados que se cruzan) se rechaza', () => {
    const bowtie = [
      square[0],
      square[2],
      square[1],
      { latitude: 10.475, longitude: -73.25 },
    ];
    expect(() =>
      toGeofenceGeometry({ shape: GeofenceShape.POLYGON, vertices: bowtie }),
    ).toThrow(POLYGON_SELF_INTERSECTS);
  });

  it('vértices repetidos o en línea recta se rechazan', () => {
    expect(() =>
      toGeofenceGeometry({
        shape: GeofenceShape.POLYGON,
        vertices: [square[0], square[1], square[1], square[2]],
      }),
    ).toThrow(POLYGON_REPEATED_VERTEX);
    expect(() =>
      toGeofenceGeometry({
        shape: GeofenceShape.POLYGON,
        vertices: [
          { latitude: 10.46, longitude: -73.25 },
          { latitude: 10.47, longitude: -73.25 },
          { latitude: 10.48, longitude: -73.25 },
        ],
      }),
    ).toThrow(POLYGON_REPEATED_VERTEX);
  });
});
