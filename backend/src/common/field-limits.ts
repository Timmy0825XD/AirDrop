export const FIELD_LIMITS = {
  fullName: 40,
  email: 50,
  phone: 10,
  passwordMax: 72,
  passwordMin: 8,
  otpDigits: 6,
  bcryptHash: 60,
  sha256Hex: 64,
} as const;

export const OTP_SIGNUP_TTL_MS = 10 * 60 * 1000;
export const OTP_RESET_TTL_MS = 15 * 60 * 1000;
export const LOGIN_MAX_ATTEMPTS = 5;
export const LOGIN_LOCK_MS = 15 * 60 * 1000;

/** Numeración colombiana: exactamente 10 dígitos, sin +57 ni espacios. */
export const COLOMBIA_PHONE_REGEX = /^\d{10}$/;
