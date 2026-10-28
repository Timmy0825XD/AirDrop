import { createHash, randomInt } from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { DocumentType } from '../common/enums/document-type.enum';
import { User } from '../users/user.entity';
import {
  INSTITUTIONAL_ROLES,
  PUBLIC_REGISTER_ROLES,
  UserRole,
} from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import {
  FIELD_LIMITS,
  LOGIN_LOCK_MS,
  LOGIN_MAX_ATTEMPTS,
} from '../common/field-limits';

/** Sin `JWT_EXPIRES_IN`, la sesión dura 8 horas: una jornada de turno. */
export const DEFAULT_JWT_EXPIRES_IN_SECONDS = 8 * 60 * 60;

export const JWT_EXPIRES_IN_INVALID =
  'JWT_EXPIRES_IN debe ser un número de segundos o un valor como 8h, 30m o 1d.';

const DURATION_SECONDS: Record<string, number> = {
  s: 1,
  m: 60,
  h: 60 * 60,
  d: 24 * 60 * 60,
};

/**
 * Vencimiento del token en segundos. Acepta `28800` o `8h`, `30m`, `1d`.
 * Un valor mal escrito detiene el arranque en vez de dejar sesiones sin
 * vencer o con una duración inesperada.
 */
export function jwtExpiresInSeconds(raw: string | undefined): number {
  const value = raw?.trim();
  if (!value) {
    return DEFAULT_JWT_EXPIRES_IN_SECONDS;
  }
  const match = /^(\d+)\s*([smhd])?$/i.exec(value);
  const amount = match ? Number(match[1]) : NaN;
  if (!match || !Number.isSafeInteger(amount) || amount <= 0) {
    throw new Error(JWT_EXPIRES_IN_INVALID);
  }
  return amount * DURATION_SECONDS[(match[2] ?? 's').toLowerCase()];
}

export function hashOtp(code: string): string {
  return createHash('sha256').update(code).digest('hex');
}

export function generateOtp(): string {
  return randomInt(0, 1_000_000)
    .toString()
    .padStart(FIELD_LIMITS.otpDigits, '0');
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
  return INSTITUTIONAL_ROLES.includes(role);
}

export function isPublicRegisterRole(role: string): boolean {
  return (PUBLIC_REGISTER_ROLES as string[]).includes(role);
}

const DOCUMENT_PATTERNS: Record<DocumentType, RegExp> = {
  [DocumentType.CITIZENSHIP_ID]: /^\d{6,10}$/,
  [DocumentType.FOREIGNER_ID]: /^\d{6,10}$/,
  [DocumentType.PPT]: /^[A-Z0-9]{6,15}$/,
};

export function normalizeDocumentNumber(
  type: DocumentType,
  raw: string,
): string | null {
  const value = raw.trim().toUpperCase();
  if (!DOCUMENT_PATTERNS[type]?.test(value)) {
    return null;
  }
  return value;
}

export function isLockActive(user: User, now = new Date()): boolean {
  return Boolean(
    user.lockedUntil && user.lockedUntil.getTime() > now.getTime(),
  );
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

export function clearLockState(
  status: UserStatus,
): Pick<User, 'failedLoginCount' | 'lockedUntil' | 'status'> {
  return {
    failedLoginCount: 0,
    lockedUntil: null,
    status: status === UserStatus.LOCKED ? UserStatus.ACTIVE : status,
  };
}

export function isOtpExpired(expiresAt: Date, now = new Date()): boolean {
  return expiresAt.getTime() <= now.getTime();
}

export function isOtpConsumed(consumedAt: Date | null): boolean {
  return consumedAt != null;
}
