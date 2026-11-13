/// El tamizaje de la urgencia (RF-41) y el paciente a cargo (RF-42), con los
/// mismos valores que Nest (§19.1) y su texto en español.
library;

/// Un signo de alarma: con uno, la app ofrece el 123 y la urgencia va
/// primero en la cola.
enum RedFlag {
  breathingDifficulty('breathing_difficulty', 'Le cuesta respirar'),
  chestPain('chest_pain', 'Dolor en el pecho'),
  seizure('seizure', 'Convulsión'),
  uncontrolledBleeding('uncontrolled_bleeding', 'Sangrado que no para'),
  fainting('fainting', 'Desmayo'),
  severeAllergy('severe_allergy', 'Alergia grave');

  const RedFlag(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum PatientGroup {
  baby('baby', 'Bebé'),
  child('child', 'Niño'),
  adult('adult', 'Adulto'),
  olderAdult('older_adult', 'Adulto mayor');

  const PatientGroup(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// Se pregunta por embarazo solo donde puede haberlo.
  bool get mayBePregnant => this == child || this == adult;
}

enum Symptom {
  fever('fever', 'Fiebre'),
  pain('pain', 'Dolor'),
  breathing('breathing', 'Respiración'),
  allergy('allergy', 'Alergia'),
  bloodSugar('blood_sugar', 'Azúcar'),
  bloodPressure('blood_pressure', 'Presión'),
  infection('infection', 'Infección'),
  stomach('stomach', 'Estómago'),
  other('other', 'Otro');

  const Symptom(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum SymptomOnset {
  hours('hours', 'Hace unas horas'),
  today('today', 'Desde hoy'),
  days('days', 'Hace varios días');

  const SymptomOnset(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum SymptomSeverity {
  mild('mild', 'Leve'),
  moderate('moderate', 'Moderado'),
  severe('severe', 'Fuerte');

  const SymptomSeverity(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum PatientRelation {
  child('child', 'Hijo o hija'),
  parent('parent', 'Mamá o papá'),
  partner('partner', 'Pareja'),
  relative('relative', 'Otro familiar'),
  dependent('dependent', 'Alguien que cuido');

  const PatientRelation(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// El documento del paciente: suma los de menores a los de una cuenta.
enum PatientDocumentType {
  civilRegistry('civil_registry', 'Registro civil'),
  identityCard('identity_card', 'Tarjeta de identidad'),
  citizenshipId('citizenship_id', 'Cédula de ciudadanía'),
  foreignerId('foreigner_id', 'Cédula de extranjería'),
  ppt('ppt', 'PPT');

  const PatientDocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

T? _byApi<T extends Enum>(List<T> values, Object? raw, String Function(T) api) {
  for (final value in values) {
    if (api(value) == raw) return value;
  }
  return null;
}

/// Lo que el solicitante contó de la urgencia (RF-41).
class OrderTriage {
  const OrderTriage({
    required this.redFlags,
    required this.patientGroup,
    required this.symptoms,
    required this.onset,
    required this.severity,
    this.pregnant,
  });

  /// `null` si el JSON no trae tamizaje (pedidos de la app anterior).
  static OrderTriage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final group = _byApi(
      PatientGroup.values,
      raw['patientGroup'],
      (g) => g.apiValue,
    );
    final onset = _byApi(SymptomOnset.values, raw['onset'], (o) => o.apiValue);
    final severity = _byApi(
      SymptomSeverity.values,
      raw['severity'],
      (s) => s.apiValue,
    );
    if (group == null || onset == null || severity == null) return null;
    List<T> listOf<T extends Enum>(
      List<T> all,
      String key,
      String Function(T) api,
    ) => [
      for (final item in raw[key] as List? ?? const []) ?_byApi(all, item, api),
    ];
    return OrderTriage(
      redFlags: listOf(RedFlag.values, 'redFlags', (f) => f.apiValue),
      patientGroup: group,
      pregnant: raw['pregnant'] as bool?,
      symptoms: listOf(Symptom.values, 'symptoms', (s) => s.apiValue),
      onset: onset,
      severity: severity,
    );
  }

  final List<RedFlag> redFlags;
  final PatientGroup patientGroup;
  final bool? pregnant;
  final List<Symptom> symptoms;
  final SymptomOnset onset;
  final SymptomSeverity severity;

  bool get hasRedFlag => redFlags.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'redFlags': [for (final flag in redFlags) flag.apiValue],
    'patientGroup': patientGroup.apiValue,
    'pregnant': ?pregnant,
    'symptoms': [for (final symptom in symptoms) symptom.apiValue],
    'onset': onset.apiValue,
    'severity': severity.apiValue,
  };
}

/// La persona a cargo que es el paciente (RF-42). Sin ella, el paciente es
/// el titular de la cuenta.
class OrderPatient {
  const OrderPatient({
    required this.fullName,
    required this.documentType,
    required this.documentNumber,
    required this.relation,
  });

  static OrderPatient? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = _byApi(
      PatientDocumentType.values,
      raw['documentType'],
      (t) => t.apiValue,
    );
    final relation = _byApi(
      PatientRelation.values,
      raw['relation'],
      (r) => r.apiValue,
    );
    final name = raw['fullName'];
    if (type == null || relation == null || name is! String) return null;
    return OrderPatient(
      fullName: name,
      documentType: type,
      documentNumber: '${raw['documentNumber'] ?? ''}',
      relation: relation,
    );
  }

  final String fullName;
  final PatientDocumentType documentType;
  final String documentNumber;
  final PatientRelation relation;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'documentType': documentType.apiValue,
    'documentNumber': documentNumber,
    'relation': relation.apiValue,
  };
}
