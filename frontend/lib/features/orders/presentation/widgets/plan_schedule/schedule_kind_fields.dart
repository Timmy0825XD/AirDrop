import '../../../../../theme/app_icons.dart';
import 'package:flutter/material.dart';

import 'schedule_chip.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import 'schedule_values.dart';
import 'schedule_fields.dart';

/// Lo propio de cada tipo de calendario: los días de la semana, el día
/// del mes o las fechas sueltas.
class ScheduleKindFields extends StatelessWidget {
  const ScheduleKindFields({
    super.key,
    required this.form,
    this.showWeeklyInterval = true,
  });

  final ScheduleForm form;
  final bool showWeeklyInterval;

  @override
  Widget build(BuildContext context) {
    return switch (form.draft.kind) {
      ScheduleKind.weekly => _WeeklyFields(
        form: form,
        showInterval: showWeeklyInterval,
      ),
      ScheduleKind.monthly => _MonthlyFields(form: form),
      ScheduleKind.dates => _DatesFields(form: form),
    };
  }
}

const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class _WeeklyFields extends StatelessWidget {
  const _WeeklyFields({required this.form, required this.showInterval});

  final ScheduleForm form;
  final bool showInterval;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Días',
          errorText: form.errors[ScheduleInput.days],
          shakeCount: form.shakeCount,
          children: [
            for (var day = 1; day <= 7; day++)
              Semantics(
                label: weekdayName(day),
                child: ScheduleChip(
                  label: _dayLetters[day - 1],
                  selected: draft.daysOfWeek.contains(day),
                  onTap: () {
                    draft.toggleDay(day);
                    form.onChanged();
                  },
                ),
              ),
          ],
        ),
        if (showInterval) const SizedBox(height: 16),
        if (showInterval)
          AuthChoiceGroup(
            label: 'Se repite',
            children: [
              for (var weeks = 1; weeks <= 4; weeks++)
                ScheduleChip(
                  label: weeks == 1 ? 'Cada semana' : 'Cada $weeks semanas',
                  selected: draft.everyWeeks == weeks,
                  filled: false,
                  onTap: () {
                    draft.everyWeeks = weeks;
                    form.onChanged();
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _MonthlyFields extends StatelessWidget {
  const _MonthlyFields({required this.form});

  final ScheduleForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Día del mes',
          errorText: form.errors[ScheduleInput.dayOfMonth],
          shakeCount: form.shakeCount,
          children: [
            for (var day = 1; day <= 31; day++)
              ScheduleChip(
                label: '$day',
                selected: draft.dayOfMonth == day,
                filled: false,
                onTap: () {
                  draft.dayOfMonth = day;
                  form.onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Si el mes es más corto, la entrega cae el último día.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DatesFields extends StatelessWidget {
  const _DatesFields({required this.form});

  final ScheduleForm form;

  Future<void> _add(BuildContext context) async {
    final picked = await pickFutureDate(context);
    final dates = form.draft.dates;
    if (picked == null || dates.contains(picked)) return;
    dates
      ..add(picked)
      ..sort();
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final dates = form.draft.dates;
    return AuthChoiceGroup(
      label: 'Fechas (hasta 30)',
      errorText: form.errors[ScheduleInput.dates],
      shakeCount: form.shakeCount,
      children: [
        for (final date in dates)
          ScheduleChip(
            label: formatDay(date),
            icon: AppIcons.close,
            selected: true,
            filled: false,
            onTap: () {
              dates.remove(date);
              form.onChanged();
            },
          ),
        if (dates.length < 30)
          ScheduleChip(
            label: 'Agregar fecha',
            icon: AppIcons.add,
            selected: false,
            onTap: () => _add(context),
          ),
      ],
    );
  }
}
