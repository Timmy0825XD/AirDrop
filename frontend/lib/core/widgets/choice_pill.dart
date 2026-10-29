import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// Chip redondo que se elige con un toque: tipo de central, centrales de
/// una cuenta, filtros. Elegido, se pinta de marca ([filled]) o se tiñe
/// con un borde de marca; el cambio se funde y se hunde al tocarlo.
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
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Elegido, muestra un check antes del texto.
  final bool showCheck;

  /// `true`: elegido va relleno de marca. `false`: tinte suave y borde.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = !selected
        ? colors.onSurface
        : (filled ? colors.onPrimary : colors.primary);
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        scale: 0.95,
        child: GestureDetector(
          onTap: onTap,
          child: _PillBox(
            selected: selected,
            filled: filled,
            child: _PillFace(
              label: label,
              color: ink,
              icon: showCheck && selected ? Icons.check_rounded : icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// El fondo y el borde del chip, que se funden al elegirlo.
class _PillBox extends StatelessWidget {
  const _PillBox({
    required this.selected,
    required this.filled,
    required this.child,
  });

  final bool selected;
  final bool filled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final fill = !selected
        ? palette.glass
        : (filled ? colors.primary : colors.primary.withValues(alpha: 0.14));
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.quick),
      curve: AppMotion.enterCurve,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? colors.primary : palette.glassBorder,
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class _PillFace extends StatelessWidget {
  const _PillFace({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: icon == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(icon, size: 16, color: color),
                ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontSize: 13, color: color),
        ),
      ],
    );
  }
}
