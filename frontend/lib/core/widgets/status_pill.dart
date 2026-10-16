import 'package:flutter/material.dart';

/// Qué tan bien está lo que muestra la pastilla.
enum PillTone { positive, attention, negative }

/// Estado en una pastilla de color (Activa, Suspendida, Bloqueada…). El
/// color no es decorativo: distingue de un vistazo si algo puede operar.
/// Cuando cambia el texto, la pastilla nueva entra con un rebote corto.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final base = switch (tone) {
      PillTone.positive => colors.tertiary,
      PillTone.attention => colors.secondary,
      PillTone.negative => colors.error,
    };
    // El texto se oscurece (o aclara en tema oscuro) hacia la tinta para
    // que lea con contraste sobre su propio tinte.
    final ink = Color.lerp(base, colors.onSurface, 0.4)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
