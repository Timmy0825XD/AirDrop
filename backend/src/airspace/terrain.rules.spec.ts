import { DRONE_TYPES } from '../fleet/drone-types';
import {
  CRUISE_AGL_M,
  MAX_AGL_M,
  MIN_AGL_M,
  TerrainGrid,
  altitudeAt,
  climbPercentPerM,
  groundAt,
  maxClimbPerKm,
  terrainProfile,
} from './terrain.rules';
import { loadGrid } from './terrain.service';

/**
 * RF-46 con una malla sintética: 1 fila × 40 columnas de 0,0045° (~500 m)
 * hacia el este. Plano a 100 m y, desde la columna 20, una ladera de 1.000 m.
 */
function syntheticGrid(): TerrainGrid {
  const cols = 40;
  const values = Array.from({ length: cols }, (_, col) =>
    col < 20 ? 100 : 1100,
  );
  return {
    south: 10,
    west: -73,
    cellDeg: 0.0045,
    rows: 1,
    cols,
    maxElevationM: values,
  };
}

const garza = DRONE_TYPES[1];
const line = (fromCol: number, toCol: number) => ({
  coordinates: [
    [-73 + 0.0045 * (fromCol + 0.5), 10.002],
    [-73 + 0.0045 * (toCol + 0.5), 10.002],
  ] as Array<[number, number]>,
});

describe('Perfil de terreno (RF-46)', () => {
  it('en plano vuela a 90 m sobre el terreno y no sube', () => {
    const profile = terrainProfile(syntheticGrid(), line(0, 15), garza);
    expect(profile.climbM).toBe(0);
    for (const sample of profile.samples) {
      expect(sample.altitudeMslM - sample.groundM).toBe(CRUISE_AGL_M);
    }
  });

  it('ante una ladera empieza a subir antes, sin pasar de 120 m AGL', () => {
    const profile = terrainProfile(syntheticGrid(), line(5, 35), garza);
    const climbing = profile.samples.filter(
      (sample) =>
        sample.groundM === 100 &&
        sample.altitudeMslM - sample.groundM > CRUISE_AGL_M,
    );
    expect(climbing.length).toBeGreaterThan(0);
    for (const sample of profile.samples) {
      const agl = sample.altitudeMslM - sample.groundM;
      expect(agl).toBeGreaterThanOrEqual(MIN_AGL_M);
      if (sample.groundM === 100) {
        expect(agl).toBeLessThanOrEqual(MAX_AGL_M);
      }
    }
    // Sube lo justo: de 190 a 220 m (techo de 120 AGL antes de la ladera) y
    // de ahí al piso de 60 m sobre la meseta (1.160 m).
    expect(profile.climbM).toBe(970);
    expect(profile.peakMslM).toBe(1100 + MIN_AGL_M);
  });

  it('bajar no cuenta como subida', () => {
    const down = terrainProfile(syntheticGrid(), line(35, 5), garza);
    expect(down.climbM).toBe(0);
  });

  it('la subida máxima por km sale de la velocidad vertical y el crucero', () => {
    // Garza: 4 m/s × 3.600 s / 110 km/h ≈ 131 m por km.
    expect(maxClimbPerKm(garza)).toBeCloseTo(130.9, 1);
  });

  it('subir 100 m cuesta lo que dice condiciones-de-vuelo.md', () => {
    const [colibri, , condor] = DRONE_TYPES;
    expect(climbPercentPerM(colibri) * 100).toBeCloseTo(0.545, 3);
    expect(climbPercentPerM(garza) * 100).toBeCloseTo(0.65, 2);
    expect(climbPercentPerM(condor) * 100).toBeCloseTo(1.23, 2);
    expect(climbPercentPerM({})).toBe(0);
  });

  it('la altitud entre muestras se interpola', () => {
    const profile = terrainProfile(syntheticGrid(), line(0, 4), garza);
    const middle = altitudeAt(profile, profile.samples[1].km / 2);
    expect(middle.altitudeMslM).toBe(190);
  });
});

describe('Malla real de la región (terrain-grid.json)', () => {
  const grid = loadGrid();

  it('coincide con la elevación conocida de los pueblos (±80 m)', () => {
    const known: Array<[number, number, number]> = [
      [10.43513, -73.2494, 148], // ARP de SKVP (AIP)
      [10.4171, -73.5804, 1108], // Pueblo Bello
      [10.0367, -73.2356, 136], // Agustín Codazzi
      [10.3928, -73.0325, 726], // Manaure
    ];
    for (const [latitude, longitude, elevation] of known) {
      expect(
        Math.abs(groundAt(grid, { latitude, longitude }) - elevation),
      ).toBeLessThanOrEqual(80);
    }
  });

  it('fuera de la malla devuelve la del borde', () => {
    expect(groundAt(grid, { latitude: 0, longitude: -80 })).toBe(
      grid.maxElevationM[0],
    );
  });
});
