import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../order_format.dart';
import '../plan_schedule/schedule_fields.dart';
import '../plan_schedule/schedule_values.dart';

class PeriodicDates extends StatelessWidget {
  const PeriodicDates({super.key, required this.form});
  final ScheduleForm form;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Tus fechas (${form.draft.dates.length}/30)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final date in form.draft.dates)
            InputChip(
              label: Text(capitalized(formatDay(date, relative: false))),
              deleteIcon: const Icon(AppIcons.close, size: 18),
              onDeleted: () {
                form.draft.dates.remove(date);
                form.onChanged();
              },
            ),
        ],
      ),
      AuthFieldError(message: form.errors[ScheduleInput.dates]),
      if (form.draft.dates.length < 30)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _add(context, form),
            icon: const Icon(AppIcons.add),
            label: const Text('Agregar fecha'),
          ),
        ),
    ],
  );
}

Future<void> _add(BuildContext context, ScheduleForm form) async {
  final date = await pickFutureDate(context);
  if (date == null || !context.mounted || form.draft.dates.contains(date)) {
    return;
  }
  form.draft.dates
    ..add(date)
    ..sort();
  form.onChanged();
}
