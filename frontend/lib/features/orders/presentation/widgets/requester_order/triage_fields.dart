import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/app_snack.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../core/widgets/yes_no_question.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/triage_models.dart';
import 'chip_choice_field.dart';
import 'triage_values.dart';

/// Lo que la pantalla le pasa a los campos del tamizaje.
class TriageForm {
  const TriageForm({
    required this.draft,
    required this.errors,
    required this.onChanged,
  });

  final TriageDraft draft;
  final Map<TriageInput, String> errors;
  final VoidCallback onChanged;

  /// Cambia el borrador y pide repintar.
  void edit(void Function(TriageDraft draft) change) {
    change(draft);
    onChanged();
  }
}

/// Primero los signos de alarma (RF-41): son los que más se pasan por alto.
/// Con uno marcado sale el 123, y se puede seguir pidiendo.
class RedFlagsField extends StatelessWidget {
  const RedFlagsField({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipChoiceField<RedFlag>(
          label: '¿Tiene alguno de estos signos ahora?',
          options: RedFlag.values,
          labelOf: (flag) => flag.label,
          isSelected: draft.redFlags.contains,
          onTap: (flag) => form.edit((d) => d.toggleRedFlag(flag)),
          errorText: form.errors[TriageInput.redFlags],
          trailing: ChoicePill(
            label: 'Ninguno',
            selected: draft.anyRedFlag == false,
            showCheck: true,
            onTap: () => form.edit((d) => d.noRedFlags()),
          ),
        ),
        if (draft.hasRedFlag) ...[
          const SizedBox(height: 12),
          const AlarmCallCard(),
        ],
      ],
    );
  }
}

Future<void> _call123(BuildContext context) async {
  final opened = await launchUrl(Uri(scheme: 'tel', path: '123'));
  if (!opened && context.mounted) {
    showAppSnack(
      context,
      'No se pudo abrir el marcador. Llama al 123 desde tu teléfono.',
      tone: SnackTone.info,
    );
  }
}

/// El aviso rojo de un signo de alarma: el dron no reemplaza una
/// ambulancia. El botón abre el marcador con el 123.
class AlarmCallCard extends StatelessWidget {
  const AlarmCallCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = context.palette.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Esto puede ser grave. Llama al 123 ahora: el dron no reemplaza '
            'una ambulancia. Puedes seguir con el pedido y le llegará primero '
            'al despachador.',
            style: theme.textTheme.bodyMedium?.copyWith(color: danger),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => _call123(context),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Llamar al 123'),
          ),
        ],
      ),
    );
  }
}

/// Quién es el paciente: edad en grupos y, donde aplica, si está
/// embarazada.
class PatientGroupField extends StatelessWidget {
  const PatientGroupField({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipChoiceField<PatientGroup>(
          label: 'El paciente es',
          options: PatientGroup.values,
          labelOf: (group) => group.label,
          isSelected: (group) => draft.group == group,
          onTap: (group) => form.edit((d) => d.pickGroup(group)),
          errorText: form.errors[TriageInput.group],
        ),
        if (draft.group?.mayBePregnant == true) ...[
          const SizedBox(height: 12),
          YesNoQuestion(
            question: '¿Está embarazada?',
            value: draft.pregnant,
            onChanged: (value) => form.edit((d) => d.pregnant = value),
          ),
          AuthFieldError(message: form.errors[TriageInput.pregnant]),
        ],
      ],
    );
  }
}

/// Qué siente, desde cuándo y qué tan fuerte: tres toques.
class SymptomFields extends StatelessWidget {
  const SymptomFields({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipChoiceField<Symptom>(
          label: '¿Qué siente?',
          options: Symptom.values,
          labelOf: (symptom) => symptom.label,
          isSelected: draft.symptoms.contains,
          onTap: (symptom) => form.edit(
            (d) => d.symptoms.contains(symptom)
                ? d.symptoms.remove(symptom)
                : d.symptoms.add(symptom),
          ),
          errorText: form.errors[TriageInput.symptoms],
        ),
        const SizedBox(height: 16),
        ChipChoiceField<SymptomOnset>(
          label: '¿Desde cuándo?',
          options: SymptomOnset.values,
          labelOf: (onset) => onset.label,
          isSelected: (onset) => draft.onset == onset,
          onTap: (onset) => form.edit((d) => d.onset = onset),
          errorText: form.errors[TriageInput.onset],
        ),
        const SizedBox(height: 16),
        ChipChoiceField<SymptomSeverity>(
          label: '¿Qué tan fuerte?',
          options: SymptomSeverity.values,
          labelOf: (severity) => severity.label,
          isSelected: (severity) => draft.severity == severity,
          onTap: (severity) => form.edit((d) => d.severity = severity),
          errorText: form.errors[TriageInput.severity],
        ),
      ],
    );
  }
}
