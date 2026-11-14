import { Injectable } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PlannedCorridor } from '../routing/routing.rules';
import { TerrainGrid, TerrainProfile, terrainProfile } from './terrain.rules';

/**
 * RF-46: la malla de terreno de la región (`terrain-grid.json`, generada una
 * vez con `scripts/build-terrain-grid.py`). Vive en memoria: muestrear una
 * ruta no va a la base ni a internet.
 */
@Injectable()
export class TerrainService {
  private readonly grid: TerrainGrid = loadGrid();

  profile(
    corridor: Pick<PlannedCorridor, 'coordinates'>,
    model: { verticalSpeedMs: number; maxSpeedKmh: number },
  ): TerrainProfile {
    return terrainProfile(this.grid, corridor, model);
  }

  view(): TerrainGrid {
    return this.grid;
  }
}

let cached: TerrainGrid | null = null;

/** Lee la malla una sola vez por proceso. */
export function loadGrid(): TerrainGrid {
  if (!cached) {
    cached = JSON.parse(
      readFileSync(join(__dirname, 'terrain-grid.json'), 'utf8'),
    ) as TerrainGrid;
  }
  return cached;
}
