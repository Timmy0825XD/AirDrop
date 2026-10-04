import { BadRequestException } from '@nestjs/common';
import { DocumentType } from '../common/enums/document-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { User } from '../users/user.entity';
import {
  DOCUMENT_MISMATCH,
  FORMULA_NOT_FOR_TRANSFER,
  PRESCRIPTION_IMAGE_REQUIRED,
  SPECIAL_CONTROL_MESSAGE,
  assertNoPatientFormula,
  patientFormula,
} from './orders.rules';

describe('patientFormula', () => {
  const requester = {
    documentType: DocumentType.CITIZENSHIP_ID,
    documentNumber: '1098765432',
  } as User;
  const jpeg = Buffer.from('formula').toString('base64');

  it('rejects special control and a prescription without an image', () => {
    expect(() =>
      patientFormula(requester, SaleType.SPECIAL_CONTROL, {}),
    ).toThrow(new BadRequestException(SPECIAL_CONTROL_MESSAGE));
    expect(() =>
      patientFormula(requester, SaleType.PRESCRIPTION, {
        patientDocumentType: DocumentType.CITIZENSHIP_ID,
        patientDocumentNumber: '1098765432',
      }),
    ).toThrow(new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED));
  });

  it('rejects a document that is not the account document', () => {
    expect(() =>
      patientFormula(requester, SaleType.PRESCRIPTION, {
        patientDocumentType: DocumentType.CITIZENSHIP_ID,
        patientDocumentNumber: '1098765433',
        prescriptionMime: 'image/jpeg',
        prescriptionImageBase64: jpeg,
      }),
    ).toThrow(new BadRequestException(DOCUMENT_MISMATCH));
  });

  it('rejects a patient formula on a hub transfer', () => {
    expect(() =>
      assertNoPatientFormula({
        saleType: SaleType.OVER_THE_COUNTER,
        prescriptionImageBase64: jpeg,
      }),
    ).toThrow(new BadRequestException(FORMULA_NOT_FOR_TRANSFER));
  });
});
