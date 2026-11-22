import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../order_format.dart';

String shiftIsoDate(String date, int days) {
  final day = DateTime.parse(date);
  return isoDate(DateTime.utc(day.year, day.month, day.day + days));
}

/// Selección del día y calendario, con tres fechas cuando el texto necesita espacio.
class AgendaDayBar extends StatelessWidget {
  const AgendaDayBar({
    super.key,
    required this.date,
    required this.onChanged,
    required this.onPick,
  });
  final String date;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DayNavigation(date: date, onChanged: onChanged, onPick: onPick),
      const SizedBox(height: 12),
      _AgendaDays(date: date, onChanged: onChanged),
      if (date != todayIso())
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => onChanged(todayIso()),
            child: const Text('Volver a hoy'),
          ),
        ),
    ],
  );
}

class _AgendaDays extends StatelessWidget {
  const _AgendaDays({required this.date, required this.onChanged});
  final String date;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact =
          box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final radius = compact ? 1 : 2;
      return Row(
        children: [
          for (var offset = -radius; offset <= radius; offset++) ...[
            if (offset > -radius) const SizedBox(width: 8),
            Expanded(
              child: _DayButton(
                date: shiftIsoDate(date, offset),
                selected: offset == 0,
                onTap: () => onChanged(shiftIsoDate(date, offset)),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _DayNavigation extends StatelessWidget {
  const _DayNavigation({
    required this.date,
    required this.onChanged,
    required this.onPick,
  });
  final String date;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Día anterior',
        icon: const Icon(AppIcons.back),
        onPressed: () => onChanged(shiftIsoDate(date, -1)),
      ),
      Expanded(
        child: TextButton.icon(
          onPressed: onPick,
          icon: const Icon(AppIcons.calendar, size: 20),
          label: Text(
            capitalized(formatDay(date, relative: false)),
            textAlign: TextAlign.center,
          ),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size(0, 48),
          ),
        ),
      ),
      IconButton(
        tooltip: 'Día siguiente',
        icon: const Icon(AppIcons.forward),
        onPressed: () => onChanged(shiftIsoDate(date, 1)),
      ),
    ],
  );
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.date,
    required this.selected,
    required this.onTap,
  });
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      label: capitalized(formatDay(date, relative: false)),
      excludeSemantics: true,
      onTap: onTap,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          backgroundColor: selected ? colors.primary : colors.surface,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
        ),
        child: _DayLabel(date: date, color: color),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date, required this.color});
  final String date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = capitalized(
      formatDay(date, relative: false).split(' ').first,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          date == todayIso() ? 'Hoy' : weekday,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        const SizedBox(height: 6),
        Text(
          '${DateTime.parse(date).day}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
