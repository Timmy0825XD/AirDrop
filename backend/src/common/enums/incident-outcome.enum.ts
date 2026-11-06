/** RF-34: en qué quedó el incidente. Cambia mientras se resuelve. */
export enum IncidentOutcome {
  /** El dron siguió su misión. */
  CONTINUED = 'continued',
  /** Va de vuelta a la central con el paquete. */
  RETURNING = 'returning',
  /** Llegó a la central; el paquete quedó en cuarentena. */
  RETURNED = 'returned',
  /** Va bajando al punto de aterrizaje de emergencia. */
  LANDING = 'landing',
  /** En tierra fuera de base, esperando el rescate. */
  GROUNDED = 'grounded',
  /** Lo rescataron: está en su central, en mantenimiento. */
  RESCUED = 'rescued',
}
