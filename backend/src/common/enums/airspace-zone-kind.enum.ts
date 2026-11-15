/**
 * RF-43: los tipos de zona legal de `context/operacion/espacio-aereo.md`.
 * La restricción temporal no está aquí: es una geovalla con vencimiento
 * (RF-36).
 */
export enum AirspaceZoneKind {
  /** Aeródromo de la AIP: anillo de 9 km desde el ARP (RAC 100.315(a)(14)). */
  AERODROME = 'aerodrome',
  /** Base militar, cárcel o infraestructura crítica, con 2 km (100.315(a)(13)). */
  PROHIBITED = 'prohibited',
  /** Helipuerto: 3 km desde su punto de referencia (100.315(a)(15)). */
  HELIPORT = 'heliport',
  /** Policía municipal o resguardo: solo por el corredor pactado. */
  COORDINATED = 'coordinated',
  /** Casco urbano de Valledupar: solo VLOS, así que no se vuela (100.220(b)). */
  URBAN = 'urban',
  /** Pista agrícola privada: se muestra y no bloquea. */
  CAUTION = 'caution',
}
