import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_palette.dart';
import 'check_mark.dart';
import 'drone_glyph.dart';

/// El botón de adentro sin fondo propio: el color lo pone el contenedor.
ButtonStyle _clearStyle(BuildContext context) => ElevatedButton.styleFrom(
  padding: EdgeInsets.zero,
  shape: const RoundedRectangleBorder(),
  backgroundColor: Colors.transparent,
  foregroundColor: context.palette.onAccent,
  shadowColor: Colors.transparent,
  disabledBackgroundColor: Colors.transparent,
  disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
);

/// El fondo del botón: el acento en degradado con su halo, verde al
/// terminar bien, o apagado.
BoxDecoration _morphDecoration(
  BuildContext context,
  bool on,
  double radius, {
  bool done = false,
}) {
  final palette = context.palette;
  final glow = done ? palette.success : palette.accentGradient.first;
  return BoxDecoration(
    gradient: done
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(palette.success, Colors.white, 0.25)!,
              palette.success,
            ],
          )
        : on
        ? palette.accent
        : null,
    color: on || done
        ? null
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      if (on || done)
        BoxShadow(
          color: glow.withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
    ],
  );
}

/// Botón principal de auth. Al cargar se encoge a un círculo con el dron
/// girando; al tocarlo se hunde un 2 %. Con [onPressed] en `null` queda
/// apagado. Con [isDone] se pone verde y dibuja el check (la cuenta ya
/// entró y la pantalla va a salir hacia el inicio).
class AuthMorphButton extends StatelessWidget {
  const AuthMorphButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
    this.isDone = false,
    this.pill = false,
  });

  static const double height = 58;

  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDone;

  /// Bordes del todo redondos (auth); el resto usa el radio 16 del tema.
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final round = isLoading || isDone;
    final radius = round || pill ? height / 2 : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        label: isLoading ? loadingLabel : null,
        child: PressScale(
          scale: 0.98,
          child: AnimatedContainer(
            duration: AppMotion.of(context, const Duration(milliseconds: 480)),
            curve: AppMotion.enterCurve,
            width: round ? height : constraints.maxWidth,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: _morphDecoration(
              context,
              enabled,
              radius,
              done: isDone,
            ),
            child: AbsorbPointer(
              absorbing: round,
              child: ElevatedButton(
                onPressed: onPressed,
                style: _clearStyle(context),
                child: _ButtonFace(button: this),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cambia el texto por el dron o el check, con fundido y escala.
class _ButtonFace extends StatelessWidget {
  const _ButtonFace({required this.button});

  final AuthMorphButton button;

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
      child: button.isDone
          ? _DrawnCheck(key: const ValueKey('done'), color: onPrimary)
          : button.isLoading
          ? SpinningDrone(key: const ValueKey('loading'), color: onPrimary)
          : FittedBox(
              key: ValueKey(button.label),
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(button.label),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
    );
  }
}

/// El check que se dibuja de punta a punta al terminar bien.
class _DrawnCheck extends StatelessWidget {
  const _DrawnCheck({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 340)),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: const Size.square(30),
        painter: CheckMarkPainter(progress: t, color: color, strokeWidth: 3),
      ),
    );
  }
}
