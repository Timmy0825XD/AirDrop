import 'package:flutter/material.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../data/triage_models.dart';

/// Los campos del tamizaje y del paciente que pueden tener error.
enum TriageInput {
  redFlags,
  group,
  pregnant,
  symptoms,
  onset,
  severity,
  patientName,
  patientDocumentType,
  patientDocument,
  relation,
  allergies,
}

/// Lo que el solicitante va contando de la urgencia (RF-41) y, si es para
/// otra persona, quién es (RF-42). Todo en fichas salvo el nombre, el
/// documento y las alergias.
class TriageDraft {
  /// `null` mientras no contesta; `false` es "Ninguno".
  bool? anyRedFlag;
  final redFlags = <RedFlag>{};
  PatientGroup? group;
  bool? pregnant;
  final symptoms = <Symptom>{};
  SymptomOnset? onset;
  SymptomSeverity? severity;

  bool forSomeoneElse = false;
  final patientName = TextEditingController();
  PatientDocumentType? patientDocumentType;
  final patientDocument = TextEditingController();
  PatientRelation? relation;

  /// `null` mientras no contesta.
  bool? hasAllergies;
  final allergies = TextEditingController();
  bool _prefilled = false;

  void dispose() {
    for (final c in [patientName, patientDocument, allergies]) {
      c.dispose();
    }
  }

  bool get hasRedFlag => anyRedFlag == true && redFlags.isNotEmpty;

  /// Marca o desmarca un signo; sin ninguno marcado vuelve a "sin contestar".
  void toggleRedFlag(RedFlag flag) {
    redFlags.contains(flag) ? redFlags.remove(flag) : redFlags.add(flag);
    anyRedFlag = redFlags.isEmpty ? null : true;
  }

  void noRedFlags() {
    redFlags.clear();
    anyRedFlag = false;
  }

  void pickGroup(PatientGroup value) {
    group = value;
    if (!value.mayBePregnant) pregnant = null;
  }

  /// Trae las alergias que la cuenta ya tiene, una sola vez y solo si el
  /// paciente es el titular.
  void prefillFrom(PublicUser? user) {
    if (_prefilled || user == null) return;
    _prefilled = true;
    final known = user.allergies;
    if (known != null && known.isNotEmpty) {
      hasAllergies = true;
      allergies.text = known;
    }
  }

  /// Los errores del paso "Qué pasa" (o, con [patientOnly], solo de quién
  /// es el paciente, para la entrega periódica).
  Map<TriageInput, String> validateSituation({bool patientOnly = false}) {
    final errors = <TriageInput, String?>{
      if (!patientOnly) ...{
        TriageInput.redFlags: anyRedFlag == null
            ? 'Marca los signos que tiene o «Ninguno».'
            : null,
        TriageInput.group: group == null ? 'Di quién es el paciente.' : null,
        TriageInput.pregnant: group?.mayBePregnant == true && pregnant == null
            ? 'Di si está embarazada.'
            : null,
        TriageInput.symptoms: symptoms.isEmpty
            ? 'Elige al menos un síntoma.'
            : null,
        TriageInput.onset: onset == null ? 'Di desde cuándo.' : null,
        TriageInput.severity: severity == null ? 'Di qué tan fuerte.' : null,
      },
      ..._patientErrors(),
    };
    return {
      for (final e in errors.entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  Map<TriageInput, String?> _patientErrors() {
    if (!forSomeoneElse) return const {};
    final type = patientDocumentType;
    return {
      TriageInput.patientName: patientName.text.trim().length < 3
          ? 'Escribe el nombre completo del paciente.'
          : null,
      TriageInput.patientDocumentType: type == null
          ? 'Elige el tipo de documento.'
          : null,
      TriageInput.patientDocument:
          type != null && !_validDocument(type, patientDocument.text)
          ? 'El número no corresponde a ese documento.'
          : null,
      TriageInput.relation: relation == null
          ? 'Di quién es el paciente para ti.'
          : null,
    };
  }

  Map<TriageInput, String> validateAllergies() {
    if (hasAllergies == null) {
      return {TriageInput.allergies: 'Di si es alérgico a algún medicamento.'};
    }
    if (hasAllergies! && allergies.text.trim().isEmpty) {
      return {TriageInput.allergies: 'Escribe a qué medicamentos.'};
    }
    return const {};
  }

  OrderTriage toTriage() => OrderTriage(
    redFlags: hasRedFlag ? redFlags.toList() : const [],
    patientGroup: group!,
    pregnant: group!.mayBePregnant ? pregnant : null,
    symptoms: symptoms.toList(),
    onset: onset!,
    severity: severity!,
  );

  /// La persona a cargo si ya está completa, para mostrarla (la fórmula
  /// va a su nombre); `null` si es el titular o faltan datos.
  OrderPatient? toPatientOrNull() =>
      forSomeoneElse && _patientErrors().values.every((e) => e == null)
      ? toPatient()
      : null;

  OrderPatient? toPatient() => !forSomeoneElse
      ? null
      : OrderPatient(
          fullName: patientName.text.trim(),
          documentType: patientDocumentType!,
          documentNumber: patientDocument.text.trim().toUpperCase(),
          relation: relation!,
        );

  /// Vacío es "ninguna" (§19.1).
  String get allergiesValue =>
      hasAllergies == true ? allergies.text.trim() : '';
}

/// Los mismos patrones que Nest (`normalizePatientDocument`).
bool _validDocument(PatientDocumentType type, String raw) {
  final value = raw.trim().toUpperCase();
  final pattern = switch (type) {
    PatientDocumentType.civilRegistry => RegExp(r'^\d{8,11}$'),
    PatientDocumentType.identityCard => RegExp(r'^\d{10,11}$'),
    PatientDocumentType.citizenshipId ||
    PatientDocumentType.foreignerId => RegExp(r'^\d{6,10}$'),
    PatientDocumentType.ppt => RegExp(r'^[A-Z0-9]{6,15}$'),
  };
  return pattern.hasMatch(value);
}
