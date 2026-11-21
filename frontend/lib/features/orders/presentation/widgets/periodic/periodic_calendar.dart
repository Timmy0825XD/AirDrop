import 'package:flutter/material.dart';

import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../emergency/emergency_layout.dart';
import '../plan_schedule/schedule_fields.dart';
import 'periodic_calendar_choices.dart';
import 'periodic_calendar_days.dart';
import 'periodic_calendar_range.dart';
import 'periodic_field_row.dart';

class PeriodicCalendar extends StatelessWidget {
  const PeriodicCalendar({
    super.key,
    required this.form,
    required this.preview,
  });
  final ScheduleForm form;
  final Widget preview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EmergencyIntro(
        title: 'Elige tu ritmo.',
        subtitle:
            'Decide los días y la hora. Te mostraremos las fechas antes de programar.',
      ),
      PeriodicFieldRow(
        icon: AppIcons.repeat,
        title: '¿Cómo se repite?',
        value: form.draft.kind.label,
        onTap: () => _pickKind(context, form),
      ),
      const SizedBox(height: 12),
      PeriodicCalendarDays(form: form),
      if (form.draft.kind != ScheduleKind.dates) ...[
        const SizedBox(height: 24),
        PeriodicCalendarRange(form: form),
      ],
      const SizedBox(height: 24),
      PeriodicFieldRow(
        icon: AppIcons.clock,
        title: 'Hora de entrega',
        value: periodicTimeSlot(form.draft.time),
        onTap: () => _pickTime(context, form),
      ),
      if (form.needsPrescription) ...[
        const SizedBox(height: 12),
        PeriodicDateRow(form: form, prescription: true),
      ],
      const SizedBox(height: 24),
      preview,
    ],
  );
}

Future<void> _pickKind(BuildContext context, ScheduleForm form) async {
  final kind = await pickPeriodicChoice(
    context,
    title: '¿Cómo quieres las entregas?',
    hint: 'Elige la opción que se acomode a tu tratamiento.',
    current: form.draft.kind,
    options: [
      const PickerOption(
        value: ScheduleKind.weekly,
        title: 'Días de la semana',
        subtitle: 'Uno o varios días, cada 1 a 4 semanas',
        icon: AppIcons.repeat,
      ),
      const PickerOption(
        value: ScheduleKind.monthly,
        title: 'Un día del mes',
        subtitle: 'La misma fecha cada mes',
        icon: AppIcons.calendar,
      ),
      const PickerOption(
        value: ScheduleKind.dates,
        title: 'Fechas sueltas',
        subtitle: 'Elige hasta 30 fechas específicas',
        icon: AppIcons.createPlan,
      ),
    ],
  );
  if (kind == null || !context.mounted) return;
  form.draft.kind = kind;
  form.onChanged();
}

Future<void> _pickTime(BuildContext context, ScheduleForm form) async {
  final time = await pickPeriodicChoice(
    context,
    title: 'Hora de entrega',
    hint: 'Cada entrega tiene una franja de una hora.',
    current: form.draft.time,
    options: [
      for (final time in slotTimes)
        PickerOption(
          value: time,
          title: periodicTimeSlot(time),
          icon: AppIcons.clock,
        ),
    ],
  );
  if (time == null || !context.mounted) return;
  form.draft.time = time;
  form.onChanged();
}
