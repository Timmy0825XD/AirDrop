import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { PUBLIC_REGISTER_ROLES, UserRole } from './common/enums/user-role.enum';
import { UserStatus } from './common/enums/user-status.enum';
import {
  FIELD_LIMITS,
  LOGIN_MAX_ATTEMPTS,
} from './common/field-limits';
import {
  hashOtp,
  isLockActive,
  isOtpConsumed,
  isOtpExpired,
  isPublicRegisterRole,
  nextFailedLoginState,
  requiresInstitutionalEmail,
} from './auth/auth.rules';
import { RegisterDto } from './auth/dto/register.dto';
import { User } from './users/user.entity';

describe('auth.rules', () => {
  it('hashes OTP to 64 hex chars', () => {
    const digest = hashOtp('123456');
    expect(digest).toHaveLength(FIELD_LIMITS.sha256Hex);
    expect(digest).toMatch(/^[a-f0-9]{64}$/);
  });

  it('rejects expired and reused OTP', () => {
    expect(isOtpExpired(new Date(Date.now() - 1000))).toBe(true);
    expect(isOtpExpired(new Date(Date.now() + 60_000))).toBe(false);
    expect(isOtpConsumed(new Date())).toBe(true);
    expect(isOtpConsumed(null)).toBe(false);
  });

  it('locks after five failed logins', () => {
    const user = {
      failedLoginCount: LOGIN_MAX_ATTEMPTS - 1,
      status: UserStatus.ACTIVE,
      lockedUntil: null,
    } as User;
    const next = nextFailedLoginState(user, new Date('2026-09-03T12:00:00Z'));
    expect(next.status).toBe(UserStatus.LOCKED);
    expect(next.failedLoginCount).toBe(LOGIN_MAX_ATTEMPTS);
    expect(isLockActive({ ...user, ...next } as User, new Date('2026-09-03T12:01:00Z'))).toBe(
      true,
    );
  });

  it('requires email for dispatcher and fleet operator', () => {
    expect(requiresInstitutionalEmail(UserRole.DISPATCHER)).toBe(true);
    expect(requiresInstitutionalEmail(UserRole.FLEET_OPERATOR)).toBe(true);
    expect(requiresInstitutionalEmail(UserRole.REQUESTER)).toBe(false);
    expect(requiresInstitutionalEmail(UserRole.ADMIN)).toBe(false);
  });

  it('allows only three public register roles', () => {
    expect(PUBLIC_REGISTER_ROLES).toEqual([
      UserRole.REQUESTER,
      UserRole.DISPATCHER,
      UserRole.FLEET_OPERATOR,
    ]);
    expect(isPublicRegisterRole(UserRole.REQUESTER)).toBe(true);
    expect(isPublicRegisterRole(UserRole.ADMIN)).toBe(false);
    expect(isPublicRegisterRole('recipient')).toBe(false);
  });
});

describe('RegisterDto lengths', () => {
  it('rejects email longer than 50', async () => {
    const dto = plainToInstance(RegisterDto, {
      fullName: 'Ana Pérez',
      email: `${'a'.repeat(45)}@mail.com`,
      password: 'secreto12',
      role: UserRole.REQUESTER,
      consentAccepted: true,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'email')).toBe(true);
  });

  it('rejects a name longer than 40', async () => {
    const dto = plainToInstance(RegisterDto, {
      fullName: 'N'.repeat(41),
      email: 'ana@correo.co',
      password: 'secreto12',
      role: UserRole.REQUESTER,
      consentAccepted: true,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'fullName')).toBe(true);
  });

  it('rejects a phone that is not 10 digits', async () => {
    const dto = plainToInstance(RegisterDto, {
      fullName: 'Ana Pérez',
      phone: '300123456',
      password: 'secreto12',
      role: UserRole.REQUESTER,
      consentAccepted: true,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'phone')).toBe(true);
  });

  it('accepts a realistic Colombian payload', async () => {
    const dto = plainToInstance(RegisterDto, {
      fullName: 'Ana Pérez',
      email: 'ana@correo.co',
      phone: '3001234567',
      password: 'secreto12',
      role: UserRole.REQUESTER,
      consentAccepted: true,
    });
    const errors = await validate(dto);
    expect(errors).toHaveLength(0);
  });

  it('rejects admin and retired recipient on public register', async () => {
    const admin = plainToInstance(RegisterDto, {
      fullName: 'Ana Pérez',
      email: 'ana@correo.co',
      password: 'secreto12',
      role: UserRole.ADMIN,
      consentAccepted: true,
    });
    const recipient = plainToInstance(RegisterDto, {
      fullName: 'Ana Pérez',
      email: 'ana@correo.co',
      password: 'secreto12',
      role: 'recipient',
      consentAccepted: true,
    });
    expect(
      (await validate(admin)).some((error) => error.property === 'role'),
    ).toBe(true);
    expect(
      (await validate(recipient)).some((error) => error.property === 'role'),
    ).toBe(true);
  });
});
