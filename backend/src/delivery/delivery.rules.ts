import { createHmac, timingSafeEqual } from 'node:crypto';
import { FIELD_LIMITS } from '../common/field-limits';

/** CU-29: el solicitante tiene 5 minutos desde el aterrizaje. */
export const DEFAULT_DELIVERY_WAIT_MS = 5 * 60 * 1000;

export const ONLY_AWAITING_DELIVERY_IS_DELIVERED =
  'Solo se entrega un pedido en espera de entrega.';
export const DELIVERY_CODE_NOT_READY =
  'El código aparece cuando el despachador confirma la carga.';
export const DELIVERY_CODE_NOT_AVAILABLE =
  'Este pedido ya no tiene un código de entrega vigente.';
export const ORDER_ALREADY_DELIVERED = 'Este pedido ya fue entregado.';
export const DELIVERY_WAIT_EXPIRED = 'El tiempo para recibir el pedido venció.';
/** Tope de códigos equivocados por pedido, como el login (RNF-04). */
export const DELIVERY_CODE_MAX_ATTEMPTS = 5;

export const DELIVERY_CODE_LOCKED =
  'Se agotaron los intentos. El dron regresa con el paquete.';
export const DELIVERY_CODE_REJECTED =
  'El código es inválido, ya se usó o venció.';

/**
 * Tiempo de espera del código. `DELIVERY_WAIT_MS` permite acortarlo en las
 * pruebas; sin variable (o con un valor no válido) son 5 minutos.
 */
export function deliveryWaitMs(): number {
  const configured = Number(process.env.DELIVERY_WAIT_MS);
  return Number.isInteger(configured) && configured > 0
    ? configured
    : DEFAULT_DELIVERY_WAIT_MS;
}

/** Tras el código correcto, el dron espera 1 minuto a que retiren el medicamento. */
export const DEFAULT_PICKUP_WAIT_MS = 60 * 1000;

/**
 * `PICKUP_WAIT_MS` permite acortar el retiro en pruebas; sin variable (o con
 * un valor no válido) es 1 minuto.
 */
export function pickupWaitMs(): number {
  const configured = Number(process.env.PICKUP_WAIT_MS);
  return Number.isInteger(configured) && configured > 0
    ? configured
    : DEFAULT_PICKUP_WAIT_MS;
}

export function deliveryExpiresAt(landedAt: Date): Date {
  return new Date(landedAt.getTime() + deliveryWaitMs());
}

/** CU-30: pasada la espera sin código, el dron vuelve con el paquete. */
export function isDeliveryWaitOver(landedAt: Date, now: Date): boolean {
  return now.getTime() >= deliveryExpiresAt(landedAt).getTime();
}

export function isDeliveryCodeLocked(code: { attempts: number }): boolean {
  return code.attempts >= DELIVERY_CODE_MAX_ATTEMPTS;
}

/**
 * CU-19: el código existe desde que se confirma la carga. Se deriva con HMAC
 * del pedido y de ese instante, así quien recibe puede verlo mientras el dron
 * vuela sin que el código se guarde en claro.
 */
export function deliveryCodeFor(
  order: { id: string; loadConfirmedAt: Date },
  secret: string,
): string {
  const digest = createHmac('sha256', secret)
    .update(`delivery-code:${order.id}:${order.loadConfirmedAt.toISOString()}`)
    .digest();
  return (digest.readUInt32BE(0) % 10 ** FIELD_LIMITS.otpDigits)
    .toString()
    .padStart(FIELD_LIMITS.otpDigits, '0');
}

export function isDeliveryCodeUsable(
  code: { usedAt: Date | null },
  landedAt: Date,
  now: Date,
): boolean {
  return code.usedAt === null && !isDeliveryWaitOver(landedAt, now);
}

export function deliveryCodeMatches(
  received: string,
  expected: string,
): boolean {
  const left = Buffer.from(received);
  const right = Buffer.from(expected);
  return left.length === right.length && timingSafeEqual(left, right);
}
