import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_palette.dart';
import 'drone_glyph.dart';

/// El fondo del botón: el acento en degradado con su halo, o apagado.
BoxDecoration _morphDecoration(BuildContext context, bool on, bool loading) {
  final palette = context.palette;
  const height = AuthMorphButton.height;
  return BoxDecoration(
    gradient: on ? palette.accent : null,
    color: on
        ? null
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(loading ? height / 2 : 16),
    boxShadow: [
      if (on)
        BoxShadow(
          color: palette.accentGradient.first.withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
    ],
  );
}

/// Botón principal de auth. Al cargar se encoge de ancho completo a un
/// círculo con el dron girando; al terminar vuelve a su forma. Al tocarlo
/// se hunde un 2 % para dar respuesta táctil. Con [onPressed] en `null`
/// queda apagado (gris) hasta que se cumpla lo que pide la pantalla.
class AuthMorphButton extends StatelessWidget {
  const AuthMorphButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
  });

  static const double height = 58;

  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final enabled = onPressed != null;
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        label: isLoading ? loadingLabel : null,
        child: PressScale(
          scale: 0.98,
          child: AnimatedContainer(
            duration: AppMotion.of(context, const Duration(milliseconds: 480)),
            curve: AppMotion.enterCurve,
            width: isLoading ? height : constraints.maxWidth,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: _morphDecoration(context, enabled, isLoading),
            child: AbsorbPointer(
              absorbing: isLoading,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: palette.onAccent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: colors.onSurfaceVariant,
                ),
                child: _ButtonFace(label: label, isLoading: isLoading),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cambia el texto por el dron con un fundido y una escala.
class _ButtonFace extends StatelessWidget {
  const _ButtonFace({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.palette.onAccent;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.fastOutSlowIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: isLoading
          ? SpinningDrone(key: const ValueKey('loading'), color: onPrimary)
          : FittedBox(
              key: ValueKey(label),
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
    );
  }
}
