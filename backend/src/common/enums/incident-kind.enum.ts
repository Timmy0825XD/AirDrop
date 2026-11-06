/**
 * RF-34: lo que le pasa a un dron en vuelo. Estos los detecta el reloj de
 * vuelo; el catálogo de la consola (fallas, choques) llega con su rama.
 */
export enum IncidentKind {
  /** La batería bajó del 20 % (CU-32). */
  BATTERY_CRITICAL = 'battery_critical',
  /** RF-32: el viento donde va el dron pasa del límite del Wingcopter. */
  WIND_LIMIT = 'wind_limit',
  /** RF-33: una zona nueva cruza el tramo que falta y no hay otro camino. */
  ROUTE_BLOCKED = 'route_blocked',
  /** RF-33: hay camino nuevo, pero la batería no alcanza para terminarlo. */
  BATTERY_SHORT = 'battery_short',
}
