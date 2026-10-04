import { BadRequestException } from '@nestjs/common';
import { normalizeDocumentNumber } from '../auth/auth.rules';
import { DocumentType } from '../common/enums/document-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
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

export const START_DATE_IN_THE_PAST =
  'La fecha de inicio no puede ser anterior a hoy.';

export const ONCE_IS_NOT_EXTENDED = 'La frecuencia única no se extiende.';

export const PLAN_NOT_READY_TO_EXTEND =
  'El plan todavía no está en la última semana.';

export const PLAN_ALREADY_CANCELLED = 'El plan ya está cancelado.';

export const PLAN_CANCELLED_REASON = 'El plan fue cancelado.';

/** Ocho semanas. El día `windowEndsOn` ya es la ventana siguiente. */
export const PLAN_WINDOW_DAYS = 56;

export const PLAN_RENEWAL_NOTICE_DAYS = 7;

/** RU-15: la urgencia en recibido avisa al pasar de 5 minutos. */
export const UNATTENDED_EMERGENCY_MS = 5 * 60 * 1000;

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

export function addCalendarDays(isoDate: string, days: number): string {
  const [year, month, day] = isoDate.split('-').map(Number);
  const utc = new Date(Date.UTC(year, month - 1, day));
  utc.setUTCDate(utc.getUTCDate() + days);
  return utc.toISOString().slice(0, 10);
}

function addCalendarMonths(isoDate: string, months: number): string {
  const [year, month, day] = isoDate.split('-').map(Number);
  const monthIndex = month - 1 + months;
  const targetYear = year + Math.floor(monthIndex / 12);
  const targetMonth = ((monthIndex % 12) + 12) % 12;
  const lastDay = new Date(
    Date.UTC(targetYear, targetMonth + 1, 0),
  ).getUTCDate();
  const targetDay = Math.min(day, lastDay);
  const monthText = String(targetMonth + 1).padStart(2, '0');
  const dayText = String(targetDay).padStart(2, '0');
  return `${targetYear}-${monthText}-${dayText}`;
}

export function assertStartDate(
  startDate: string,
  today = todayInColombia(),
): void {
  if (startDate < today) {
    throw new BadRequestException(START_DATE_IN_THE_PAST);
  }
}

export function windowEnd(startDate: string): string {
  return addCalendarDays(startDate, PLAN_WINDOW_DAYS);
}

/** Una ocurrencia por periodo, sin incluir el día en que abre la ventana siguiente. */
export function occurrenceDates(
  startDate: string,
  untilExclusive: string,
  frequency: PlanFrequency,
): string[] {
  if (frequency === PlanFrequency.ONCE) {
    return [startDate];
  }
  const dates: string[] = [];
  for (let index = 0; index < 24; index += 1) {
    const cursor =
      frequency === PlanFrequency.WEEKLY
        ? addCalendarDays(startDate, 7 * index)
        : frequency === PlanFrequency.BIWEEKLY
          ? addCalendarDays(startDate, 14 * index)
          : addCalendarMonths(startDate, index);
    if (cursor >= untilExclusive) {
      break;
    }
    dates.push(cursor);
  }
  return dates;
}

export function renewalDue(
  plan: {
    status: PlanStatus;
    frequency: PlanFrequency;
    windowEndsOn: string;
  },
  today: string,
): boolean {
  if (
    plan.status !== PlanStatus.ACTIVE ||
    plan.frequency === PlanFrequency.ONCE
  ) {
    return false;
  }
  return today >= addCalendarDays(plan.windowEndsOn, -PLAN_RENEWAL_NOTICE_DAYS);
}

export function datesForExtension(
  startDate: string,
  windowEndsOn: string,
  frequency: PlanFrequency,
  today: string,
): { windowEndsOn: string; dates: string[] } {
  const nextEnd = addCalendarDays(windowEndsOn, PLAN_WINDOW_DAYS);
  const dates = occurrenceDates(startDate, nextEnd, frequency).filter(
    (date) => date >= windowEndsOn && date >= today,
  );
  return { windowEndsOn: nextEnd, dates };
}

/** Se calcula al abrir la cola. No cambia el estado ni autoriza. */
export function isUnattendedEmergency(
  createdAt: Date,
  now = new Date(),
): boolean {
  return now.getTime() - createdAt.getTime() > UNATTENDED_EMERGENCY_MS;
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
