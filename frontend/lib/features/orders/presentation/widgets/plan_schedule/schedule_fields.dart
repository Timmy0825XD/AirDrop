import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../data/order_models.dart';
import 'schedule_values.dart';
import 'schedule_kind_fields.dart';
import 'schedule_range_fields.dart';

/// Lo que los campos del calendario reciben de la pantalla.
class ScheduleForm {
  const ScheduleForm({
    required this.draft,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
    this.needsPrescription = false,
  });

  final ScheduleDraft draft;
  final Map<ScheduleInput, String> errors;
  final int shakeCount;

  /// Algo cambió: la pantalla repinta y pide de nuevo la vista previa.
  final VoidCallback onChanged;

  /// Plan civil bajo fórmula: hay que decir hasta cuándo vale.
  final bool needsPrescription;
}

/// El calendario de un plan (RU-30): el tipo, sus días, cuándo empieza y
/// termina, la hora de la franja y, con fórmula, su vigencia.
class ScheduleFields extends StatelessWidget {
  const ScheduleFields({super.key, required this.form});

  final ScheduleForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Calendario',
          children: [
            for (final kind in ScheduleKind.values)
              ChoicePill(
                label: kind.label,
                selected: draft.kind == kind,
                onTap: () {
                  draft.kind = kind;
                  form.onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        ScheduleKindFields(form: form),
        if (draft.kind != ScheduleKind.dates) ...[
          const SizedBox(height: 16),
          ScheduleRangeFields(form: form),
        ],
        const SizedBox(height: 16),
        ScheduleTimeField(form: form),
        if (form.needsPrescription) ...[
          const SizedBox(height: 16),
          _PrescriptionValidity(form: form),
        ],
      ],
    );
  }
}

/// La hora en punto de la franja (07:00 a 17:00).
class ScheduleTimeField extends StatelessWidget {
  const ScheduleTimeField({super.key, required this.form});

  final ScheduleForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Hora de la entrega',
          children: [
            for (final time in slotTimes)
              ChoicePill(
                label: time,
                selected: draft.time == time,
                filled: false,
                onTap: () {
                  draft.time = time;
                  form.onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'La entrega se hace dentro de esa hora.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PrescriptionValidity extends StatelessWidget {
  const _PrescriptionValidity({required this.form});

  final ScheduleForm form;

  Future<void> _pick(BuildContext context) async {
    final draft = form.draft;
    final picked = await pickFutureDate(
      context,
      current: draft.prescriptionValidUntil,
    );
    if (picked == null) return;
    draft.prescriptionValidUntil = picked;
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthDateField(
          label: 'La fórmula vale hasta',
          value: form.draft.prescriptionValidUntil,
          hint: 'Elige la fecha',
          errorText: form.errors[ScheduleInput.prescription],
          shakeCount: form.shakeCount,
          onTap: () => _pick(context),
        ),
        const SizedBox(height: 6),
        Text(
          'El plan no pasará de esa fecha.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
