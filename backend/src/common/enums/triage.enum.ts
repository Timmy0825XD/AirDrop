/** RF-41: signos de alarma. Con uno, la app ofrece el 123 y la urgencia va primero. */
export enum RedFlag {
  BREATHING_DIFFICULTY = 'breathing_difficulty',
  CHEST_PAIN = 'chest_pain',
  SEIZURE = 'seizure',
  UNCONTROLLED_BLEEDING = 'uncontrolled_bleeding',
  FAINTING = 'fainting',
  SEVERE_ALLERGY = 'severe_allergy',
}

/** RF-41: la edad del paciente, en grupos. */
export enum PatientGroup {
  BABY = 'baby',
  CHILD = 'child',
  ADULT = 'adult',
  OLDER_ADULT = 'older_adult',
}

/** RF-41: qué siente el paciente. */
export enum Symptom {
  FEVER = 'fever',
  PAIN = 'pain',
  BREATHING = 'breathing',
  ALLERGY = 'allergy',
  BLOOD_SUGAR = 'blood_sugar',
  BLOOD_PRESSURE = 'blood_pressure',
  INFECTION = 'infection',
  STOMACH = 'stomach',
  OTHER = 'other',
}

/** RF-41: desde cuándo. */
export enum SymptomOnset {
  HOURS = 'hours',
  TODAY = 'today',
  DAYS = 'days',
}

/** RF-41: qué tan fuerte. */
export enum SymptomSeverity {
  MILD = 'mild',
  MODERATE = 'moderate',
  SEVERE = 'severe',
}
