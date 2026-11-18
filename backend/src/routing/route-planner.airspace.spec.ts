import { BadRequestException } from '@nestjs/common';
import { AirspaceService } from '../airspace/airspace.service';
import { DEMO_PLACES, ESES, MAIN_HUBS } from '../airspace/regional-network';
import { RoutePlannerService } from './route-planner.service';
import { corridorCrossesGeofence } from './routing.rules';

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
  DEMO_PLACES.find((entry) => entry.code === code)!;

describe('RoutePlannerService con las zonas del RAC 100', () => {
  it('cada punto de entrega tiene corredor desde su nodo', () => {
    const { planner, airspace } = build();
    const nodes = Object.values(MAIN_HUBS);
    for (const target of DEMO_PLACES) {
      const node = nodes.find((entry) => entry.code === target.hubCode)!;
      const corridor = planner.plan(node, target, airspace.blockingPolygons());
      expect({ target: target.code, ok: corridor != null }).toEqual({
        target: target.code,
        ok: true,
      });
    }
  });

  it('cada ESE tiene corredor desde su nodo', () => {
    const { planner, airspace } = build();
    const pairs = [
      [MAIN_HUBS.valledupar, ESES.rosarioPumarejo],
      [MAIN_HUBS.valledupar, ESES.arredondo],
      [MAIN_HUBS.south, ESES.laPaz],
      [MAIN_HUBS.south, ESES.sanDiego],
      [MAIN_HUBS.south, ESES.manaure],
      [MAIN_HUBS.west, ESES.puebloBello],
      [MAIN_HUBS.codazzi, ESES.codazzi],
    ] as const;
    for (const [node, ese] of pairs) {
      const corridor = planner.plan(node, ese, airspace.blockingPolygons());
      expect({ ese: ese.code, ok: corridor != null }).toEqual({
        ese: ese.code,
        ok: true,
      });
    }
  });

  it('ningún corredor cruza una zona bloqueante', () => {
    const { planner, airspace } = build();
    const blocking = airspace.blockingPolygons();
    for (const target of DEMO_PLACES) {
      const node = Object.values(MAIN_HUBS).find(
        (entry) => entry.code === target.hubCode,
      )!;
      const corridor = planner.plan(node, target, blocking)!;
      expect(corridorCrossesGeofence(corridor, blocking)).toBe(false);
    }
  });

  it('un destino en la ciudad de Valledupar se acepta', async () => {
    const { planner } = build();
    await expect(
      planner.assertDestinationAllowed(point('dp-los-mayales')),
    ).resolves.toBeUndefined();
  });

  it('un destino sobre un CAI o en el anillo del aeropuerto no se acepta', async () => {
    const { planner } = build();
    await expect(
      planner.assertDestinationAllowed({
        latitude: 10.4705,
        longitude: -73.2494,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      planner.assertDestinationAllowed({ latitude: 10.44, longitude: -73.25 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('cruzar la ciudad rodea los CAI sin desviarse mucho', () => {
    const { planner, airspace } = build();
    const corridor = planner.plan(
      MAIN_HUBS.valledupar,
      point('dp-la-nevada'),
      airspace.blockingPolygons(),
    )!;
    expect(corridor).not.toBeNull();
    expect(corridor.distanceKm).toBeLessThan(7.5);
  });

  it('planear la ruta más larga de la red tarda poco', () => {
    const { planner, airspace } = build();
    const started = Date.now();
    planner.plan(
      MAIN_HUBS.west,
      point('dp-mariangola'),
      airspace.blockingPolygons(),
    );
    planner.plan(MAIN_HUBS.north, ESES.laPaz, airspace.blockingPolygons());
    expect(Date.now() - started).toBeLessThan(500);
  });
});
