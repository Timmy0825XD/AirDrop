/**
 * RF-21: la clase de una geovalla. Las tres primeras son las zonas legales
 * (RF-43, mismos valores que `AirspaceZoneKind`); la operativa la dibuja el
 * operador y la temporal la lanza la consola (RF-36).
 */
export enum GeofenceClass {
  AERODROME = 'aerodrome',
  PROHIBITED = 'prohibited',
  HELIPORT = 'heliport',
  OPERATIONAL = 'operational',
  TEMPORARY = 'temporary',
}

export const LEGAL_GEOFENCE_CLASSES: readonly GeofenceClass[] = [
  GeofenceClass.AERODROME,
  GeofenceClass.PROHIBITED,
  GeofenceClass.HELIPORT,
];

export function isLegalGeofenceClass(value: GeofenceClass): boolean {
  return LEGAL_GEOFENCE_CLASSES.includes(value);
}
