/**
 * RF-34: lo que le pasa a un dron en vuelo. Los cuatro primeros los detecta
 * el reloj de vuelo; los demás los lanza la consola (CU-38) o el modo caos.
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
  /** Sube el consumo el resto del vuelo. */
  BATTERY_DEGRADED = 'battery_degraded',
  /** 1 de los 8 motores: vuelo degradado, más consumo y menos velocidad. */
  MOTOR_FAILURE = 'motor_failure',
  /** 2 motores: aterrizaje de emergencia. */
  DUAL_MOTOR_FAILURE = 'dual_motor_failure',
  /** Sigue con el sistema de posición de respaldo. */
  GPS_LOSS_MINOR = 'gps_loss_minor',
  /** Sin posición confiable: aterrizaje de emergencia. */
  GPS_LOSS_MAJOR = 'gps_loss_major',
  /** Procedimiento de enlace perdido: vuelve solo a la central. */
  LINK_LOSS = 'link_loss',
  /** La carga con frío empieza a calentarse (RF-17). */
  COOLING_FAILURE = 'cooling_failure',
  /** Ave u obstáculo: sube el consumo. */
  COLLISION_MINOR = 'collision_minor',
  /** Cae donde va; el dron queda fuera de servicio y el paquete se pierde. */
  COLLISION_MAJOR = 'collision_major',
  /** Sin rastro: fuera de servicio y paquete perdido. */
  DRONE_LOST = 'drone_lost',
}

/** CU-38: los que la consola puede lanzar sobre un dron en vuelo. */
export const CONSOLE_INCIDENT_KINDS = [
  IncidentKind.BATTERY_DEGRADED,
  IncidentKind.MOTOR_FAILURE,
  IncidentKind.DUAL_MOTOR_FAILURE,
  IncidentKind.GPS_LOSS_MINOR,
  IncidentKind.GPS_LOSS_MAJOR,
  IncidentKind.LINK_LOSS,
  IncidentKind.COOLING_FAILURE,
  IncidentKind.COLLISION_MINOR,
  IncidentKind.COLLISION_MAJOR,
  IncidentKind.DRONE_LOST,
] as const;
