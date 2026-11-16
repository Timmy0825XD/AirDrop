/**
 * RF-43: los tipos de zona legal de `context/operacion/espacio-aereo.md`, a
 * escala de demo. La restricción temporal no está aquí: es una geovalla con
 * vencimiento (RF-36).
 */
export enum AirspaceZoneKind {
  /** Aeródromo de la AIP: 1,5 km desde el ARP (RAC 100.315(a)(14)). */
  AERODROME = 'aerodrome',
  /** Policía o CAI, base, cárcel, infraestructura crítica o pista agrícola (100.315(a)(13)). */
  PROHIBITED = 'prohibited',
  /** Helipuerto: 300 m desde su punto de referencia (100.315(a)(15)). */
  HELIPORT = 'heliport',
}
