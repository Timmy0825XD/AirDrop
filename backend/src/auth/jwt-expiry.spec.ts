import {
  DEFAULT_JWT_EXPIRES_IN_SECONDS,
  JWT_EXPIRES_IN_INVALID,
  jwtExpiresInSeconds,
} from './auth.rules';

describe('jwtExpiresInSeconds (JWT_EXPIRES_IN)', () => {
  it('sin variable, o vacía, son 8 horas', () => {
    expect(jwtExpiresInSeconds(undefined)).toBe(DEFAULT_JWT_EXPIRES_IN_SECONDS);
    expect(jwtExpiresInSeconds('  ')).toBe(8 * 60 * 60);
  });

  it('lee horas, minutos, días y segundos', () => {
    expect(jwtExpiresInSeconds('2h')).toBe(2 * 60 * 60);
    expect(jwtExpiresInSeconds('30m')).toBe(30 * 60);
    expect(jwtExpiresInSeconds('1d')).toBe(24 * 60 * 60);
    expect(jwtExpiresInSeconds('45s')).toBe(45);
    expect(jwtExpiresInSeconds('28800')).toBe(28800);
    expect(jwtExpiresInSeconds(' 8H ')).toBe(8 * 60 * 60);
  });

  it('un valor mal escrito detiene el arranque', () => {
    for (const raw of ['ocho horas', '8 semanas', '0', '-2h', '1.5h']) {
      expect(() => jwtExpiresInSeconds(raw)).toThrow(JWT_EXPIRES_IN_INVALID);
    }
  });
});
