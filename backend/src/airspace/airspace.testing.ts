import { AirspaceService } from './airspace.service';

/**
 * Para pruebas que no tratan de la norma aérea: un espacio aéreo sin zonas,
 * para que una central o un destino de prueba en la ciudad no choque con el
 * anillo del aeropuerto.
 */
export const NO_AIRSPACE = {
  all: () => [],
  blockingPolygons: () => [],
  coordinatedZones: () => [],
  restrictionAt: () => null,
  assertHubLocation: () => undefined,
  view: () => [],
} as unknown as AirspaceService;
