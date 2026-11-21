import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../requester_order/triage_fields.dart';
import '../requester_order/triage_values.dart';
import 'emergency_layout.dart';
import 'emergency_patient.dart';
import 'emergency_question_row.dart';
import 'emergency_triage_actions.dart';

class EmergencySituation extends StatelessWidget {
  const EmergencySituation({super.key, required this.form, required this.note});
  final TriageForm form;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EmergencyIntro(
        title: 'Vamos contigo.',
        subtitle: 'Primero, cuéntanos qué pasa.',
      ),
      EmergencySurface(
        child: EmergencyQuestionRow(
          icon: Icons.monitor_heart_rounded,
          label: 'Signos de alarma',
          answered: form.draft.anyRedFlag != null,
          value: form.draft.anyRedFlag == null
              ? 'Revisa antes de continuar'
              : form.draft.hasRedFlag
              ? form.draft.redFlags.map((f) => f.label).join(', ')
              : 'Ninguno de estos signos',
          error: form.errors[TriageInput.redFlags],
          onTap: () => editEmergencyAlarms(context, form),
        ),
      ),
      if (form.draft.hasRedFlag) ...[
        const SizedBox(height: 12),
        const AlarmCallCard(),
      ],
      const SizedBox(height: 24),
      EmergencyPatient(form: form),
      const SizedBox(height: 24),
      _SymptomSummary(form: form),
      const SizedBox(height: 12),
      _EmergencyNote(controller: note),
    ],
  );
}

class _SymptomSummary extends StatelessWidget {
  const _SymptomSummary({required this.form});
  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final d = form.draft;
    return EmergencySurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '¿Cómo te sientes?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          EmergencyQuestionRow(
            icon: Icons.thermostat_rounded,
            label: 'Síntomas',
            value: d.symptoms.isEmpty
                ? 'Elige lo que siente'
                : d.symptoms.map((s) => s.label).join(', '),
            answered: d.symptoms.isNotEmpty,
            error: form.errors[TriageInput.symptoms],
            onTap: () => editEmergencySymptoms(context, form),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          EmergencyQuestionRow(
            icon: Icons.schedule_rounded,
            label: 'Desde cuándo',
            value: d.onset?.label ?? '¿Cuándo empezó?',
            answered: d.onset != null,
            error: form.errors[TriageInput.onset],
            onTap: () => editEmergencyOnset(context, form),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          EmergencyQuestionRow(
            icon: Icons.signal_cellular_alt_rounded,
            label: 'Intensidad',
            value: d.severity?.label ?? '¿Qué tan fuerte?',
            answered: d.severity != null,
            error: form.errors[TriageInput.severity],
            onTap: () => editEmergencySeverity(context, form),
          ),
        ],
      ),
    );
  }
}

class _EmergencyNote extends StatelessWidget {
  const _EmergencyNote({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(top: 8),
    shape: const Border(),
    collapsedShape: const Border(),
    leading: Icon(
      Icons.add_rounded,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: const Text('Añadir una nota'),
    subtitle: const Text('Opcional'),
    initiallyExpanded: controller.text.isNotEmpty,
    maintainState: true,
    children: [
      AuthField(
        label: 'Algo más para el despachador',
        hint: 'Ej.: empezó con fiebre anoche',
        controller: controller,
        maxLength: FieldLimits.orderDescription,
        maxLines: 3,
      ),
    ],
  );
}
