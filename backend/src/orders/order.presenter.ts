import { SaleType } from '../common/enums/sale-type.enum';
import { Order } from './order.entity';

export function presentOrder(order: Order) {
  return {
    id: order.id,
    missionType: order.missionType,
    destinationKind: order.destinationKind,
    status: order.status,
    priority: order.priority,
    medicationName: order.medicationName,
    saleType: order.saleType,
    requiresColdChain: order.requiresColdChain,
    quantity: order.quantity,
    description: order.description,
    requesterId: order.requesterId,
    createdByUserId: order.createdByUserId,
    destinationHubId: order.destinationHubId,
    originHubId: order.originHubId,
    address: order.address,
    latitude: order.latitude,
    longitude: order.longitude,
    droneId: order.droneId,
    loadConfirmedAt: order.loadConfirmedAt,
    statusReason: order.statusReason,
    planId: order.planId,
    scheduledFor: order.scheduledFor,
    hasPrescription: order.saleType === SaleType.PRESCRIPTION,
    reassignedFromHubId: order.reassignedFromHubId,
    fallback: presentFallback(order),
    createdAt: order.createdAt,
  };
}

/** RF-18 y CU-05: la alternativa que ve quien pidió, mientras aplica. */
function presentFallback(order: Order) {
  if (!order.fallbackKind) {
    return null;
  }
  return {
    kind: order.fallbackKind,
    reason: order.fallbackReason,
    options: order.fallbackOptions ?? [],
    retryAfter: order.retryAfter,
    reassignedAt: order.reassignedAt,
  };
}
