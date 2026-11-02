import { GeoJsonPolygon } from '../geofences/geofences.rules';
import {
  CORRIDOR_ALTITUDE_M,
  GEOFENCE_MARGIN_KM,
  LngLat,
  PlannedCorridor,
  corridorCrossesGeofence,
  haversineKm,
  isInsideGeofence,
  planCorridor,
  planReturnCorridor,
  reverseCorridor,
} from './routing.rules';
import { PlanePoint, projectionAround } from './visibility.rules';

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

const polygon = (points: Array<[number, number]>): GeoJsonPolygon => ({
  type: 'Polygon',
  coordinates: [[...points, points[0]]],
});

/** Distancia mínima, en km, entre el corredor y el borde de una geovalla. */
function clearanceKm(corridor: PlannedCorridor, fence: GeoJsonPolygon): number {
  const [lng, lat] = corridor.coordinates[0];
  const projection = projectionAround(lng, lat);
  const path = corridor.coordinates.map(([x, y]) => projection.toPlane(x, y));
  const ring = fence.coordinates[0].map(([x, y]) => projection.toPlane(x, y));
  let best = Infinity;
  for (let i = 1; i < path.length; i += 1) {
    for (let j = 1; j < ring.length; j += 1) {
      best = Math.min(
        best,
        pointToSegment(path[i - 1], ring[j - 1], ring[j]),
        pointToSegment(path[i], ring[j - 1], ring[j]),
        pointToSegment(ring[j - 1], path[i - 1], path[i]),
        pointToSegment(ring[j], path[i - 1], path[i]),
      );
    }
  }
  return best;
}

function pointToSegment(p: PlanePoint, a: PlanePoint, b: PlanePoint): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lengthSq = dx * dx + dy * dy;
  const t =
    lengthSq === 0
      ? 0
      : Math.max(
          0,
          Math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSq),
        );
  return Math.hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy));
}

/** Margen exigido menos el redondeo de coordenadas a 6 decimales. */
const MARGIN_WITH_ROUNDING_KM = GEOFENCE_MARGIN_KM - 0.002;

