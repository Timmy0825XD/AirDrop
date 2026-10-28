/** Avisos de la bandeja (RU-05). */
export enum NotificationKind {
  /** T-24 h: la entrega llega pronto y hay que confirmarla. */
  CONFIRM_DELIVERY = 'confirm_delivery',
  /** T-24 h de un abastecimiento: llega a la central, ya confirmado. */
  INCOMING_SUPPLY = 'incoming_supply',
  /** T-24 h para la central de origen de un abastecimiento: le toca despachar. */
  DISPATCH_SOON = 'dispatch_soon',
  /** Puede no haber stock para una entrega próxima. */
  STOCK_WARNING = 'stock_warning',
  /** La entrega se omitió (sin confirmar o plan en pausa). */
  DELIVERY_SKIPPED = 'delivery_skipped',
  /** El dron despegó y se avisa a qué hora llega. */
  DEPARTED = 'departed',
  /** La franja cerró sin despegue. */
  DELIVERY_MISSED = 'delivery_missed',
}
