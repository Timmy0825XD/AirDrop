import { DroneMaintenanceKind } from '../common/enums/drone-maintenance-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';

/**
 * Mantenimiento preventivo (CU-17): cada cuántos vuelos se revisa un dron.
 * `DRONE_MAINTENANCE_CYCLES` lo cambia (por ejemplo, 2 para la demo).
 */
export const DEFAULT_MAINTENANCE_CYCLES = 50;

export function maintenanceCycles(): number {
  const configured = Number(process.env.DRONE_MAINTENANCE_CYCLES);
  return Number.isInteger(configured) && configured > 0
    ? configured
    : DEFAULT_MAINTENANCE_CYCLES;
}

/** Ya le toca revisión: sigue volando, pero el operador debe programarla. */
export function isMaintenanceDue(
  flightsSinceMaintenance: number,
  cycles = maintenanceCycles(),
): boolean {
  return flightsSinceMaintenance >= cycles;
}

/**
 * La fecha estimada pasó y el dron sigue en mantenimiento. No se libera solo:
 * el técnico confirma que sirve (o mueve la fecha).
 */
export function isMaintenanceOverdue(
  drone: { status: DroneStatus; maintenanceUntil: string | null },
  today: string,
): boolean {
  return (
    drone.status === DroneStatus.MAINTENANCE &&
    drone.maintenanceUntil !== null &&
    drone.maintenanceUntil < today
  );
}

/** El periodo de taller que abre cada estado (disponible no abre ninguno). */
export function periodKindFor(
  status: DroneStatus,
): DroneMaintenanceKind | null {
  if (status === DroneStatus.MAINTENANCE) {
    return DroneMaintenanceKind.MAINTENANCE;
  }
  if (status === DroneStatus.OUT_OF_SERVICE) {
    return DroneMaintenanceKind.OUT_OF_SERVICE;
  }
  return null;
}

/** Solo un mantenimiento cerrado deja al dron revisado (cuenta desde cero). */
export function closingResetsCycles(
  kind: DroneMaintenanceKind | null,
): boolean {
  return kind === DroneMaintenanceKind.MAINTENANCE;
}

export function overdueNotice(identifier: string, until: string) {
  return {
    title: 'Mantenimiento vencido',
    body: `El mantenimiento del dron ${identifier} debía terminar el ${until}. Libéralo si ya está listo o cambia la fecha estimada.`,
  };
}

export function dueNotice(identifier: string, flights: number) {
  return {
    title: 'Le toca revisión a un dron',
    body: `El dron ${identifier} lleva ${flights} vuelos desde su último mantenimiento. Sigue volando, pero programa su revisión.`,
  };
}
