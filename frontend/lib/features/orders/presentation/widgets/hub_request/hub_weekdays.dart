import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../order_format.dart';
import '../plan_schedule/schedule_fields.dart';
import '../plan_schedule/schedule_values.dart';

/// Los siete días conservan su orden en una fila, con el nombre accesible.
class HubWeekdays extends StatelessWidget {
  const HubWeekdays({super.key, required this.form});
  final ScheduleForm form;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Días', style: authLabelStyle(Theme.of(context))),
      const SizedBox(height: 6),
      ShakeOnError(
        trigger: form.errors[ScheduleInput.days] == null ? 0 : form.shakeCount,
        child: Row(
          children: [
            for (var day = 1; day <= 7; day++) ...[
              if (day > 1) const SizedBox(width: 5),
              Expanded(
                child: _WeekdayButton(
                  day: day,
                  selected: form.draft.daysOfWeek.contains(day),
                  onTap: () {
                    form.draft.toggleDay(day);
                    form.onChanged();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      AuthFieldError(message: form.errors[ScheduleInput.days]),
    ],
  );
}

class _WeekdayButton extends StatelessWidget {
  const _WeekdayButton({
    required this.day,
    required this.selected,
    required this.onTap,
  });
  final int day;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: weekdayName(day),
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                const ['L', 'M', 'X', 'J', 'V', 'S', 'D'][day - 1],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
