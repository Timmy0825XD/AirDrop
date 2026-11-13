import { BadRequestException } from '@nestjs/common';
import {
  PRESCRIPTION_MAX_BYTES,
  PRESCRIPTION_MAX_IMAGES,
} from '../common/field-limits';

export const PDF_MIME = 'application/pdf';

/** Lo que se acepta de la fórmula (RU-25, RF-27). */
export const PRESCRIPTION_MIMES = ['image/jpeg', 'image/png', PDF_MIME];

export const PRESCRIPTION_IMAGE_REQUIRED =
  'La venta bajo fórmula exige la fórmula: un PDF o de 1 a 3 fotos.';

export const PRESCRIPTION_FILES_RULE =
  'La fórmula va en un solo PDF o en 1 a 3 fotos, sin mezclarlos.';

export const PRESCRIPTION_TYPE =
  'La fórmula debe ser un PDF o una foto JPG o PNG.';

export const PRESCRIPTION_SIZE =
  'Cada archivo de la fórmula debe pesar hasta 5 MB.';

export const PRESCRIPTION_CORRUPT = 'El archivo de la fórmula no es válido.';

/** Un archivo de la fórmula ya decodificado. */
export interface PrescriptionFile {
  content: Buffer;
  mime: string;
}

/** Un archivo como llega en el cuerpo: tipo y base64. */
export interface RawPrescriptionFile {
  mime: string;
  base64: string;
}

/**
 * Los archivos que trae el pedido: la lista nueva `prescriptions`, o el
 * archivo único de la app anterior (`prescriptionMime` y
 * `prescriptionImageBase64`).
 */
export function rawPrescriptionFiles(input: {
  prescriptions?: RawPrescriptionFile[];
  prescriptionMime?: string;
  prescriptionImageBase64?: string;
}): RawPrescriptionFile[] {
  if (input.prescriptions?.length) {
    return input.prescriptions;
  }
  if (input.prescriptionImageBase64) {
    return [
      {
        mime: input.prescriptionMime ?? '',
        base64: input.prescriptionImageBase64,
      },
    ];
  }
  return [];
}

/**
 * Decodifica y revisa la fórmula: un PDF solo, o de 1 a 3 fotos. Cada
 * archivo pesa hasta 5 MB y su contenido debe ser del tipo que dice; el
 * tipo declarado no basta.
 */
export function decodePrescriptionFiles(
  raw: RawPrescriptionFile[],
): PrescriptionFile[] {
  if (raw.length === 0) {
    throw new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED);
  }
  const pdfs = raw.filter((file) => file.mime === PDF_MIME).length;
  if (raw.length > PRESCRIPTION_MAX_IMAGES || (pdfs > 0 && raw.length > 1)) {
    throw new BadRequestException(PRESCRIPTION_FILES_RULE);
  }
  return raw.map((file) => ({
    mime: file.mime,
    content: decodePrescription(file.mime, file.base64),
  }));
}

export function decodePrescription(mime: string, base64: string): Buffer {
  if (!PRESCRIPTION_MIMES.includes(mime)) {
    throw new BadRequestException(PRESCRIPTION_TYPE);
  }
  const payload = base64.includes(',')
    ? base64.slice(base64.indexOf(',') + 1)
    : base64;
  const cleaned = payload.replace(/\s/g, '');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(cleaned)) {
    throw new BadRequestException(PRESCRIPTION_CORRUPT);
  }
  const content = Buffer.from(cleaned, 'base64');
  if (content.length === 0 || content.length > PRESCRIPTION_MAX_BYTES) {
    throw new BadRequestException(PRESCRIPTION_SIZE);
  }
  if (!matchesSignature(mime, content)) {
    throw new BadRequestException(PRESCRIPTION_CORRUPT);
  }
  return content;
}

const SIGNATURES: Record<string, number[]> = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  // "%PDF-"
  [PDF_MIME]: [0x25, 0x50, 0x44, 0x46, 0x2d],
};

/** Los primeros bytes del archivo dicen qué es, no la extensión. */
export function matchesSignature(mime: string, content: Buffer): boolean {
  const signature = SIGNATURES[mime];
  return (
    signature != null &&
    content.length >= signature.length &&
    signature.every((byte, index) => content[index] === byte)
  );
}

/** La extensión del archivo guardado y descargado. */
export function prescriptionExtension(mime: string): string {
  if (mime === PDF_MIME) {
    return 'pdf';
  }
  return mime === 'image/png' ? 'png' : 'jpg';
}

/** El nombre con el que se abre en otra app: `formula-1a2b3c4d-2.jpg`. */
export function prescriptionFilename(
  orderId: string,
  position: number,
  mime: string,
): string {
  return `formula-${orderId.slice(0, 8)}-${position + 1}.${prescriptionExtension(mime)}`;
}
