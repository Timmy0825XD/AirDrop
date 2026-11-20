import { BadRequestException } from '@nestjs/common';
import { AirspaceService } from '../airspace/airspace.service';
import { DEMO_PLACES, HUB_SITES } from '../airspace/regional-network';
import { RoutePlannerService } from './route-planner.service';
import { corridorCrossesGeofence } from './routing.rules';

/**
 * RF-12 y RF-43 con el espacio aéreo real de la demo: rutas entre las
 * centrales y los lugares de la red regional.
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
  it('cada lugar de la demo tiene corredor desde su central', () => {
    const { planner, airspace } = build();
    const hubs = Object.values(HUB_SITES);
    for (const target of DEMO_PLACES) {
      const hub = hubs.find((entry) => entry.code === target.hubCode)!;
      const corridor = planner.plan(hub, target, airspace.blockingPolygons());
      expect({ target: target.code, ok: corridor != null }).toEqual({
        target: target.code,
        ok: true,
      });
    }
  });

  it('las centrales vecinas tienen corredor entre sí', () => {
    const { planner, airspace } = build();
    const pairs = [
      [HUB_SITES.laNevada, HUB_SITES.rosarioPumarejo],
      [HUB_SITES.rosarioPumarejo, HUB_SITES.arredondo],
      [HUB_SITES.arredondo, HUB_SITES.elCarmen],
      [HUB_SITES.laPaz, HUB_SITES.sanDiego],
      [HUB_SITES.laPaz, HUB_SITES.manaure],
      [HUB_SITES.valencia, HUB_SITES.puebloBello],
      [HUB_SITES.mediaLuna, HUB_SITES.codazzi],
    ] as const;
    for (const [from, to] of pairs) {
      const corridor = planner.plan(from, to, airspace.blockingPolygons());
      expect({ to: to.code, ok: corridor != null }).toEqual({
        to: to.code,
        ok: true,
      });
    }
  });

  it('ningún corredor cruza una zona bloqueante', () => {
    const { planner, airspace } = build();
    const blocking = airspace.blockingPolygons();
    for (const target of DEMO_PLACES) {
      const hub = Object.values(HUB_SITES).find(
        (entry) => entry.code === target.hubCode,
      )!;
      const corridor = planner.plan(hub, target, blocking)!;
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
        latitude: 10.4762,
        longitude: -73.2465,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      planner.assertDestinationAllowed({ latitude: 10.44, longitude: -73.25 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('cruzar la ciudad rodea los CAI sin desviarse mucho', () => {
    const { planner, airspace } = build();
    const corridor = planner.plan(
      HUB_SITES.laNevada,
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
      HUB_SITES.valencia,
      point('dp-mariangola'),
      airspace.blockingPolygons(),
    );
    planner.plan(
      HUB_SITES.rioSeco,
      HUB_SITES.laPaz,
      airspace.blockingPolygons(),
    );
    expect(Date.now() - started).toBeLessThan(500);
  });
});
