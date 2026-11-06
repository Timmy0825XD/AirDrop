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

export type PendingAlert = {
  orderId: string;
  droneId: string;
  identifier: string;
  hubId: string;
  kinds: FlightAlertKind[];
  latitude: number | null;
  longitude: number | null;
};

export function pendingAlertKinds(
  mission: {
    batteryAlert: boolean;
    failureAlert: boolean;
    returnedAt: Date | null;
  },
  order: { status: OrderStatus; coldChainAlertAt: Date | null },
): FlightAlertKind[] {
  if (mission.returnedAt || !ALERT_OPEN_STATUSES.includes(order.status)) {
    return [];
  }
  const kinds: FlightAlertKind[] = [];
  if (mission.batteryAlert) kinds.push('battery_critical');
  if (mission.failureAlert) kinds.push('failure');
  if (order.coldChainAlertAt) kinds.push('cold_chain');
  return kinds;
}