describe('planCorridor (RF-12 y RF-21)', () => {
  const origin: LngLat = { longitude: -73.3, latitude: 10.4 };
  const destination: LngLat = { longitude: -73.2, latitude: 10.4 };
  const direct = haversineKm(origin, destination);

  it('va en línea recta y a altitud fija cuando nada estorba', () => {
    const corridor = planCorridor(origin, destination, [
      square(-73.1, 10.5, -73.05, 10.55),
    ]);
    expect(corridor?.altitudeM).toBe(CORRIDOR_ALTITUDE_M);
    expect(corridor?.coordinates).toEqual([
      [origin.longitude, origin.latitude],
      [destination.longitude, destination.latitude],
    ]);
    expect(corridor?.distanceKm).toBeCloseTo(direct, 1);
  });

  it('rodea una geovalla sobre la línea y pasa a 150 m o más de su borde', () => {
    const fence = square(-73.26, 10.39, -73.24, 10.41);
    const corridor = planCorridor(origin, destination, [fence]);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, [fence])).toBe(false);
    expect(clearanceKm(corridor!, fence)).toBeGreaterThanOrEqual(
      MARGIN_WITH_ROUNDING_KM,
    );
    expect(corridor!.coordinates[0]).toEqual([-73.3, 10.4]);
    expect(corridor!.coordinates.at(-1)).toEqual([-73.2, 10.4]);
    // El rodeo es ceñido: poco más que subir y bajar 1,1 km + margen.
    expect(corridor!.distanceKm).toBeLessThan(direct + 1);
  });

  it('esquiva dos geovallas en fila (antes respondía "sin corredor")', () => {
    const first = square(-73.27, 10.385, -73.255, 10.415);
    const second = square(-73.245, 10.37, -73.23, 10.43);
    const corridor = planCorridor(origin, destination, [first, second]);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, [first, second])).toBe(false);
    expect(clearanceKm(corridor!, first)).toBeGreaterThanOrEqual(
      MARGIN_WITH_ROUNDING_KM,
    );
    expect(clearanceKm(corridor!, second)).toBeGreaterThanOrEqual(
      MARGIN_WITH_ROUNDING_KM,
    );
  });

  it('se aparta de una geovalla que la línea recta roza a 55 m', () => {
    const fence = square(-73.26, 10.4005, -73.24, 10.42);
    expect(
      corridorCrossesGeofence(
        {
          altitudeM: 100,
          distanceKm: direct,
          coordinates: [
            [-73.3, 10.4],
            [-73.2, 10.4],
          ],
        },
        [fence],
      ),
    ).toBe(false);
    const corridor = planCorridor(origin, destination, [fence]);
    expect(corridor!.coordinates.length).toBeGreaterThan(2);
    expect(clearanceKm(corridor!, fence)).toBeGreaterThanOrEqual(
      MARGIN_WITH_ROUNDING_KM,
    );
  });

  it('acepta un destino a 100 m de una geovalla, sin cruzarla', () => {
    const fence = square(-73.199, 10.39, -73.18, 10.41);
    const corridor = planCorridor(origin, destination, [fence]);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, [fence])).toBe(false);
  });

  it('pasa por el hueco entre dos muros si el hueco cabe con el margen', () => {
    const blocking = square(-73.26, 10.39, -73.24, 10.41);
    const northWall = square(-73.4, 10.42, -73.1, 11);
    const southWall = square(-73.4, 9.8, -73.1, 10.38);
    const fences = [blocking, northWall, southWall];
    const corridor = planCorridor(origin, destination, fences);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, fences)).toBe(false);
    for (const fence of fences) {
      expect(clearanceKm(corridor!, fence)).toBeGreaterThanOrEqual(
        MARGIN_WITH_ROUNDING_KM,
      );
    }
  });

  it('no hay corredor si las geovallas encierran el destino', () => {
    const enclosure = [
      square(-73.22, 10.42, -73.18, 10.43),
      square(-73.22, 10.37, -73.18, 10.38),
      square(-73.22, 10.37, -73.21, 10.43),
      square(-73.19, 10.37, -73.18, 10.43),
    ];
    expect(planCorridor(origin, destination, enclosure)).toBeNull();
  });

  it('no pasa por un hueco más angosto que dos márgenes: rodea los muros', () => {
    // Hueco de 0,0025° (~280 m) al sur: con 150 m por lado no cabe.
    const blocking = square(-73.26, 10.3985, -73.24, 10.41);
    const southWall = square(-73.4, 9.8, -73.1, 10.396);
    const northWall = square(-73.4, 10.41, -73.1, 11);
    const fences = [blocking, northWall, southWall];
    const corridor = planCorridor(origin, destination, fences);
    expect(corridorCrossesGeofence(corridor!, fences)).toBe(false);
    // Rodea los muros por fuera (más de 100 km): RF-11 lo descarta por batería.
    expect(corridor!.distanceKm).toBeGreaterThan(100);
  });

  it('rodea una geovalla cóncava (en forma de L)', () => {
    const fence = polygon([
      [-73.27, 10.38],
      [-73.23, 10.38],
      [-73.23, 10.39],
      [-73.26, 10.39],
      [-73.26, 10.43],
      [-73.27, 10.43],
    ]);
    const corridor = planCorridor(origin, destination, [fence]);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, [fence])).toBe(false);
    expect(clearanceKm(corridor!, fence)).toBeGreaterThanOrEqual(
      MARGIN_WITH_ROUNDING_KM,
    );
  });

  it('con 30 geovallas encuentra un corredor válido y rápido', () => {
    const fences: GeoJsonPolygon[] = [];
    for (let row = 0; row < 5; row += 1) {
      for (let column = 0; column < 6; column += 1) {
        const west = -73.29 + column * 0.015;
        const south = 10.37 + row * 0.014 + (column % 2) * 0.006;
        fences.push(square(west, south, west + 0.006, south + 0.006));
      }
    }
    const started = Date.now();
    const corridor = planCorridor(origin, destination, fences);
    expect(Date.now() - started).toBeLessThan(500);
    expect(corridor).not.toBeNull();
    expect(corridorCrossesGeofence(corridor!, fences)).toBe(false);
  });

  it('no hay corredor si la central está dentro de una geovalla', () => {
    expect(
      planCorridor(origin, destination, [square(-73.31, 10.39, -73.29, 10.41)]),
    ).toBeNull();
  });
});

