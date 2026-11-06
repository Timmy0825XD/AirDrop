/** Un periodo de un dron fuera de la flota (CU-16, CU-17). */
export enum DroneMaintenanceKind {
  /** Temporal: con fecha estimada de fin. Al cerrarlo, el dron queda revisado. */
  MAINTENANCE = 'maintenance',
  /** Indefinido: el dron no vuela hasta que el técnico lo libere. */
  OUT_OF_SERVICE = 'out_of_service',
}
