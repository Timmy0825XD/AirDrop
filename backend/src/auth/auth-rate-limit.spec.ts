import { GUARDS_METADATA } from '@nestjs/common/constants';
import { AuthController } from './auth.controller';
import { LoginRateLimitGuard } from './login-rate-limit.guard';

// @nestjs/swagger se publica como ESM y Jest (CommonJS) no lo carga. Sus
// decoradores solo documentan la API, así que aquí no hacen nada.
jest.mock('@nestjs/swagger', () => ({
  ApiTags: () => () => undefined,
  ApiBearerAuth: () => () => undefined,
}));

/**
 * H-08: `@Throttle` no hace nada sin su guard (no hay uno global). Este test
 * falla si alguien quita el límite de peticiones de un endpoint con código.
 */
describe('AuthController rate limit', () => {
  const limited = [
    'login',
    'register',
    'verifyOtp',
    'resendOtp',
    'forgotPassword',
    'resetPassword',
    'confirmEmail',
    'resendEmail',
  ];

  it.each(limited)('%s uses the rate-limit guard', (method) => {
    const handler = Object.getOwnPropertyDescriptor(
      AuthController.prototype,
      method,
    )?.value as object;
    const guards = (Reflect.getMetadata(GUARDS_METADATA, handler) ??
      []) as unknown[];
    expect(guards).toContain(LoginRateLimitGuard);
  });

  it('logout is not rate limited (it only needs the token)', () => {
    const handler = Object.getOwnPropertyDescriptor(
      AuthController.prototype,
      'logout',
    )?.value as object;
    const guards = (Reflect.getMetadata(GUARDS_METADATA, handler) ??
      []) as unknown[];
    expect(guards).not.toContain(LoginRateLimitGuard);
  });
});
