export const FIELD_LIMITS = {
  fullName: 40,
  email: 50,
  phone: 10,
  /** Cédula (6–10) o PPT (hasta 15). */
  documentNumber: 15,
  /** Código de lote del empaque. */
  lotCode: 20,
  passwordMax: 72,
  passwordMin: 8,
  otpDigits: 6,
  bcryptHash: 60,
  sha256Hex: 64,
  hubName: 80,
  medicationName: 80,
  geofenceName: 80,
  address: 160,
  reason: 160,
  droneIdentifier: 32,
  droneModelName: 80,
  droneModelCode: 32,
  /** Descripción breve de una urgencia civil. */
  orderDescription: 500,
  prescriptionMime: 32,
} as const;

/** Imagen de fórmula: jpeg o png, hasta 2 MiB. */
export const PRESCRIPTION_MAX_BYTES = 2 * 1024 * 1024;

/** RU-02 no pide cantidad: la urgencia civil sale con una unidad. */
export const CIVIL_EMERGENCY_QUANTITY = 1;

export const OTP_SIGNUP_TTL_MS = 10 * 60 * 1000;
export const OTP_RESET_TTL_MS = 15 * 60 * 1000;
export const LOGIN_MAX_ATTEMPTS = 5;
export const LOGIN_LOCK_MS = 15 * 60 * 1000;

/** Numeración colombiana: exactamente 10 dígitos, sin +57 ni espacios. */
export const COLOMBIA_PHONE_REGEX = /^\d{10}$/;
