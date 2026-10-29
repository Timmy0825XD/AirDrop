import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/glass_icon_button.dart';
import '../../order_format.dart';

/// [date] corrido [days] días.
String shiftIsoDate(String date, int days) =>
    isoDate(DateTime.parse(date).add(Duration(days: days)));

/// El día de la agenda: el anterior, el siguiente y tocar la fecha abre
/// el calendario.
class AgendaDayBar extends StatelessWidget {
  const AgendaDayBar({
    super.key,
    required this.date,
    required this.onChanged,
    required this.onPick,
  });

  /// `AAAA-MM-DD`.
  final String date;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = date == todayIso();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Día anterior',
            onPressed: () => onChanged(shiftIsoDate(date, -1)),
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      today ? 'HOY' : 'AGENDA',
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      formatLongDate(date),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Día siguiente',
            onPressed: () => onChanged(shiftIsoDate(date, 1)),
          ),
        ],
      ),
    );
  }
}
