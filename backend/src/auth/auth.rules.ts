import { createHash, randomInt } from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { User } from '../users/user.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import {
  FIELD_LIMITS,
  LOGIN_LOCK_MS,
  LOGIN_MAX_ATTEMPTS,
} from '../common/field-limits';

export function hashOtp(code: string): string {
  return createHash('sha256').update(code).digest('hex');
}

export function generateOtp(): string {
  return randomInt(0, 1_000_000).toString().padStart(FIELD_LIMITS.otpDigits, '0');
}

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 10);
}

export async function passwordsMatch(
  password: string,
  passwordHash: string,
): Promise<boolean> {
  return bcrypt.compare(password, passwordHash);
}

export function requiresInstitutionalEmail(role: UserRole): boolean {
  return role === UserRole.DISPATCHER || role === UserRole.FLEET_OPERATOR;
}

export function isLockActive(user: User, now = new Date()): boolean {
  return Boolean(user.lockedUntil && user.lockedUntil.getTime() > now.getTime());
}

export function nextFailedLoginState(
  user: User,
  now = new Date(),
): Pick<User, 'failedLoginCount' | 'status' | 'lockedUntil'> {
  const failedLoginCount = user.failedLoginCount + 1;
  if (failedLoginCount >= LOGIN_MAX_ATTEMPTS) {
    return {
      failedLoginCount,
      status: UserStatus.LOCKED,
      lockedUntil: new Date(now.getTime() + LOGIN_LOCK_MS),
    };
  }
  return {
    failedLoginCount,
    status: user.status,
    lockedUntil: user.lockedUntil,
  };
}

export function clearLockState(): Pick<
  User,
  'failedLoginCount' | 'lockedUntil' | 'status'
> {
  return {
    failedLoginCount: 0,
    lockedUntil: null,
    status: UserStatus.ACTIVE,
  };
}

export function isOtpExpired(expiresAt: Date, now = new Date()): boolean {
  return expiresAt.getTime() <= now.getTime();
}

export function isOtpConsumed(consumedAt: Date | null): boolean {
  return consumedAt != null;
}
