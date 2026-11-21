import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/sliding_segmented.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../order_format.dart';
import '../plan_schedule/schedule_fields.dart';
import '../plan_schedule/schedule_values.dart';
import 'periodic_field_row.dart';

class PeriodicCalendarRange extends StatelessWidget {
  const PeriodicCalendarRange({super.key, required this.form});
  final ScheduleForm form;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PeriodicDateRow(form: form),
      const SizedBox(height: 20),
      Text('¿Cuándo termina?', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SlidingSegmented<ScheduleEnd>(
        options: const [
          SegmentOption(ScheduleEnd.count, 'Por entregas'),
          SegmentOption(ScheduleEnd.until, 'Por fecha'),
        ],
        selected: form.draft.end,
        onChanged: (end) {
          form.draft.end = end;
          form.onChanged();
        },
      ),
      const SizedBox(height: 16),
      if (form.draft.end == ScheduleEnd.until)
        PeriodicDateRow(form: form, end: true)
      else
        AuthField(
          label: 'Número de entregas',
          hint: 'Ej.: 4',
          controller: form.draft.count,
          keyboardType: TextInputType.number,
          maxLength: 3,
          errorText: form.errors[ScheduleInput.end],
          shakeCount: form.shakeCount,
          onChanged: (_) => form.onChanged(),
        ),
      const SizedBox(height: 8),
      Text(
        'Puedes programar hasta 3 meses de entregas.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class PeriodicDateRow extends StatelessWidget {
  const PeriodicDateRow({
    super.key,
    required this.form,
    this.end = false,
    this.prescription = false,
  });
  final ScheduleForm form;
  final bool end;
  final bool prescription;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    final value = prescription
        ? draft.prescriptionValidUntil
        : end
        ? draft.endDate
        : draft.startDate;
    return PeriodicFieldRow(
      icon: prescription ? AppIcons.document : AppIcons.calendar,
      title: prescription
          ? 'La fórmula vale hasta'
          : end
          ? 'Último día del plan'
          : 'Fecha de inicio',
      value: value == null
          ? 'Elige una fecha'
          : capitalized(formatDay(value, relative: false)),
      selected: value != null,
      error: prescription
          ? form.errors[ScheduleInput.prescription]
          : end
          ? form.errors[ScheduleInput.end]
          : null,
      onTap: () async {
        final picked = await pickFutureDate(
          context,
          current: value ?? draft.startDate,
        );
        if (picked == null || !context.mounted) return;
        if (prescription) {
          draft.prescriptionValidUntil = picked;
        } else if (end) {
          draft.endDate = picked;
        } else {
          draft.startDate = picked;
        }
        form.onChanged();
      },
    );
  }
}
