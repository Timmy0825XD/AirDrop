import 'package:flutter/material.dart';

import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../data/triage_models.dart';
import '../requester_order/triage_fields.dart';
import 'emergency_choice_sheet.dart';

Future<void> editEmergencySymptoms(
  BuildContext context,
  TriageForm form,
) async {
  final result = await showEmergencyChoices<Symptom>(
    context,
    title: '¿Qué siente?',
    hint: 'Puedes elegir más de un síntoma.',
    multiple: true,
    selected: form.draft.symptoms,
    options: [
      for (final symptom in Symptom.values)
        PickerOption(
          value: symptom,
          title: symptom.label,
          icon: symptomIcon(symptom),
        ),
    ],
  );
  if (result != null && context.mounted) {
    form.edit(
      (d) => d.symptoms
        ..clear()
        ..addAll(result),
    );
  }
}

IconData symptomIcon(Symptom symptom) => switch (symptom) {
  Symptom.fever => Icons.thermostat_rounded,
  Symptom.pain => Icons.healing_rounded,
  Symptom.breathing => Icons.air_rounded,
  Symptom.allergy => Icons.spa_rounded,
  Symptom.bloodSugar => Icons.water_drop_rounded,
  Symptom.bloodPressure => Icons.monitor_heart_rounded,
  Symptom.infection => Icons.health_and_safety_rounded,
  Symptom.stomach => Icons.accessibility_new_rounded,
  Symptom.other => Icons.more_horiz_rounded,
};

Future<void> editEmergencyOnset(BuildContext context, TriageForm form) async {
  final current = form.draft.onset;
  final result = await showEmergencyChoices<SymptomOnset>(
    context,
    title: '¿Desde cuándo?',
    hint: 'Elige cuándo comenzaron los síntomas.',
    selected: {?current},
    options: [
      for (final onset in SymptomOnset.values)
        PickerOption(
          value: onset,
          title: onset.label,
          icon: Icons.schedule_rounded,
        ),
    ],
  );
  if (result != null && context.mounted) {
    form.edit((d) => d.onset = result.single);
  }
}

Future<void> editEmergencySeverity(
  BuildContext context,
  TriageForm form,
) async {
  final current = form.draft.severity;
  final result = await showEmergencyChoices<SymptomSeverity>(
    context,
    title: '¿Qué tan fuerte?',
    hint: 'Elige cómo se siente en este momento.',
    selected: {?current},
    options: [
      for (final severity in SymptomSeverity.values)
        PickerOption(
          value: severity,
          title: severity.label,
          icon: Icons.signal_cellular_alt_rounded,
        ),
    ],
  );
  if (result != null && context.mounted) {
    form.edit((d) => d.severity = result.single);
  }
}

Future<void> editEmergencyAlarms(BuildContext context, TriageForm form) async {
  final draft = form.draft;
  final result = await showEmergencyChoices<RedFlag?>(
    context,
    title: 'Signos de alarma',
    hint: 'Marca los que tiene ahora o elige «Ninguno».',
    multiple: true,
    exclusive: (flag) => flag == null,
    selected: {if (draft.anyRedFlag == false) null, ...draft.redFlags},
    options: [
      for (final flag in RedFlag.values)
        PickerOption(
          value: flag,
          title: flag.label,
          icon: Icons.warning_amber_rounded,
        ),
      const PickerOption(
        value: null,
        title: 'Ninguno',
        icon: Icons.check_rounded,
      ),
    ],
  );
  if (result == null || !context.mounted) return;
  form.edit((d) {
    if (result.contains(null)) {
      d.noRedFlags();
    } else {
      d.anyRedFlag = true;
      d.redFlags
        ..clear()
        ..addAll(result.whereType<RedFlag>());
    }
  });
}
