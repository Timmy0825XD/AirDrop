import 'package:flutter/material.dart';

import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../emergency/emergency_choice_sheet.dart';
import '../plan_schedule/schedule_fields.dart';
import '../plan_schedule/schedule_values.dart';
import 'periodic_calendar_choices.dart';
import 'periodic_dates.dart';
import 'periodic_field_row.dart';

class PeriodicCalendarDays extends StatelessWidget {
  const PeriodicCalendarDays({super.key, required this.form});
  final ScheduleForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    if (draft.kind == ScheduleKind.dates) return PeriodicDates(form: form);
    if (draft.kind == ScheduleKind.monthly) {
      return PeriodicFieldRow(
        icon: AppIcons.calendar,
        title: 'Día del mes',
        value: draft.dayOfMonth == null
            ? 'Elige del 1 al 31'
            : 'El día ${draft.dayOfMonth} de cada mes',
        selected: draft.dayOfMonth != null,
        error: form.errors[ScheduleInput.dayOfMonth],
        onTap: () => _month(context, form),
      );
    }
    final days = [...draft.daysOfWeek]..sort();
    return Column(
      children: [
        PeriodicFieldRow(
          icon: AppIcons.calendar,
          title: 'Días de entrega',
          value: days.isEmpty
              ? 'Elige uno o varios días'
              : days.map((d) => capitalized(weekdayName(d))).join(', '),
          selected: days.isNotEmpty,
          error: form.errors[ScheduleInput.days],
          onTap: () => _days(context, form),
        ),
        const SizedBox(height: 12),
        PeriodicFieldRow(
          icon: AppIcons.repeat,
          title: 'Frecuencia',
          value: draft.everyWeeks == 1
              ? 'Cada semana'
              : 'Cada ${draft.everyWeeks} semanas',
          onTap: () => _weeks(context, form),
        ),
      ],
    );
  }
}

Future<void> _days(BuildContext context, ScheduleForm form) async {
  final days = await showEmergencyChoices<int>(
    context,
    title: 'Días de entrega',
    hint: 'Puedes seleccionar más de un día.',
    multiple: true,
    selected: form.draft.daysOfWeek,
    options: [
      for (var d = 1; d <= 7; d++)
        PickerOption(value: d, title: capitalized(weekdayName(d))),
    ],
  );
  if (days == null || !context.mounted) return;
  form.draft.daysOfWeek
    ..clear()
    ..addAll(days);
  form.onChanged();
}

Future<void> _weeks(BuildContext context, ScheduleForm form) async {
  final weeks = await pickPeriodicChoice(
    context,
    title: '¿Cada cuánto se repite?',
    hint: 'Usaremos los días de la semana que elegiste.',
    current: form.draft.everyWeeks,
    options: [
      for (var w = 1; w <= 4; w++)
        PickerOption(
          value: w,
          title: w == 1 ? 'Cada semana' : 'Cada $w semanas',
        ),
    ],
  );
  if (weeks == null || !context.mounted) return;
  form.draft.everyWeeks = weeks;
  form.onChanged();
}

Future<void> _month(BuildContext context, ScheduleForm form) async {
  final day = await pickPeriodicMonthDay(context, form.draft.dayOfMonth);
  if (day == null || !context.mounted) return;
  form.draft.dayOfMonth = day;
  form.onChanged();
}
