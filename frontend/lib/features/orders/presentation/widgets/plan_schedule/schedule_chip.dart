import 'package:flutter/material.dart';

/// Selección que crece con el texto y mantiene el acento compartido.
class ScheduleChip extends StatelessWidget {
  const ScheduleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.filled = true,
    this.icon,
  });
  final String label;
  final bool selected, filled;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
      selectedColor: colors.primary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurface,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
