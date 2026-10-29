import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_palette.dart';

/// El fondo de toda la app: el degradado de grafito (o de cielo, en claro)
/// con un velo de cielo arriba a la izquierda y uno turquesa abajo a la
/// derecha. Es opaco, así que una pantalla nueva tapa a la anterior.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.backdrop,
          stops: const [0, 0.48, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.2,
            colors: [palette.skyGlow, palette.skyGlow.withValues(alpha: 0)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1, 1),
              radius: 1.1,
              colors: [
                palette.accentGlow,
                palette.accentGlow.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Transición entre pantallas: la nueva sube un poco y aparece sobre su
/// propio fondo, mientras la anterior se hunde y se apaga. Con "reducir
/// movimiento" solo se funde.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final page = AppBackdrop(child: child);
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.pageCurve,
    );
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: enter, child: page);
    }
    final leave = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.pageCurve,
    );
    // Transiciones compuestas (no reconstruyen la pantalla en cada cuadro):
    // con un mapa debajo, repintar todo cada cuadro era muy pesado.
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(enter),
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 0.96).animate(leave),
          child: page,
        ),
      ),
    );
  }
}
