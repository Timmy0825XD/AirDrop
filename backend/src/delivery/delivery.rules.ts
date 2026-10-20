import { timingSafeEqual } from 'node:crypto';
import { hashOtp } from '../auth/auth.rules';

/** CU-29: el solicitante tiene 5 minutos desde el aterrizaje. */
export const DEFAULT_DELIVERY_WAIT_MS = 5 * 60 * 1000;

export const ONLY_AWAITING_DELIVERY_IS_DELIVERED =
  'Solo se entrega un pedido en espera de entrega.';
export const ORDER_ALREADY_DELIVERED = 'Este pedido ya fue entregado.';
export const DELIVERY_WAIT_EXPIRED = 'El tiempo para recibir el pedido venció.';
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

export function deliveryExpiresAt(landedAt: Date): Date {
  return new Date(landedAt.getTime() + deliveryWaitMs());
}

export function isDeliveryCodeUsable(
  code: { usedAt: Date | null; expiresAt: Date },
  now: Date,
): boolean {
  return code.usedAt === null && now.getTime() < code.expiresAt.getTime();
}

export function deliveryCodeMatches(code: string, codeHash: string): boolean {
  const received = Buffer.from(hashOtp(code), 'hex');
  const stored = Buffer.from(codeHash, 'hex');
  return received.length === stored.length && timingSafeEqual(received, stored);
}
