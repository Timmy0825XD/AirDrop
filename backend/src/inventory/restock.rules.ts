import { QuarantineReason } from '../common/enums/quarantine-reason.enum';

export const ONLY_RETURNED_IS_CHECKED =
  'Solo se revisa un pedido que volvió sin entregar.';

export const RETURN_ALREADY_CHECKED = 'Este retorno ya se revisó.';

export const NOT_THE_RETURN_HUB =
  'Solo el despachador de la central de origen revisa el retorno.';

export const RECEIPT_CHECK_REQUIRED =
  'Confirma si la remisión coincide y si el sello llegó intacto.';

export const RECEIPT_COLD_CHAIN =
  'Hubo alerta de frío en el trayecto. El paquete vuelve a origen.';

export const RECEIPT_SEAL_BROKEN =
  'El sello llegó roto. El paquete vuelve a origen.';

export const RECEIPT_REMISSION_MISMATCH =
  'La remisión no coincide. El paquete vuelve a origen.';

/**
 * Cuarentena de productos.md: con alerta de frío, o con el empaque
 * comprometido (lo marca el despachador al revisar, o el sello llegó roto a
 * la central de destino), el insumo no reingresa.
 */
export function quarantineReasonFor(input: {
  coldChainAlert: boolean;
  packagingIntact: boolean;
  receiptSealIntact: boolean | null;
}): QuarantineReason | null {
  if (input.coldChainAlert) {
    return QuarantineReason.COLD_CHAIN;
  }
  if (!input.packagingIntact || input.receiptSealIntact === false) {
    return QuarantineReason.PACKAGING;
  }
  return null;
}

/**
 * centrales.md, paso 6: el traslado no entra en destino si hubo alerta de
 * frío, el sello está mal o la remisión no coincide. `null` = se recibe.
 */
export function receiptRejection(input: {
  coldChainAlert: boolean;
  remissionMatches: boolean;
  sealIntact: boolean;
}): string | null {
  if (input.coldChainAlert) {
    return RECEIPT_COLD_CHAIN;
  }
  if (!input.sealIntact) {
    return RECEIPT_SEAL_BROKEN;
  }
  if (!input.remissionMatches) {
    return RECEIPT_REMISSION_MISMATCH;
  }
  return null;
}
