import { BadRequestException } from '@nestjs/common';
import { AirspaceService } from '../airspace/airspace.service';
import { DELIVERY_POINTS, ESES, NODES } from '../airspace/regional-network';
import { regionalAirspace } from '../airspace/regional-airspace';
import { RoutePlannerService } from './route-planner.service';
import { corridorCrossesGeofence, isInsideGeofence } from './routing.rules';

/**
 * RF-12 y RF-43 con el espacio aéreo real de la demo: rutas entre los nodos
 * y los puntos de la red regional.
 */
function build() {
  const airspace = new AirspaceService();
  const planner = new RoutePlannerService(
    { manager: { query: jest.fn().mockResolvedValue([]) } } as never,
    { stormPolygons: () => [] } as never,
    airspace,
  );
  return { planner, airspace };
}

const point = (code: string) =>
  DELIVERY_POINTS.find((entry) => entry.code === code)!;

describe('RoutePlannerService con las zonas del RAC 100', () => {
  it('cada punto de entrega tiene corredor desde su nodo', () => {
    const { planner, airspace } = build();
    const nodes = Object.values(NODES);
    for (const target of DELIVERY_POINTS) {
      const node = nodes.find((entry) => entry.code === target.nodeCode)!;
      const corridor = planner.plan(node, target, airspace.blockingPolygons());
      expect({ target: target.code, ok: corridor != null }).toEqual({
        target: target.code,
        ok: true,
      });
    }
  });

  it('cada ESE tiene corredor desde su nodo, entrando por la estación', () => {
    const { planner, airspace } = build();
    const pairs = [
      [NODES.south, ESES.laPaz],
      [NODES.south, ESES.sanDiego],
      [NODES.south, ESES.manaure],
      [NODES.west, ESES.puebloBello],
      [NODES.codazzi, ESES.codazzi],
    ] as const;
    for (const [node, ese] of pairs) {
      const corridor = planner.plan(node, ese, airspace.blockingPolygons(), {
        destinationIsHub: true,
      });
      expect({ ese: ese.code, ok: corridor != null }).toEqual({
        ese: ese.code,
        ok: true,
      });
    }
  });

  it('ningún corredor cruza una zona bloqueante', () => {
    const { planner, airspace } = build();
    const blocking = airspace.blockingPolygons();
    for (const target of DELIVERY_POINTS) {
      const node = Object.values(NODES).find(
        (entry) => entry.code === target.nodeCode,
      )!;
      const corridor = planner.plan(node, target, blocking)!;
      expect(corridorCrossesGeofence(corridor, blocking)).toBe(false);
    }
  });

  it('a Atánquez entra por la entrada pactada del resguardo', () => {
    const { planner, airspace } = build();
    const gateway = regionalAirspace().find(
      (zone) => zone.code === 'resguardo-kankuamo',
    )!.gateway!;
    const corridor = planner.plan(
      NODES.north,
      point('dp-atanquez'),
      airspace.blockingPolygons(),
    )!;
    expect(corridor.coordinates.at(-2)).toEqual([
      gateway.longitude,
      gateway.latitude,
    ]);
    // Antes de la entrada, ningún tramo pisa el resguardo.
    const resguardo = regionalAirspace().find(
      (zone) => zone.code === 'resguardo-kankuamo',
    )!.polygon;
    const beforeGateway = corridor.coordinates.slice(0, -1);
    expect(
      beforeGateway.some(([longitude, latitude]) =>
        isInsideGeofence({ longitude, latitude }, [resguardo]),
      ),
    ).toBe(false);
  });

  it('el regreso desde Atánquez sale por la misma entrada', () => {
    const { planner, airspace } = build();
    const gateway = regionalAirspace().find(
      (zone) => zone.code === 'resguardo-kankuamo',
    )!.gateway!;
    const back = planner.planReturn(
      point('dp-atanquez'),
      NODES.north,
      airspace.blockingPolygons(),
      null,
    )!;
    expect(back.corridor.coordinates[1]).toEqual([
      gateway.longitude,
      gateway.latitude,
    ]);
    expect(back.corridor.coordinates.at(-1)).toEqual([
      NODES.north.longitude,
      NODES.north.latitude,
    ]);
  });

  it('un destino en la ciudad de Valledupar no se acepta', async () => {
    const { planner } = build();
    await expect(
      planner.assertDestinationAllowed({ latitude: 10.47, longitude: -73.25 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('un punto cualquiera dentro del resguardo no se acepta; el pactado sí', async () => {
    const { planner } = build();
    await expect(
      planner.assertDestinationAllowed({ latitude: 10.7, longitude: -73.37 }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      planner.assertDestinationAllowed(point('dp-atanquez')),
    ).resolves.toBeUndefined();
  });

  it('planear la ruta más larga de la red tarda poco', () => {
    const { planner, airspace } = build();
    const started = Date.now();
    planner.plan(
      NODES.west,
      point('dp-mariangola'),
      airspace.blockingPolygons(),
    );
    planner.plan(NODES.north, ESES.laPaz, airspace.blockingPolygons(), {
      destinationIsHub: true,
    });
    expect(Date.now() - started).toBeLessThan(500);
  });
});
