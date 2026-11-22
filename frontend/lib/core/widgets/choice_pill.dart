import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// Filtro de la app con selección, foco de teclado y área táctil de 48 dp.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showCheck = false,
    this.filled = true,
  });
  final String label;
  final bool selected, showCheck, filled;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = !selected
        ? colors.onSurface
        : filled
        ? colors.onPrimary
        : colors.primary;
    return PressScale(
      scale: 0.95,
      child: ChoiceChip(
        label: _PillFace(
          label: label,
          color: ink,
          icon: showCheck && selected ? Icons.check_rounded : icon,
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        labelPadding: EdgeInsets.zero,
        shape: const StadiumBorder(),
        backgroundColor: context.palette.glass,
        selectedColor: filled
            ? colors.primary
            : colors.primary.withValues(alpha: 0.14),
        side: BorderSide(
          color: selected ? colors.primary : context.palette.glassBorder,
          width: 1.2,
        ),
      ),
    );
  }
}

class _PillFace extends StatelessWidget {
  const _PillFace({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
      ],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontSize: 13, color: color),
        ),
      ),
    ],
  );
}
