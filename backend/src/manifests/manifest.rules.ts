import { COLD_COMPARTMENT_KG } from '../fleet/drone-types';
import { ManifestItem } from './cargo-manifest.entity';

/** RF-47: quien firma cuando confirma el despachador automático (RF-37). */
export const AUTO_DISPATCHER_NAME = 'Despachador automático';

/** `context/entregas/productos.md`: en la demo todo ítem con frío usa 2–8 °C. */
export const COLD_RANGE = '2–8 °C';

export const MANIFEST_REPLACED = 'Nueva carga confirmada para el pedido.';
export const MANIFEST_NOT_FOUND = 'El pedido todavía no tiene manifiesto.';
export const MANIFEST_FORBIDDEN = 'No puedes ver el manifiesto de este pedido.';

/** RF-47: consecutivo por año, único: `MAN-2026-000123`. */
export function manifestNumber(year: number, sequence: number): string {
  return `MAN-${year}-${String(sequence).padStart(6, '0')}`;
}

/** El año del manifiesto es el de la hora simulada en Colombia. */
export function manifestYear(issuedAt: Date): number {
  return Number(
    new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Bogota',
      year: 'numeric',
    }).format(issuedAt),
  );
}

export type ManifestSource = {
  medicationName: string;
  quantity: number;
  dispatchedLot: string | null;
  dispatchedLotExpiresOn: string | null;
  payloadKg: number | null;
  requiresColdChain: boolean;
};

/** El contenido por ítem: medicamento, lote, vencimiento y cantidad. */
export function manifestItems(order: ManifestSource): ManifestItem[] {
  return [
    {
      medicationName: order.medicationName,
      lot: order.dispatchedLot ?? 'Sin lote',
      expiresOn: order.dispatchedLotExpiresOn ?? '',
      quantity: order.quantity,
    },
  ];
}

/** Peso y frío: el compartimento cuenta si el dron lo lleva instalado. */
export function manifestCold(
  order: ManifestSource,
  coldCompartment: boolean,
): { coldCompartmentKg: number | null; coldRange: string | null } {
  return {
    coldCompartmentKg: coldCompartment ? COLD_COMPARTMENT_KG : null,
    coldRange: order.requiresColdChain ? COLD_RANGE : null,
  };
}
