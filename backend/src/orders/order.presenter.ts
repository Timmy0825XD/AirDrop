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
    statusReason: order.statusReason,
    planId: order.planId,
    scheduledFor: order.scheduledFor,
    hasPrescription: order.saleType === SaleType.PRESCRIPTION,
    createdAt: order.createdAt,
  };
}
