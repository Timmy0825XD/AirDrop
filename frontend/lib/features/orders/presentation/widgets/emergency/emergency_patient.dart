import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/yes_no_question.dart';
import '../../../data/triage_models.dart';
import '../requester_order/patient_fields.dart';
import '../requester_order/chip_choice_field.dart';
import '../requester_order/triage_fields.dart';
import '../requester_order/triage_values.dart';
import 'emergency_question_row.dart';
import 'emergency_layout.dart';

class EmergencyPatient extends StatelessWidget {
  const EmergencyPatient({super.key, required this.form});
  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final d = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Para quién es?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PatientChoice(
                label: 'Para mí',
                icon: Icons.person_rounded,
                selected: !d.forSomeoneElse,
                onTap: () => form.edit((d) => d.forSomeoneElse = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PatientChoice(
                label: 'Otra persona',
                icon: Icons.people_alt_rounded,
                selected: d.forSomeoneElse,
                onTap: () => form.edit((d) => d.forSomeoneElse = true),
              ),
            ),
          ],
        ),
        if (d.forSomeoneElse) ...[
          const SizedBox(height: 20),
          DependentFields(form: form),
        ],
        const SizedBox(height: 16),
        EmergencySurface(
          child: EmergencyQuestionRow(
            icon: Icons.person_outline_rounded,
            label: 'Paciente',
            value: _patientSummary(d),
            answered: d.group != null,
            error:
                form.errors[TriageInput.group] ??
                form.errors[TriageInput.pregnant],
            onTap: () => _editPatient(context, form),
          ),
        ),
      ],
    );
  }
}

class _PatientChoice extends StatelessWidget {
  const _PatientChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PatientChoiceMark(icon: icon, selected: selected),
                const SizedBox(height: 10),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _patientSummary(TriageDraft d) => [
  d.group?.label ?? 'Elige el grupo de edad',
  if (d.group?.mayBePregnant == true)
    d.pregnant == null
        ? 'Indica si hay embarazo'
        : d.pregnant!
        ? 'Embarazada'
        : 'Sin embarazo',
].join(' · ');

class _PatientChoiceMark extends StatelessWidget {
  const _PatientChoiceMark({required this.icon, required this.selected});
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const Spacer(),
      if (selected)
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
    ],
  );
}

Future<void> _editPatient(BuildContext context, TriageForm form) async {
  final result = await showAppSheet<(PatientGroup, bool?)>(
    context,
    builder: (_) =>
        _PatientSheet(group: form.draft.group, pregnant: form.draft.pregnant),
  );
  if (result == null || !context.mounted) return;
  form.edit((d) {
    d.pickGroup(result.$1);
    d.pregnant = result.$2;
  });
}

class _PatientSheet extends StatefulWidget {
  const _PatientSheet({required this.group, required this.pregnant});
  final PatientGroup? group;
  final bool? pregnant;
  @override
  State<_PatientSheet> createState() => _PatientSheetState();
}

class _PatientSheetState extends State<_PatientSheet> {
  late PatientGroup? _group = widget.group;
  late bool? _pregnant = widget.pregnant;

  @override
  Widget build(BuildContext context) {
    final ready =
        _group != null && (!_group!.mayBePregnant || _pregnant != null);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sobre el paciente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Un par de datos para el despachador.'),
            const SizedBox(height: 24),
            ChipChoiceField<PatientGroup>(
              label: 'Grupo de edad',
              options: PatientGroup.values,
              labelOf: (g) => g.label,
              isSelected: (g) => g == _group,
              onTap: (g) => setState(() {
                _group = g;
                _pregnant = null;
              }),
            ),
            if (_group?.mayBePregnant == true) ...[
              const SizedBox(height: 24),
              YesNoQuestion(
                question: '¿Está embarazada?',
                value: _pregnant,
                onChanged: (v) => setState(() => _pregnant = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: ready
                  ? () => Navigator.pop(context, (
                      _group!,
                      _group!.mayBePregnant ? _pregnant : null,
                    ))
                  : null,
              child: const Text('Confirmar datos'),
            ),
          ],
        ),
      ),
    );
  }
}
