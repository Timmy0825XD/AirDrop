/** Estados de RU-03, más `cancelled` para quien cancela su plan. */
export enum OrderStatus {
  RECEIVED = 'received',
  UNDER_REVIEW = 'under_review',
  ASSIGNED = 'assigned',
  PENDING_LOAD = 'pending_load',
  IN_FLIGHT = 'in_flight',
  AWAITING_DELIVERY = 'awaiting_delivery',
  DELIVERED = 'delivered',
  RETURNING = 'returning',
  RETURNED = 'returned',
  REJECTED = 'rejected',
  REASSIGNED = 'reassigned',
  CANCELLED = 'cancelled',
}
