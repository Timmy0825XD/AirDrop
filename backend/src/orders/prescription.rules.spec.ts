import { BadRequestException } from '@nestjs/common';
import {
  decodePrescriptionFiles,
  matchesSignature,
  PDF_MIME,
  PRESCRIPTION_CORRUPT,
  PRESCRIPTION_FILES_RULE,
  PRESCRIPTION_IMAGE_REQUIRED,
  PRESCRIPTION_SIZE,
  PRESCRIPTION_TYPE,
  prescriptionFilename,
  rawPrescriptionFiles,
} from './prescription.rules';

const MB = 1024 * 1024;
const JPEG = [0xff, 0xd8, 0xff];
const PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const PDF = [...Buffer.from('%PDF-1.7')];

function file(mime: string, signature: number[], size = 64) {
  const content = Buffer.alloc(size, 7);
  content.set(signature);
  return { mime, base64: content.toString('base64') };
}

const jpeg = () => file('image/jpeg', JPEG);
const png = () => file('image/png', PNG);
const pdf = () => file(PDF_MIME, PDF);

describe('fórmula en PDF o hasta 3 fotos (RU-25)', () => {
  it('acepta un PDF solo', () => {
    const [only] = decodePrescriptionFiles([pdf()]);
    expect(only.mime).toBe(PDF_MIME);
    expect(only.content.subarray(0, 5).toString()).toBe('%PDF-');
  });

  it('acepta de 1 a 3 fotos, mezclando JPG y PNG', () => {
    expect(decodePrescriptionFiles([jpeg(), png(), jpeg()])).toHaveLength(3);
  });

  it('no acepta 4 fotos ni un PDF con fotos', () => {
    const rule = new BadRequestException(PRESCRIPTION_FILES_RULE);
    expect(() =>
      decodePrescriptionFiles([jpeg(), jpeg(), jpeg(), jpeg()]),
    ).toThrow(rule);
    expect(() => decodePrescriptionFiles([pdf(), jpeg()])).toThrow(rule);
    expect(() => decodePrescriptionFiles([pdf(), pdf()])).toThrow(rule);
  });

  it('sin archivos pide la fórmula', () => {
    expect(() => decodePrescriptionFiles([])).toThrow(
      new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED),
    );
  });

  it('rechaza un tipo que no es PDF, JPG ni PNG', () => {
    expect(() =>
      decodePrescriptionFiles([file('image/gif', [0x47, 0x49, 0x46])]),
    ).toThrow(new BadRequestException(PRESCRIPTION_TYPE));
  });

  it('rechaza un archivo que dice ser PDF y no lo es', () => {
    expect(() => decodePrescriptionFiles([file(PDF_MIME, JPEG)])).toThrow(
      new BadRequestException(PRESCRIPTION_CORRUPT),
    );
  });

  it('acepta 5 MB y rechaza 5 MB + 1 byte', () => {
    expect(
      decodePrescriptionFiles([file('image/jpeg', JPEG, 5 * MB)]),
    ).toHaveLength(1);
    expect(() =>
      decodePrescriptionFiles([file('image/jpeg', JPEG, 5 * MB + 1)]),
    ).toThrow(new BadRequestException(PRESCRIPTION_SIZE));
  });

  it('la lista nueva manda sobre el archivo único de la app anterior', () => {
    expect(
      rawPrescriptionFiles({
        prescriptions: [pdf()],
        prescriptionMime: 'image/jpeg',
        prescriptionImageBase64: 'AQID',
      }),
    ).toEqual([pdf()]);
    expect(
      rawPrescriptionFiles({
        prescriptionMime: 'image/png',
        prescriptionImageBase64: 'AQID',
      }),
    ).toEqual([{ mime: 'image/png', base64: 'AQID' }]);
    expect(rawPrescriptionFiles({})).toEqual([]);
  });

  it('reconoce cada tipo por sus primeros bytes', () => {
    expect(matchesSignature('image/png', Buffer.from(PNG))).toBe(true);
    expect(matchesSignature('image/png', Buffer.from(JPEG))).toBe(false);
    expect(matchesSignature(PDF_MIME, Buffer.from('%PD'))).toBe(false);
  });

  it('nombra el archivo para abrirlo con otra app', () => {
    expect(
      prescriptionFilename('1a2b3c4d-0000-4000-8000-000000000000', 1, PDF_MIME),
    ).toBe('formula-1a2b3c4d-2.pdf');
  });
});
