import 'package:flutter/material.dart';

/// Qué cuenta la ilustración.
enum CorridorScene {
  /// Todavía no hay nada: el destino espera, sin ruta.
  empty,

  /// Algo falló: la ruta sale de la central y se corta.
  broken,

  /// La ruta completa, de la central al destino.
  route,
}

/// La ilustración del concepto Corredor: la región vista desde arriba
/// (tierra, río) y la ruta punteada entre la central y el destino.
/// Va en los estados vacíos y de error y en la bienvenida. Es decoración:
/// no muestra datos. Todos los colores salen del tema. Con [icon] lleva una
/// ficha en el centro que dice de qué se trata.
class CorridorArt extends StatelessWidget {
  const CorridorArt({
    super.key,
    this.scene = CorridorScene.empty,
    this.icon,
    this.width = 220,
  });

  final CorridorScene scene;
  final IconData? icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final broken = scene == CorridorScene.broken;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 0.6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CorridorPainter(
                  scene: scene,
                  ground: colors.primary.withValues(alpha: 0.10),
                  land: colors.surfaceContainerHighest,
                  river: colors.primary.withValues(alpha: 0.22),
                  line: colors.primary,
                  surface: colors.surface,
                ),
              ),
            ),
            if (icon != null)
              Container(
                width: width * 0.24,
                height: width * 0.24,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  icon,
                  size: width * 0.12,
                  color: broken ? colors.error : colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CorridorPainter extends CustomPainter {
  const _CorridorPainter({
    required this.scene,
    required this.ground,
    required this.land,
    required this.river,
    required this.line,
    required this.surface,
  });

  final CorridorScene scene;
  final Color ground;
  final Color land;
  final Color river;
  final Color line;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Se dibuja sobre una base de 200 × 120 y se escala al tamaño real.
    canvas.save();
    canvas.scale(size.width / 200, size.height / 120);
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 120),
      const Radius.circular(16),
    );
    canvas.clipRRect(frame);
    canvas.drawRRect(frame, Paint()..color = ground);
    _paintLand(canvas);
    _paintRoute(canvas);
    canvas.restore();
  }

  void _paintLand(Canvas canvas) {
    final hills = Path()
      ..moveTo(0, 88)
      ..cubicTo(40, 72, 62, 106, 110, 94)
      ..cubicTo(150, 84, 172, 62, 200, 74)
      ..lineTo(200, 120)
      ..lineTo(0, 120)
      ..close();
    canvas.drawPath(hills, Paint()..color = land);
    final stream = Path()
      ..moveTo(26, 0)
      ..cubicTo(40, 32, 18, 58, 42, 120);
    canvas.drawPath(
      stream,
      Paint()
        ..color = river
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
  }

  void _paintRoute(Canvas canvas) {
    const from = Offset(34, 92);
    const to = Offset(166, 30);
    final dot = Paint()..color = line;
    if (scene != CorridorScene.empty) {
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(66, 44, 124, 76, to.dx, to.dy);
      final metric = path.computeMetrics().first;
      // La ruta cortada llega solo hasta un tercio del camino.
      final end = scene == CorridorScene.broken
          ? metric.length * 0.32
          : metric.length;
      for (var d = 0.0; d < end; d += 7) {
        final at = metric.getTangentForOffset(d);
        if (at != null) canvas.drawCircle(at.position, 1.4, dot);
      }
      canvas.drawCircle(from, 6, dot);
    }
    canvas.drawCircle(to, 6, Paint()..color = surface);
    canvas.drawCircle(
      to,
      6,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_CorridorPainter old) =>
      old.scene != scene || old.line != line || old.ground != ground;
}
