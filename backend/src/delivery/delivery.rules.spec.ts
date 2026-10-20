import {
  DEFAULT_DELIVERY_WAIT_MS,
  deliveryCodeFor,
  deliveryCodeMatches,
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

describe('deliveryCodeFor', () => {
  const order = {
    id: '11111111-1111-4111-8111-111111111111',
    loadConfirmedAt: new Date('2026-10-19T14:00:00.000Z'),
  };

  it('es de 6 dígitos y estable para el mismo pedido', () => {
    const code = deliveryCodeFor(order, 'secreto');
    expect(code).toMatch(/^\d{6}$/);
    expect(deliveryCodeFor(order, 'secreto')).toBe(code);
  });

  it('cambia con el pedido, con la confirmación de carga y con el secreto', () => {
    const code = deliveryCodeFor(order, 'secreto');
    expect(deliveryCodeFor({ ...order, id: 'otro' }, 'secreto')).not.toBe(code);
    expect(
      deliveryCodeFor(
        { ...order, loadConfirmedAt: new Date('2026-10-19T14:00:01.000Z') },
        'secreto',
      ),
    ).not.toBe(code);
    expect(deliveryCodeFor(order, 'otro-secreto')).not.toBe(code);
  });

  it('compara sin importar el largo', () => {
    expect(deliveryCodeMatches('123456', '123456')).toBe(true);
    expect(deliveryCodeMatches('123456', '123457')).toBe(false);
    expect(deliveryCodeMatches('12345', '123456')).toBe(false);
  });
});
