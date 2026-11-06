import { DestinationKind } from '../common/enums/destination-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { clearFallback } from './fallback.rules';

/**
 * RF-35 y CU-44: el pedido cuya misión no llegó por un incidente vuelve al
 * motor de decisión. No tiene un estado nuevo: sigue el flujo normal con
 * otro dron, y la carga se confirma otra vez.
 */

export const REDISPATCH_REASON =
  'El dron tuvo un incidente en vuelo; el pedido vuelve a despacharse.';

/** Por dónde vuelve a entrar el pedido. */
export type RedispatchPath =
  /** Urgencia a una persona: se ofrece otra vez a las centrales (RU-10). */
  | 'offers'
  /** Urgencia entre centrales: la misma central de origen la autoriza otra vez. */
  | 'same_hub'
  /** Programado: RF-18 (reintento en la franja, otra central o convencional). */
  | 'scheduled';

/** La misión se cae en vuelo (`in_flight`) o tras volver a la central (`returned`). */
export function canRedispatch(order: Pick<Order, 'status' | 'droneId'>) {
  return (
    order.droneId != null &&
    (order.status === OrderStatus.IN_FLIGHT ||
      order.status === OrderStatus.RETURNED)
  );
}

export function redispatchPath(
  order: Pick<Order, 'missionType' | 'destinationKind'>,
): RedispatchPath {
  if (order.missionType !== MissionType.EMERGENCY) {
    return 'scheduled';
  }
  return order.destinationKind === DestinationKind.PERSON
    ? 'offers'
    : 'same_hub';
}

/**
 * Suelta el dron, el lote y la carga confirmada. El paquete que se cayó ya
 * quedó en el incidente; el siguiente lote se descuenta al confirmar la
 * carga de nuevo (productos.md). El pedido queda `received`.
 */
export function releaseForRedispatch(order: Order, path: RedispatchPath): void {
  order.status = OrderStatus.RECEIVED;
  order.statusReason = REDISPATCH_REASON;
  order.droneId = null;
  order.inventoryItemId = null;
  order.authorizedAt = null;
  order.loadConfirmedAt = null;
  order.dispatchedLot = null;
  order.dispatchedLotExpiresOn = null;
  order.coldChainAlertAt = null;
  order.returnCheckedAt = null;
  order.returnOutcome = null;
  clearFallback(order);
  if (path === 'offers') {
    // RU-10 vuelve a calcular a quién ofrecerla, con la misma central incluida.
    order.originHubId = null;
    order.dispatchOffers = null;
    order.nextEscalationAt = null;
  }
}
