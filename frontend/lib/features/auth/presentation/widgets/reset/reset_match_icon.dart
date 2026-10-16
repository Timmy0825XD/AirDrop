import 'package:flutter/material.dart';

/// Check verde que aparece girando con un rebote cuando la confirmación
/// coincide con la nueva contraseña.
class ResetMatchIcon extends StatelessWidget {
  const ResetMatchIcon({super.key, required this.match});

  final bool match;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.2, end: 1).animate(animation),
        child: RotationTransition(
          turns: Tween<double>(begin: -30 / 360, end: 0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: match
          ? Semantics(
              key: const ValueKey('match'),
              label: 'Las contraseñas coinciden',
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: colors.primary,
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            )
          : const SizedBox(key: ValueKey('none')),
    );
  }
}
