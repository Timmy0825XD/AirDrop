/** RF-42: quién es el paciente a cargo para el titular. */
export enum PatientRelation {
  CHILD = 'child',
  PARENT = 'parent',
  PARTNER = 'partner',
  RELATIVE = 'relative',
  DEPENDENT = 'dependent',
}

/**
 * RF-42: el documento del paciente. Suma los de menores (registro civil y
 * tarjeta de identidad) a los de una cuenta, que es siempre de adulto.
 */
export enum PatientDocumentType {
  CIVIL_REGISTRY = 'civil_registry',
  IDENTITY_CARD = 'identity_card',
  CITIZENSHIP_ID = 'citizenship_id',
  FOREIGNER_ID = 'foreigner_id',
  PPT = 'ppt',
}
