import { OrderStatus } from '../common/enums/order-status.enum';
import { FlightAlertKind } from '../simulation/simulation.rules';

/**
 * RF-39: una alerta queda pendiente mientras el dron no vuelva a su central.
 * Al cerrar la misión (`returnedAt`) se da por resuelta.
 */

/** Estados en que el dron todavía no ha vuelto (incluido el regreso tras entregar). */
export const ALERT_OPEN_STATUSES = [
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
  OrderStatus.RETURNING,
  OrderStatus.DELIVERED,
];

/** RF-34: además de las de vuelo, el dron que espera el rescate. */
export type PendingAlertKind = FlightAlertKind | 'emergency_landing';

export type PendingAlert = {
  orderId: string;
  droneId: string;
  identifier: string;
  hubId: string;
  kinds: PendingAlertKind[];
  latitude: number | null;
  longitude: number | null;
};

export function pendingAlertKinds(
  mission: {
    batteryAlert: boolean;
    failureAlert: boolean;
    windAlert?: boolean;
    returnedAt: Date | null;
  },
  order: { status: OrderStatus; coldChainAlertAt: Date | null },
  /**
   * RF-34: el dron de esta misión aterrizó de emergencia y no lo han
   * rescatado. Sigue abierta aunque el pedido ya salga con otro dron (RF-35).
   */
  grounded = false,
): PendingAlertKind[] {
  if (mission.returnedAt) {
    return [];
  }
  if (grounded) {
    const kinds: PendingAlertKind[] = ['emergency_landing'];
    if (mission.batteryAlert) kinds.push('battery_critical');
    if (mission.failureAlert) kinds.push('failure');
    if (mission.windAlert) kinds.push('wind_limit');
    return kinds;
  }
  if (!ALERT_OPEN_STATUSES.includes(order.status)) {
    return [];
  }
  const kinds: PendingAlertKind[] = [];
  if (mission.batteryAlert) kinds.push('battery_critical');
  if (mission.failureAlert) kinds.push('failure');
  if (mission.windAlert) kinds.push('wind_limit');
  if (order.coldChainAlertAt) kinds.push('cold_chain');
  return kinds;
}
