import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../data/order_models.dart';
import '../plan_schedule/schedule_fields.dart';
import '../plan_schedule/schedule_kind_fields.dart';
import '../plan_schedule/schedule_range_fields.dart';
import '../plan_schedule/schedule_values.dart';
import 'hub_request_picker.dart';
import 'hub_weekdays.dart';

/// Misma regla de calendario con selectores compactos y duración desplegable.
class HubScheduleFields extends StatelessWidget {
  const HubScheduleFields({super.key, required this.form});
  final ScheduleForm form;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _HubFrequencyField(form: form),
      const SizedBox(height: 12),
      if (form.draft.kind == ScheduleKind.weekly)
        HubWeekdays(form: form)
      else
        ScheduleKindFields(form: form, showWeeklyInterval: false),
      const SizedBox(height: 16),
      HubRequestPicker<String>(
        label: 'Franja horaria',
        hint: 'Elige una franja',
        icon: AppIcons.clock,
        options: [
          for (final time in slotTimes)
            PickerOption(
              value: time,
              title:
                  '${formatTimeText(time)} – ${formatTimeText('${int.parse(time.split(':').first) + 1}:00')}',
            ),
        ],
        isSelected: (value) => value == form.draft.time,
        onSelected: (value) {
          form.draft.time = value;
          form.onChanged();
        },
      ),
      if (form.draft.kind != ScheduleKind.dates) ...[
        const SizedBox(height: 16),
        _HubScheduleRange(form: form),
      ],
    ],
  );
}

class _HubFrequencyField extends StatelessWidget {
  const _HubFrequencyField({required this.form});
  final ScheduleForm form;
  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    final selected = draft.kind == ScheduleKind.weekly
        ? 'weekly:${draft.everyWeeks}'
        : draft.kind.apiValue;
    return HubRequestPicker<String>(
      label: 'Frecuencia',
      hint: 'Elige la frecuencia',
      icon: AppIcons.calendar,
      options: [
        for (var weeks = 1; weeks <= 4; weeks++)
          PickerOption(
            value: 'weekly:$weeks',
            title: weeks == 1 ? 'Semanal' : 'Cada $weeks semanas',
          ),
        const PickerOption(value: 'monthly', title: 'Mensual'),
        const PickerOption(value: 'dates', title: 'Fechas específicas'),
      ],
      isSelected: (value) => value == selected,
      onSelected: (value) {
        if (value.startsWith('weekly:')) {
          draft.kind = ScheduleKind.weekly;
          draft.everyWeeks = int.parse(value.split(':').last);
        } else {
          draft.kind = value == 'monthly'
              ? ScheduleKind.monthly
              : ScheduleKind.dates;
        }
        form.onChanged();
      },
    );
  }
}

class _HubScheduleRange extends StatelessWidget {
  const _HubScheduleRange({required this.form});
  final ScheduleForm form;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthDateField(
        label: 'Fecha de inicio',
        value: form.draft.startDate,
        hint: 'Elige la fecha',
        icon: AppIcons.calendar,
        trailingIcon: AppIcons.down,
        onTap: () async {
          final picked = await pickFutureDate(
            context,
            current: form.draft.startDate,
          );
          if (picked == null || !context.mounted) return;
          form.draft.startDate = picked;
          form.onChanged();
        },
      ),
      const SizedBox(height: 8),
      ExpansionTile(
        key: ValueKey(form.errors[ScheduleInput.end] != null),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: const Text('Duración del plan'),
        subtitle: Text(
          form.draft.end == ScheduleEnd.count
              ? '${form.draft.count.text} entregas'
              : 'Hasta ${form.draft.endDate == null ? 'elegir una fecha' : formatDay(form.draft.endDate!, relative: false)}',
        ),
        initiallyExpanded: form.errors[ScheduleInput.end] != null,
        children: [ScheduleEndFields(form: form)],
      ),
    ],
  );
}
