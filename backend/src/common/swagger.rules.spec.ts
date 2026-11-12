import { swaggerEnabled } from './swagger.rules';

describe('swaggerEnabled (H-07)', () => {
  it('no publica Swagger en producción', () => {
    expect(swaggerEnabled('production')).toBe(false);
  });

  it('lo publica en desarrollo, en pruebas y sin NODE_ENV', () => {
    expect(swaggerEnabled('development')).toBe(true);
    expect(swaggerEnabled('test')).toBe(true);
    expect(swaggerEnabled(undefined)).toBe(true);
  });
});
