import { randomBytes } from 'node:crypto';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SUBSTANTIAL_POLICY_VERSION } from './privacy-policy';

export const POLICY_VERSION_MISMATCH =
  'Esa no es la versión vigente de la política.';
export const POLICY_NOT_ACCEPTED =
  'Acepta la política de tratamiento vigente para seguir.';
export const WRONG_PASSWORD = 'La contraseña no es correcta.';
export const ONLY_REQUESTERS =
  'Solo el solicitante gestiona aquí sus datos; el personal lo hace con el administrador.';
export const ORDER_IN_PROGRESS =
  'Tienes un pedido en curso: la supresión espera a que se entregue o vuelva.';
export const CONSENT_REVOKED_LOGIN =
  'Revocaste el consentimiento: tu cuenta está inactiva.';
export const REVOKED_REASON = 'El titular revocó el consentimiento.';
export const SUPPRESSED_REASON = 'El titular pidió la supresión de sus datos.';

/** La explicación que la app muestra antes de confirmar (CU-46). */
export const REVOKE_NOTICE = [
  'Tu cuenta queda inactiva: no podrás entrar ni crear pedidos y no te enviaremos correos.',
  'Los pedidos que todavía no tienen dron se cancelan; los que ya salieron terminan.',
  'Revocar no borra tus datos: para eso pide la supresión.',
];
export const SUPPRESS_NOTICE = [
  'Se borran tu correo, tu celular y tu contraseña; el correo y el celular quedan libres.',
  'Tus pedidos se anonimizan: tu nombre y tu documento se reemplazan por un identificador.',
  'Se conservan el medicamento, el lote, la fecha y el punto, porque la norma farmacéutica obliga a guardar el registro de dispensación.',
  'Con un pedido en curso, la supresión espera a que termine.',
];

/** Con dron reservado o en el aire: la supresión espera (CU-46). */
export const IN_PROGRESS_STATUSES = [
  OrderStatus.UNDER_REVIEW,
  OrderStatus.ASSIGNED,
  OrderStatus.PENDING_LOAD,
  OrderStatus.IN_FLIGHT,
  OrderStatus.AWAITING_DELIVERY,
  OrderStatus.RETURNING,
];

/** RF-50: ¿tiene que aceptar la política en este ingreso? */
export function mustAcceptPolicy(acceptedVersion: string | null): boolean {
  return (
    acceptedVersion == null ||
    compareVersions(acceptedVersion, SUBSTANTIAL_POLICY_VERSION) < 0
  );
}

export function compareVersions(left: string, right: string): number {
  const a = left.split('.').map(Number);
  const b = right.split('.').map(Number);
  for (let index = 0; index < Math.max(a.length, b.length); index += 1) {
    const diff = (a[index] ?? 0) - (b[index] ?? 0);
    if (diff !== 0) {
      return diff;
    }
  }
  return 0;
}

/** Un identificador sin relación con la persona (`ANON-3f9a1c07`). */
export function pseudonym(random: (size: number) => Buffer = randomBytes) {
  return `ANON-${random(4).toString('hex')}`;
}
