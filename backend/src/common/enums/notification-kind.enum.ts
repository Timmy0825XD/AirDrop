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
  /** Al operador: la fecha estimada del mantenimiento ya pasó. */
  MAINTENANCE_OVERDUE = 'maintenance_overdue',
  /** Al operador: el dron cumplió los vuelos del preventivo. */
  MAINTENANCE_DUE = 'maintenance_due',
  /** A los despachadores: su central se quedó sin energía (RF-36). */
  HUB_OUTAGE = 'hub_outage',
  /** A los despachadores: volvió la energía a su central. */
  HUB_POWER_RESTORED = 'hub_power_restored',
}
