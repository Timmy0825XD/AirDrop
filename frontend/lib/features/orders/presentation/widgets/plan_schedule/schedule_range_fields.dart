import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import 'schedule_values.dart';
import 'schedule_fields.dart';

/// Cuándo empieza el plan y cuándo termina: en una fecha **o** tras un
/// número de entregas (Nest no acepta las dos).
class ScheduleRangeFields extends StatelessWidget {
  const ScheduleRangeFields({super.key, required this.form});

  final ScheduleForm form;

  Future<void> _pickStart(BuildContext context) async {
    final draft = form.draft;
    final picked = await pickFutureDate(context, current: draft.startDate);
    if (picked == null) return;
    draft.startDate = picked;
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthDateField(
          label: 'Empieza',
          value: draft.startDate,
          hint: 'Elige la fecha',
          shakeCount: form.shakeCount,
          onTap: () => _pickStart(context),
        ),
        const SizedBox(height: 16),
        _ScheduleEndFields(form: form),
      ],
    );
  }
}

/// Termina en una fecha o tras un número de entregas.
class _ScheduleEndFields extends StatelessWidget {
  const _ScheduleEndFields({required this.form});

  final ScheduleForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    final error = form.errors[ScheduleInput.end];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Termina',
          children: [
            for (final (end, label) in const [
              (ScheduleEnd.count, 'Tras un número de entregas'),
              (ScheduleEnd.until, 'En una fecha'),
            ])
              ChoicePill(
                label: label,
                selected: draft.end == end,
                filled: false,
                onTap: () {
                  draft.end = end;
                  form.onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (draft.end == ScheduleEnd.until)
          AuthDateField(
            label: 'Fecha de fin',
            value: draft.endDate,
            hint: 'Elige la fecha',
            errorText: error,
            shakeCount: form.shakeCount,
            onTap: () => _pickEndDate(context, form),
          )
        else
          AuthField(
            label: 'Número de entregas',
            hint: '4',
            controller: draft.count,
            keyboardType: TextInputType.number,
            maxLength: 3,
            errorText: error,
            shakeCount: form.shakeCount,
            onChanged: (_) => form.onChanged(),
          ),
      ],
    );
  }
}

Future<void> _pickEndDate(BuildContext context, ScheduleForm form) async {
  final draft = form.draft;
  final picked = await pickFutureDate(
    context,
    current: draft.endDate ?? draft.startDate,
  );
  if (picked == null) return;
  draft.endDate = picked;
  form.onChanged();
}
