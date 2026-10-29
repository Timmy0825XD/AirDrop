import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../core/widgets/form_bottom_sheet.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Elige la nueva franja de una entrega: el mismo día o el siguiente, a
/// una hora en punto entre 07:00 y 17:00. Devuelve `(fecha, hora)` o
/// `null` si se cierra.
Future<(String, String)?> showRescheduleSheet(
  BuildContext context, {
  required List<String> dates,
  String? initialTime,
}) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => RescheduleSheet(dates: dates, initialTime: initialTime),
  );
}

class RescheduleSheet extends StatefulWidget {
  const RescheduleSheet({super.key, required this.dates, this.initialTime});

  final List<String> dates;
  final String? initialTime;

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late String? _date = widget.dates.firstOrNull;
  late String _time = widget.initialTime ?? slotTimes.first;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelSmall;
    return FormBottomSheet(
      title: 'Mover la entrega',
      subtitle: 'Mover la entrega la confirma.',
      saveLabel: 'Mover',
      onSave: () {
        if (_date != null) Navigator.of(context).pop((_date!, _time));
      },
      children: [
        Text('DÍA', style: label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final date in widget.dates)
              ChoicePill(
                label: formatLongDate(date),
                selected: _date == date,
                onTap: () => setState(() => _date = date),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('HORA', style: label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final time in slotTimes)
              ChoicePill(
                label: time,
                selected: _time == time,
                filled: false,
                onTap: () => setState(() => _time = time),
              ),
          ],
        ),
      ],
    );
  }
}
