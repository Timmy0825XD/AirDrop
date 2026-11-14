import {
  TerrainGrid,
  climbPercentPerM,
  terrainProfile,
} from '../airspace/terrain.rules';
import { DRONE_TYPES } from '../fleet/drone-types';
import { planCorridor } from '../routing/routing.rules';
import {
  FlightPhase,
  advanceFlight,
  initialProgress,
} from './simulation.rules';

/** RF-46 en vuelo: la subida cuesta batería y la telemetría trae la altitud MSL. */
const grid: TerrainGrid = {
  south: 10,
  west: -73,
  cellDeg: 0.0045,
  rows: 1,
  cols: 40,
  maxElevationM: Array.from({ length: 40 }, (_, col) => (col < 20 ? 100 : 900)),
};
const corridor = planCorridor(
  { longitude: -73 + 0.0045 * 2.5, latitude: 10.002 },
  { longitude: -73 + 0.0045 * 35.5, latitude: 10.002 },
  [],
)!;
const garza = DRONE_TYPES[1];
const model = {
  maxSpeedKmh: garza.maxSpeedKmh,
  maxRangeKm: garza.maxRangeKm,
  verticalSpeedMs: garza.verticalSpeedMs,
  climbPercentPerM: climbPercentPerM(garza),
};

function fly(withTerrain: boolean) {
  const terrain = withTerrain
    ? terrainProfile(grid, corridor, garza)
    : undefined;
  let progress = initialProgress();
  const poses: Array<{ phase: FlightPhase; agl: number; msl: number | null }> =
    [];
  for (
    let tick = 0;
    tick < 400 && progress.phase !== FlightPhase.LANDED;
    tick += 1
  ) {
    const step = advanceFlight({
      progress,
      elapsedMs: 16_000,
      corridor,
      model,
      loadConfirmedAt: new Date(),
      terrain,
    })!;
    progress = step.progress;
    poses.push({
      phase: progress.phase,
      agl: step.altitudeM,
      msl: step.altitudeMslM,
    });
  }
  return { progress, poses, terrain };
}

describe('Vuelo sobre el terreno (RF-46)', () => {
  it('subir la ladera cuesta la batería de sus metros', () => {
    const flat = fly(false);
    const hill = fly(true);
    const climbCost = hill.terrain!.climbM * model.climbPercentPerM;
    expect(climbCost).toBeGreaterThan(4);
    expect(
      flat.progress.batteryPercent - hill.progress.batteryPercent,
    ).toBeCloseTo(climbCost, 0);
  });

  it('en crucero vuela entre 60 y 120 m sobre el terreno y reporta la altitud MSL', () => {
    const { poses } = fly(true);
    const cruise = poses.filter((pose) => pose.phase === FlightPhase.CRUISE);
    expect(cruise.length).toBeGreaterThan(0);
    for (const pose of cruise) {
      expect(pose.agl).toBeGreaterThanOrEqual(60);
      expect(pose.agl).toBeLessThanOrEqual(120);
      expect(pose.msl).not.toBeNull();
    }
    expect(Math.max(...cruise.map((pose) => pose.msl ?? 0))).toBeGreaterThan(
      900,
    );
  });

  it('sin perfil, la altura es la fija y no hay altitud MSL', () => {
    const { poses } = fly(false);
    const cruise = poses.find((pose) => pose.phase === FlightPhase.CRUISE)!;
    expect(cruise.agl).toBe(90);
    expect(cruise.msl).toBeNull();
  });
});
