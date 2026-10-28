import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { DocumentType } from './common/enums/document-type.enum';
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
  normalizeDocumentNumber,
  requiresInstitutionalEmail,
  clearLockState,
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

  it('keeps suspended status when clearing a lock', () => {
    const next = clearLockState(UserStatus.SUSPENDED);
    expect(next.status).toBe(UserStatus.SUSPENDED);
    expect(next.failedLoginCount).toBe(0);
    expect(next.lockedUntil).toBeNull();
  });

  it('allows only the requester on public register', () => {
    expect(PUBLIC_REGISTER_ROLES).toEqual([UserRole.REQUESTER]);
    expect(isPublicRegisterRole(UserRole.REQUESTER)).toBe(true);
    expect(isPublicRegisterRole(UserRole.DISPATCHER)).toBe(false);
    expect(isPublicRegisterRole(UserRole.ADMIN)).toBe(false);
    expect(isPublicRegisterRole('recipient')).toBe(false);
  });

  it('accepts citizenship, foreigner id and PPT numbers', () => {
    expect(
      normalizeDocumentNumber(DocumentType.CITIZENSHIP_ID, '1065487321'),
    ).toBe('1065487321');
    expect(normalizeDocumentNumber(DocumentType.FOREIGNER_ID, '384921')).toBe(
      '384921',
    );
    expect(normalizeDocumentNumber(DocumentType.PPT, 'ppt26a18421')).toBe(
      'PPT26A18421',
    );
    expect(
      normalizeDocumentNumber(DocumentType.CITIZENSHIP_ID, '12345'),
    ).toBeNull();
  });
});

const requester = {
  fullName: 'Ana Pérez',
  email: 'ana.perez@gmail.com',
  phone: '3001112233',
  documentType: DocumentType.CITIZENSHIP_ID,
  documentNumber: '1065487321',
  password: 'Password123',
  consentAccepted: true,
};

describe('RegisterDto lengths', () => {
  it('rejects email longer than 50', async () => {
    const dto = plainToInstance(RegisterDto, {
      ...requester,
      email: `${'a'.repeat(42)}@gmail.com`,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'email')).toBe(true);
  });

  it('rejects a name longer than 40', async () => {
    const dto = plainToInstance(RegisterDto, {
      ...requester,
      fullName: 'N'.repeat(41),
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'fullName')).toBe(true);
  });

  it('rejects a phone that is not 10 digits', async () => {
    const dto = plainToInstance(RegisterDto, {
      ...requester,
      phone: '300123456',
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'phone')).toBe(true);
  });

  it('accepts a realistic Colombian payload', async () => {
    const dto = plainToInstance(RegisterDto, requester);
    const errors = await validate(dto);
    expect(errors).toHaveLength(0);
  });

  it('rejects a document type outside citizenship, foreigner id and PPT', async () => {
    const dto = plainToInstance(RegisterDto, {
      ...requester,
      documentType: 'identity_card',
    });
    const errors = await validate(dto);
    expect(errors.some((error) => error.property === 'documentType')).toBe(
      true,
    );
  });
});
