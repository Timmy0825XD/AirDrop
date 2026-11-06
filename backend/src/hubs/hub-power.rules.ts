/**
 * RF-36 y CU-45: una central sin energía no autoriza ni confirma cargas, y
 * sus drones no son elegibles. Los drones que vuelven a ella aterrizan igual.
 */

export const HUB_WITHOUT_POWER =
  'La central está sin energía: no puede autorizar ni confirmar cargas hasta que vuelva.';
export const HUB_ALREADY_WITHOUT_POWER = 'Esa central ya está sin energía.';
export const HUB_HAS_POWER = 'Esa central tiene energía.';
export const SUSPENDED_HUB_OUTAGE =
  'La central está suspendida: un apagón no cambia nada.';

/** Nota de la traza de decisión para la central que se saltó. */
export const HUB_WITHOUT_POWER_NOTE = 'La central está sin energía.';

/** Motivo con que la central sin energía sale de la oferta de una urgencia. */
export const OUTAGE_DECLINE_REASON = 'Central sin energía';

/** Motivo de los pedidos que la central sin energía tenía por cargar. */
export const OUTAGE_REDISPATCH_REASON =
  'La central se quedó sin energía; el pedido pasa a otra central o se reintenta.';

export function isPowered(
  hub: { powerOutageUntil?: Date | null },
  now: Date,
): boolean {
  return (
    hub.powerOutageUntil == null ||
    new Date(hub.powerOutageUntil).getTime() <= now.getTime()
  );
}

export function outageEnd(now: Date, durationMin: number): Date {
  return new Date(now.getTime() + durationMin * 60_000);
}
