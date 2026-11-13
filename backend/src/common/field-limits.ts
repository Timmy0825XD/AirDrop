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
  /** RF-42: nombre completo del paciente a cargo. */
  patientFullName: 80,
  /** RF-41: alergias a medicamentos, en pocas palabras. */
  allergies: 200,
  /** `{uuid}.jpg`, `{uuid}-2.png` o `{uuid}.pdf` dentro del bucket. */
  prescriptionObjectKey: 48,
} as const;

/** Bucket privado de Supabase Storage. Sin políticas públicas. */
export const PRESCRIPTION_BUCKET = 'prescriptions';

/** Cada archivo de la fórmula (PDF, JPEG o PNG): hasta 5 MiB (RU-25). */
export const PRESCRIPTION_MAX_BYTES = 5 * 1024 * 1024;

/** Una fórmula de papel puede tener varias hojas: hasta 3 fotos (RU-25). */
export const PRESCRIPTION_MAX_IMAGES = 3;

/** RU-02 no pide cantidad: la urgencia civil sale con una unidad. */
export const CIVIL_EMERGENCY_QUANTITY = 1;

export const OTP_SIGNUP_TTL_MS = 10 * 60 * 1000;
export const OTP_RESET_TTL_MS = 15 * 60 * 1000;
export const LOGIN_MAX_ATTEMPTS = 5;
export const LOGIN_LOCK_MS = 15 * 60 * 1000;
/** Errores permitidos con un mismo código OTP antes de anularlo (H-08). */
export const OTP_MAX_ATTEMPTS = 5;

/** Numeración colombiana: exactamente 10 dígitos, sin +57 ni espacios. */
export const COLOMBIA_PHONE_REGEX = /^\d{10}$/;
