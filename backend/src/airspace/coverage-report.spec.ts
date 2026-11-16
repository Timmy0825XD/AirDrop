import { DRONE_TYPES } from '../fleet/drone-types';
import { missionWithClimbPercent } from '../decision/decision.rules';
import { reverseCorridor } from '../routing/routing.rules';
import { RoutePlannerService } from '../routing/route-planner.service';
import { AirspaceService } from './airspace.service';
import { DELIVERY_POINTS, ESES, NODES } from './regional-network';
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
const nodes = Object.values(NODES);

function reach(
  node: (typeof nodes)[number],
  target: { latitude: number; longitude: number },
) {
  const corridor = planner.plan(node, target, airspace.blockingPolygons());
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
  it('cada punto de entrega lo alcanza al menos un tipo desde su nodo', () => {
    for (const point of DELIVERY_POINTS) {
      const node = nodes.find((entry) => entry.code === point.nodeCode)!;
      const { verdict } = reach(node, point);
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
      NODES.north,
      DELIVERY_POINTS.find((point) => point.code === 'dp-guatapuri')!,
    );
    expect(reachable(verdict)).toEqual(['Colibrí']);
  });

  it('Villa Germania queda fuera: ningún tipo vuelve', () => {
    const villaGermania = { latitude: 10.2669, longitude: -73.7151 };
    expect(reachable(reach(NODES.west, villaGermania).verdict)).toEqual([]);
  });

  it('la ESE de Pueblo Bello solo la alcanza el Colibrí', () => {
    expect(reachable(reach(NODES.west, ESES.puebloBello).verdict)).toEqual([
      'Colibrí',
    ]);
  });

  it('las ESE cercanas a su nodo las alcanza el Cóndor', () => {
    for (const [node, ese] of [
      [NODES.south, ESES.laPaz],
      [NODES.south, ESES.sanDiego],
      [NODES.codazzi, ESES.codazzi],
      [NODES.valledupar, ESES.rosarioPumarejo],
      [NODES.valledupar, ESES.arredondo],
    ] as const) {
      expect(reachable(reach(node, ese).verdict)).toContain('Cóndor');
    }
  });

  it('Nabusímake (2.135 m) queda fuera: ningún tipo vuelve', () => {
    const nabusimake = { latitude: 10.5844, longitude: -73.5929 };
    expect(reachable(reach(NODES.west, nabusimake).verdict)).toEqual([]);
  });
});
