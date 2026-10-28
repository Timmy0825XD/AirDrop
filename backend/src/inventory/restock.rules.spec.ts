import { QuarantineReason } from '../common/enums/quarantine-reason.enum';
import {
  RECEIPT_COLD_CHAIN,
  RECEIPT_REMISSION_MISMATCH,
  RECEIPT_SEAL_BROKEN,
  quarantineReasonFor,
  receiptRejection,
} from './restock.rules';

describe('quarantineReasonFor (cuarentena de productos.md)', () => {
  it('sin alerta de frío y con el empaque íntegro, reingresa', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: false,
        packagingIntact: true,
        receiptSealIntact: null,
      }),
    ).toBeNull();
  });

  it('con alerta de frío no reingresa aunque el empaque esté bien', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: true,
        packagingIntact: true,
        receiptSealIntact: null,
      }),
    ).toBe(QuarantineReason.COLD_CHAIN);
  });

  it('con el empaque comprometido no reingresa', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: false,
        packagingIntact: false,
        receiptSealIntact: null,
      }),
    ).toBe(QuarantineReason.PACKAGING);
  });

  it('con frío y empaque malo, el motivo es el frío', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: true,
        packagingIntact: false,
        receiptSealIntact: null,
      }),
    ).toBe(QuarantineReason.COLD_CHAIN);
  });

  it('un sello que llegó roto a destino va a cuarentena aunque el despachador no lo marque', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: false,
        packagingIntact: true,
        receiptSealIntact: false,
      }),
    ).toBe(QuarantineReason.PACKAGING);
  });

  it('una remisión que no coincidió, con sello y frío bien, puede reingresar', () => {
    expect(
      quarantineReasonFor({
        coldChainAlert: false,
        packagingIntact: true,
        receiptSealIntact: true,
      }),
    ).toBeNull();
  });
});

describe('receiptRejection (centrales.md, paso 6)', () => {
  it('todo en orden: se recibe', () => {
    expect(
      receiptRejection({
        coldChainAlert: false,
        remissionMatches: true,
        sealIntact: true,
      }),
    ).toBeNull();
  });

  it('frío, sello y remisión, en ese orden de prioridad', () => {
    expect(
      receiptRejection({
        coldChainAlert: true,
        remissionMatches: false,
        sealIntact: false,
      }),
    ).toBe(RECEIPT_COLD_CHAIN);
    expect(
      receiptRejection({
        coldChainAlert: false,
        remissionMatches: false,
        sealIntact: false,
      }),
    ).toBe(RECEIPT_SEAL_BROKEN);
    expect(
      receiptRejection({
        coldChainAlert: false,
        remissionMatches: false,
        sealIntact: true,
      }),
    ).toBe(RECEIPT_REMISSION_MISMATCH);
  });
});
