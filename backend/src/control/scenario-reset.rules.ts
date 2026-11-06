import { DroneStatus } from '../common/enums/drone-status.enum';
import { addCalendarDays } from '../orders/orders.rules';
import { DemoHubPlan } from './demo-scenario';

/** RF-40: el reinicio devuelve el escenario de la semilla, no lo crea. */
export const NO_DEMO_SCENARIO =
  'No existe el escenario de demostración. Primero corre pnpm seed:demo en el backend.';

export type DroneReset = {
  status: DroneStatus;
  maintenanceReason: string | null;
  maintenanceUntil: string | null;
};

/**
 * Como lo deja `pnpm seed:demo`: el dron con nota queda en mantenimiento con
 * su motivo y su fecha; los demás, disponibles.
 */
export function droneResetState(
  identifier: string,
  plan: DemoHubPlan,
  today: string,
): DroneReset {
  const note = plan.droneNotes.find(
    (entry) => identifier === `${plan.dronePrefix}-0${entry.number}`,
  );
  if (!note) {
    return {
      status: DroneStatus.AVAILABLE,
      maintenanceReason: null,
      maintenanceUntil: null,
    };
  }
  return {
    status: DroneStatus.MAINTENANCE,
    maintenanceReason: note.reason,
    maintenanceUntil: addCalendarDays(today, note.inDays),
  };
}

/** El inventario de la semilla para una central, con vencimientos desde hoy. */
export function stockRows(plan: DemoHubPlan, hubId: string, today: string) {
  return plan.stock.map((item) => ({
    hubId,
    name: item.name,
    quantity: item.quantity,
    lot: item.lot,
    expirationDate: addCalendarDays(today, item.expiresInDays),
    requiresColdChain: item.cold ?? false,
    saleType: item.saleType,
  }));
}

export type ResetSummary = {
  orders: number;
  drones: number;
  inventoryItems: number;
  geofences: number;
  /** RF-36: geovallas temporales borradas. */
  temporaryGeofences: number;
};

export function resetDetail(summary: ResetSummary): string {
  const temporary = summary.temporaryGeofences
    ? ` ${summary.temporaryGeofences} ${summary.temporaryGeofences === 1 ? 'geovalla temporal quitada' : 'geovallas temporales quitadas'}.`
    : '';
  return `${summary.orders} pedidos borrados; ${summary.drones} drones en su central; ${summary.inventoryItems} lotes y ${summary.geofences} geovallas como en la semilla.${temporary}`;
}
