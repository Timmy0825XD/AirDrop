import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../emergency/emergency_choice_sheet.dart';
import '../../order_format.dart';

Future<T?> pickPeriodicChoice<T>(
  BuildContext context, {
  required String title,
  required String hint,
  required List<PickerOption<T>> options,
  required T? current,
}) async {
  final result = await showEmergencyChoices<T>(
    context,
    title: title,
    hint: hint,
    options: options,
    selected: {?current},
  );
  return result?.firstOrNull;
}

String periodicTimeSlot(String time) {
  final hour = int.parse(time.split(':').first);
  return '${formatTimeText(time)} – ${formatHourMinute(hour + 1, 0)}';
}

Future<int?> pickPeriodicMonthDay(BuildContext context, int? selected) =>
    showAppSheet<int>(
      context,
      builder: (_) => _MonthDaySheet(selected: selected),
    );

class _MonthDaySheet extends StatelessWidget {
  const _MonthDaySheet({required this.selected});
  final int? selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Día del mes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Si el mes es más corto, la entrega será el último día.'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var day = 1; day <= 31; day++)
                SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(16) * 2 + 24,
                  child: Semantics(
                    selected: selected == day,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(day),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.all(8),
                        backgroundColor: selected == day
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor: selected == day
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                      child: Text('$day'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
