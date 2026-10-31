import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../theme/app_backdrop.dart';
import 'airspace_map.dart';

/// La salida de auth hacia el inicio. Desde el botón (ya un círculo verde)
/// se abre un círculo que deja ver el espacio aéreo, la cámara se lanza en
/// picada hacia el mapa y todo se funde en el fondo de la app, que es
/// donde empieza el inicio del rol.
///
/// Con [dive] en `false` el círculo solo deja ver el mapa inclinado, sin
/// picada ni fundido: la usa la nueva contraseña, que sigue con su propio
/// encabezado sobre el mismo mapa.
///
/// [progress] va de 0 a 1 en [duration]; en 0 no dibuja nada.
class AirspaceReveal extends StatefulWidget {
  const AirspaceReveal({
    super.key,
    required this.progress,
    required this.center,
    this.startRadius = 29,
    this.dive = true,
  });

  static const Duration duration = Duration(milliseconds: 1100);

  final Animation<double> progress;
  final Offset center;
  final double startRadius;
  final bool dive;

  @override
  State<AirspaceReveal> createState() => _AirspaceRevealState();
}

class _AirspaceRevealState extends State<AirspaceReveal> {
  late final _open = CurvedAnimation(
    parent: widget.progress,
    curve: const Interval(0, 0.45, curve: Curves.easeInOutCubic),
  );
  late final _dive = CurvedAnimation(
    parent: widget.progress,
    curve: const Interval(0.1, 1, curve: Cubic(0.7, 0, 0.2, 1)),
  );
  late final _settle = CurvedAnimation(
    parent: widget.progress,
    curve: const Interval(0.62, 1, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _open.dispose();
    _dive.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.progress,
        builder: (context, child) => widget.progress.value == 0
            ? const SizedBox.shrink()
            : ClipPath(
                clipper: _CircleClipper(
                  center: widget.center,
                  progress: _open.value,
                  startRadius: widget.startRadius,
                ),
                child: child,
              ),
        child: widget.dive
            ? Stack(
                fit: StackFit.expand,
                children: [
                  AirspaceMap(dive: _dive, focus: const Alignment(0, -0.2)),
                  FadeTransition(
                    opacity: _settle,
                    child: const AppBackdrop(child: SizedBox.expand()),
                  ),
                ],
              )
            : const AirspaceMap(focus: Alignment.center),
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper({
    required this.center,
    required this.progress,
    required this.startRadius,
  });

  final Offset center;
  final double progress;
  final double startRadius;

  @override
  Path getClip(Size size) {
    // El radio final llega a la esquina más lejana, así no queda borde.
    final far = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );
    final radius = startRadius + (far - startRadius) * progress;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.progress != progress || old.center != center;
}
