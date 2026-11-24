import {
  COLD_RANGE,
  manifestCold,
  manifestItems,
  manifestNumber,
  manifestYear,
} from './manifest.rules';

const order = {
  medicationName: 'Insulina glargina 100 UI',
  quantity: 2,
  dispatchedLot: 'L-2026-11',
  dispatchedLotExpiresOn: '2027-03-01',
  payloadKg: 0.12,
  requiresColdChain: true,
};

describe('Manifiesto de carga (RF-47)', () => {
  it('numera por año con seis cifras', () => {
    expect(manifestNumber(2026, 123)).toBe('MAN-2026-000123');
    expect(manifestNumber(2027, 1)).toBe('MAN-2027-000001');
  });

  it('el año es el de Colombia, no el de UTC', () => {
    // 31 de diciembre a las 21:00 en Bogotá ya es 1 de enero en UTC.
    expect(manifestYear(new Date('2027-01-01T02:00:00.000Z'))).toBe(2026);
  });

  it('describe la carga por ítem y no lleva datos del paciente', () => {
    const items = manifestItems(order);
    expect(items).toEqual([
      {
        medicationName: 'Insulina glargina 100 UI',
        lot: 'L-2026-11',
        expiresOn: '2027-03-01',
        quantity: 2,
      },
    ]);
    expect(JSON.stringify(items)).not.toMatch(/patient|document/i);
  });

  it('el frío: el compartimento pesa 1 kg y la carga fría exige 2–8 °C', () => {
    expect(manifestCold(order, true)).toEqual({
      coldCompartmentKg: 1,
      coldRange: COLD_RANGE,
    });
    expect(manifestCold({ ...order, requiresColdChain: false }, false)).toEqual(
      { coldCompartmentKg: null, coldRange: null },
    );
  });
});
