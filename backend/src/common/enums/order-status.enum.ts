/** Estados de RU-03, más `cancelled` para quien cancela su plan. */
export enum OrderStatus {
  /** Entrega de un plan con franja, todavía lejos: nadie la ha confirmado. */
  SCHEDULED = 'scheduled',
  /** Se avisó a quien recibe (T-24 h) y falta que confirme. */
  AWAITING_CONFIRMATION = 'awaiting_confirmation',
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
  /** Quien recibe la omitió, o no confirmó 2 horas antes de la franja. */
  SKIPPED = 'skipped',
  /** La franja cerró y el dron no despegó. */
  EXPIRED = 'expired',
}
