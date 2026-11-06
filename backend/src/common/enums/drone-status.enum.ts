export enum DroneStatus {
  AVAILABLE = 'available',
  IN_MISSION = 'in_mission',
  /**
   * RF-34: aterrizó de emergencia fuera de su central y espera el rescate.
   * Después pasa a mantenimiento.
   */
  GROUNDED = 'grounded',
  MAINTENANCE = 'maintenance',
  OUT_OF_SERVICE = 'out_of_service',
}
