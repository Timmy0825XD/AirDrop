import { corsOrigins } from './cors.rules';

describe('corsOrigins', () => {
  it('usa la lista configurada, sin espacios ni vacíos', () => {
    expect(
      corsOrigins(
        ' https://app.airdrop.co , https://qa.airdrop.co ,',
        'production',
      ),
    ).toEqual(['https://app.airdrop.co', 'https://qa.airdrop.co']);
  });

  it('en desarrollo acepta localhost en cualquier puerto', () => {
    const origins = corsOrigins(undefined, 'development') as RegExp;
    expect(origins.test('http://localhost:54321')).toBe(true);
    expect(origins.test('http://127.0.0.1:3000')).toBe(true);
    expect(origins.test('http://localhost.evil.com')).toBe(false);
    expect(origins.test('https://evil.com')).toBe(false);
  });

  it('en producción sin lista no acepta ningún origen', () => {
    expect(corsOrigins(undefined, 'production')).toBe(false);
    expect(corsOrigins('  ', 'production')).toBe(false);
  });
});
