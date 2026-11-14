import { TerrainService } from './terrain.service';

/**
 * Para pruebas que no tratan del terreno: todo plano a nivel del mar, sin
 * subida (el comportamiento de antes de RF-46).
 */
export const FLAT_TERRAIN = {
  profile: () => ({ samples: [], climbM: 0, peakMslM: 90 }),
} as unknown as TerrainService;
