import {
  DEFAULT_DELIVERY_WAIT_MS,
  deliveryWaitMs,
  isDeliveryWaitOver,
} from './delivery.rules';

describe('delivery rules', () => {
  const landedAt = new Date('2026-10-19T15:00:00.000Z');

  afterEach(() => {
    delete process.env.DELIVERY_WAIT_MS;
  });

  it('la espera es de 5 minutos por defecto', () => {
    expect(deliveryWaitMs()).toBe(DEFAULT_DELIVERY_WAIT_MS);
    expect(isDeliveryWaitOver(landedAt, new Date('2026-10-19T15:04:59Z'))).toBe(
      false,
    );
    expect(isDeliveryWaitOver(landedAt, new Date('2026-10-19T15:05:00Z'))).toBe(
      true,
    );
  });

  it('DELIVERY_WAIT_MS acorta la espera para las pruebas', () => {
    process.env.DELIVERY_WAIT_MS = '10000';
    expect(isDeliveryWaitOver(landedAt, new Date('2026-10-19T15:00:09Z'))).toBe(
      false,
    );
    expect(isDeliveryWaitOver(landedAt, new Date('2026-10-19T15:00:10Z'))).toBe(
      true,
    );
  });
});
