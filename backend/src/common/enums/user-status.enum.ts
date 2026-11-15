export enum UserStatus {
  UNVERIFIED = 'unverified',
  ACTIVE = 'active',
  LOCKED = 'locked',
  SUSPENDED = 'suspended',
  /** RF-50: el titular revocó el consentimiento; la cuenta está inactiva. */
  REVOKED = 'revoked',
  /** RF-50: el titular pidió la supresión; la fila queda anonimizada. */
  DELETED = 'deleted',
}
