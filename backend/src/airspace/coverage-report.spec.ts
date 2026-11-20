import { DRONE_TYPES } from '../fleet/drone-types';
import { missionWithClimbPercent } from '../decision/decision.rules';
import { reverseCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { AirspaceService } from './airspace.service';
import { DEMO_PLACES, HUB_SITES } from './regional-network';
import { climbPercentPerM } from './terrain.rules';
import { TerrainService } from './terrain.service';

/**
 * RF-11, RF-46 y `context/negocio/cobertura.md`: con las rutas legales y el
 * terreno real, qué tipo alcanza cada punto con la batería llena.
 */
const airspace = new AirspaceService();
const terrain = new TerrainService();
const planner = new RoutePlannerService(
  { manager: { query: jest.fn().mockResolvedValue([]) } } as never,
  { stormPolygons: () => [] } as never,
  airspace,
);
const hubs = Object.values(HUB_SITES);

function reach(
  hub: (typeof hubs)[number],
  target: { latitude: number; longitude: number },
) {
  const corridor = planner.plan(hub, target, airspace.blockingPolygons());
  if (!corridor) {
    return { km: null, verdict: {} as Record<string, boolean> };
  }
  const verdict: Record<string, boolean> = {};
  for (const spec of DRONE_TYPES) {
    const out = terrain.profile(corridor, spec);
    const back = terrain.profile(reverseCorridor(corridor), spec);
    const percent = missionWithClimbPercent(
      corridor.distanceKm,
      { maxRangeKm: spec.maxRangeKm, climbPercentPerM: climbPercentPerM(spec) },
      { climbM: out.climbM + back.climbM, peakMslM: 0 },
    );
    const peak = Math.max(out.peakMslM, back.peakMslM);
    verdict[spec.name] = percent <= 100 && peak <= spec.ceilingM;
  }
  return { km: corridor.distanceKm, verdict };
}

const reachable = (verdict: Record<string, boolean>) =>
  Object.entries(verdict)
    .filter(([, ok]) => ok)
    .map(([name]) => name);

describe('Cobertura real de la red (cobertura.md, RF-46)', () => {
  it('cada lugar de la demo lo alcanza al menos un tipo desde su central', () => {
    for (const point of DEMO_PLACES) {
      const hub = hubs.find((entry) => entry.code === point.hubCode)!;
      const { verdict } = reach(hub, point);
      expect({
        point: point.code,
        types: reachable(verdict).length > 0,
      }).toEqual({
        point: point.code,
        types: true,
      });
    }
  });

  it('Guatapurí (1.277 m) solo la alcanza el Colibrí, por la subida', () => {
    const { verdict } = reach(
      HUB_SITES.rioSeco,
      DEMO_PLACES.find((point) => point.code === 'dp-guatapuri')!,
    );
    expect(reachable(verdict)).toEqual(['Colibrí']);
  });

  it('Villa Germania queda fuera: ningún tipo vuelve', () => {
    const villaGermania = { latitude: 10.2669, longitude: -73.7151 };
    expect(reachable(reach(HUB_SITES.valencia, villaGermania).verdict)).toEqual(
      [],
    );
  });

  it('desde Valencia de Jesús, Pueblo Bello solo lo alcanza el Colibrí', () => {
    expect(
      reachable(reach(HUB_SITES.valencia, HUB_SITES.puebloBello).verdict),
    ).toEqual(['Colibrí']);
  });

  it('las centrales vecinas se abastecen con el Cóndor', () => {
    for (const [from, to] of [
      [HUB_SITES.laPaz, HUB_SITES.sanDiego],
      [HUB_SITES.laNevada, HUB_SITES.rosarioPumarejo],
      [HUB_SITES.laNevada, HUB_SITES.elCarmen],
      [HUB_SITES.arredondo, HUB_SITES.elCarmen],
    ] as const) {
      expect(reachable(reach(from, to).verdict)).toContain('Cóndor');
    }
  });

  it('Nabusímake (2.135 m) queda fuera: ningún tipo vuelve', () => {
    const nabusimake = { latitude: 10.5844, longitude: -73.5929 };
    expect(reachable(reach(HUB_SITES.valencia, nabusimake).verdict)).toEqual(
      [],
    );
  });
});