describe('planReturnCorridor (RF-30)', () => {
  const hub: LngLat = { longitude: -73.3, latitude: 10.4 };
  const from: LngLat = { longitude: -73.2, latitude: 10.4 };
  const outbound = planCorridor(hub, from, [])!;

  it('con el cielo libre vuelve en línea recta', () => {
    const result = planReturnCorridor(from, hub, [], outbound);
    expect(result?.crossesGeofence).toBe(false);
    expect(result?.corridor.coordinates).toEqual([
      [-73.2, 10.4],
      [-73.3, 10.4],
    ]);
  });

  it('rodea una geovalla creada durante la espera en vez de volar por encima', () => {
    const fence = square(-73.26, 10.39, -73.24, 10.41);
    expect(corridorCrossesGeofence(reverseCorridor(outbound), [fence])).toBe(
      true,
    );
    const result = planReturnCorridor(from, hub, [fence], outbound);
    expect(result?.crossesGeofence).toBe(false);
    expect(corridorCrossesGeofence(result!.corridor, [fence])).toBe(false);
  });

  it('si el dron quedó dentro de una geovalla nueva, sale y lo marca', () => {
    const fence = square(-73.21, 10.39, -73.19, 10.41);
    const result = planReturnCorridor(from, hub, [fence], outbound);
    expect(result?.crossesGeofence).toBe(true);
    expect(result?.corridor.coordinates[0]).toEqual([-73.2, 10.4]);
    expect(result?.corridor.coordinates.at(-1)).toEqual([-73.3, 10.4]);
  });

  it('si la central quedó encerrada, vuelve por la ida y lo marca', () => {
    const ring = [
      square(-73.32, 10.42, -73.28, 10.43),
      square(-73.32, 10.37, -73.28, 10.38),
      square(-73.32, 10.37, -73.31, 10.43),
      square(-73.29, 10.37, -73.28, 10.43),
    ];
    const result = planReturnCorridor(from, hub, ring, outbound);
    expect(result?.crossesGeofence).toBe(true);
    expect(result?.corridor.coordinates).toEqual([
      [-73.2, 10.4],
      [-73.3, 10.4],
    ]);
  });
});

describe('isInsideGeofence', () => {
  const park = square(-73.3, 10.4, -73.2, 10.5);

  it('finds a destination inside a geofence', () => {
    expect(
      isInsideGeofence({ longitude: -73.25, latitude: 10.45 }, [park]),
    ).toBe(true);
  });

  it('lets a destination outside every geofence through', () => {
    expect(
      isInsideGeofence({ longitude: -73.1, latitude: 10.45 }, [park]),
    ).toBe(false);
  });
});

describe('reverseCorridor', () => {
  it('recorre el mismo corredor al revés sin tocar el original', () => {
    const corridor = {
      altitudeM: CORRIDOR_ALTITUDE_M,
      distanceKm: 3,
      coordinates: [
        [-73.26, 10.47],
        [-73.25, 10.49],
        [-73.24, 10.46],
      ] as Array<[number, number]>,
    };
    const back = reverseCorridor(corridor);
    expect(back.coordinates).toEqual([
      [-73.24, 10.46],
      [-73.25, 10.49],
      [-73.26, 10.47],
    ]);
    expect(back.distanceKm).toBe(3);
    expect(corridor.coordinates[0]).toEqual([-73.26, 10.47]);
  });
});
