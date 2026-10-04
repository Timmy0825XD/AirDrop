import { BadRequestException } from '@nestjs/common';
import { normalizeDocumentNumber } from '../auth/auth.rules';
import { DocumentType } from '../common/enums/document-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { PRESCRIPTION_MAX_BYTES } from '../common/field-limits';
import { User } from '../users/user.entity';

export const SPECIAL_CONTROL_MESSAGE =
  'El control especial no se pide por este canal.';

export const PRESCRIPTION_IMAGE_REQUIRED =
  'La venta bajo fórmula exige la imagen de la fórmula.';

export const DOCUMENT_MISMATCH =
  'El documento de la cuenta debe ser el del paciente de la fórmula.';

export const FORMULA_NOT_FOR_TRANSFER =
  'Un traslado entre centrales no lleva fórmula de paciente.';

export const OVER_THE_COUNTER_HAS_NO_FORMULA =
  'La venta libre no lleva fórmula.';

export const COORDINATES_TOGETHER =
  'La ubicación lleva latitud y longitud juntas.';

export const COORDINATES_PRECISION =
  'Las coordenadas admiten hasta 6 decimales.';

export const SAME_HUB_MESSAGE =
  'La central de origen no puede ser la misma que la de destino.';

export const NO_STOCK_MESSAGE =
  'Ninguna central activa tiene ese medicamento disponible.';

export const ORIGIN_STOCK_MESSAGE =
  'La central de origen no tiene esa cantidad disponible.';

export const ONLY_RECEIVED_IS_REJECTED =
  'Solo se rechaza un pedido que sigue en recibido.';

export const NOT_THE_SUPPLYING_HUB =
  'Solo el despachador de la central que tiene el insumo rechaza este pedido.';

const PRESCRIPTION_MIMES = new Set(['image/jpeg', 'image/png']);

export function todayInColombia(now = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);
}

export function assertCoordinates(
  latitude?: number | null,
  longitude?: number | null,
): { latitude: number | null; longitude: number | null } {
  const hasLatitude = latitude !== undefined && latitude !== null;
  const hasLongitude = longitude !== undefined && longitude !== null;
  if (hasLatitude !== hasLongitude) {
    throw new BadRequestException(COORDINATES_TOGETHER);
  }
  if (!hasLatitude || !hasLongitude) {
    return { latitude: null, longitude: null };
  }
  if (!hasAtMostSixDecimals(latitude) || !hasAtMostSixDecimals(longitude)) {
    throw new BadRequestException(COORDINATES_PRECISION);
  }
  return { latitude, longitude };
}

export function patientFormula(
  user: User,
  saleType: SaleType,
  input: {
    patientDocumentType?: DocumentType;
    patientDocumentNumber?: string;
    prescriptionMime?: string;
    prescriptionImageBase64?: string;
  },
): Buffer | null {
  if (saleType === SaleType.SPECIAL_CONTROL) {
    throw new BadRequestException(SPECIAL_CONTROL_MESSAGE);
  }
  const hasImage = Boolean(input.prescriptionImageBase64);
  const hasDocument =
    input.patientDocumentType != null ||
    (input.patientDocumentNumber != null && input.patientDocumentNumber !== '');
  if (saleType !== SaleType.PRESCRIPTION) {
    if (hasImage || hasDocument) {
      throw new BadRequestException(OVER_THE_COUNTER_HAS_NO_FORMULA);
    }
    return null;
  }
  if (!hasImage || !input.prescriptionMime) {
    throw new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED);
  }
  if (!input.patientDocumentType || !input.patientDocumentNumber) {
    throw new BadRequestException(DOCUMENT_MISMATCH);
  }
  const normalized = normalizeDocumentNumber(
    input.patientDocumentType,
    input.patientDocumentNumber,
  );
  if (
    !normalized ||
    user.documentType !== input.patientDocumentType ||
    user.documentNumber !== normalized
  ) {
    throw new BadRequestException(DOCUMENT_MISMATCH);
  }
  return decodePrescription(
    input.prescriptionMime,
    input.prescriptionImageBase64!,
  );
}

export function assertNoPatientFormula(input: {
  patientDocumentType?: DocumentType;
  patientDocumentNumber?: string;
  prescriptionMime?: string;
  prescriptionImageBase64?: string;
  saleType: SaleType;
}): void {
  if (input.saleType === SaleType.SPECIAL_CONTROL) {
    throw new BadRequestException(SPECIAL_CONTROL_MESSAGE);
  }
  const hasFormula =
    Boolean(input.prescriptionImageBase64) ||
    Boolean(input.prescriptionMime) ||
    input.patientDocumentType != null ||
    (input.patientDocumentNumber != null && input.patientDocumentNumber !== '');
  if (hasFormula) {
    throw new BadRequestException(FORMULA_NOT_FOR_TRANSFER);
  }
}

export function decodePrescription(mime: string, base64: string): Buffer {
  if (!PRESCRIPTION_MIMES.has(mime)) {
    throw new BadRequestException('La fórmula debe ser una imagen JPEG o PNG.');
  }
  const payload = base64.includes(',')
    ? base64.slice(base64.indexOf(',') + 1)
    : base64;
  const cleaned = payload.replace(/\s/g, '');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(cleaned)) {
    throw new BadRequestException('La imagen de la fórmula no es válida.');
  }
  const content = Buffer.from(cleaned, 'base64');
  if (content.length === 0 || content.length > PRESCRIPTION_MAX_BYTES) {
    throw new BadRequestException(
      'La imagen de la fórmula debe pesar hasta 2 MB.',
    );
  }
  return content;
}

/** CU-11: el rechazo cierra el pedido. No reserva dron ni busca otra central. */
export function assertStillReceived(status: OrderStatus): void {
  if (status !== OrderStatus.RECEIVED) {
    throw new BadRequestException(ONLY_RECEIVED_IS_REJECTED);
  }
}

function hasAtMostSixDecimals(value: number): boolean {
  if (!Number.isFinite(value)) {
    return false;
  }
  const text = value.toString();
  const decimals = text.split('.')[1];
  return !decimals || decimals.length <= 6;
}
