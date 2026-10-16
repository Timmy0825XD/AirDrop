import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';

import 'drone_glyph.dart';

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
    final enabled = onPressed != null;
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        label: isLoading ? loadingLabel : null,
        child: PressScale(
          scale: 0.98,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.fastOutSlowIn,
            width: isLoading ? height : constraints.maxWidth,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: enabled
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(isLoading ? height / 2 : 18),
            ),
            child: AbsorbPointer(
              absorbing: isLoading,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(),
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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
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
