import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';

/// Bloque de marca con el borde inferior curvo: el acento turquesa en
/// degradado, una luz suave arriba, la trama de puntos y un filo de luz en
/// la curva, como el borde de un vidrio.
///
/// La altura y la profundidad de la curva llegan desde afuera para poder
/// animarlas: en el splash cubre toda la pantalla ([curve] en 0) y después
/// se encoge hasta ser el encabezado del formulario. Solo cambia el
/// recorte, así que el GPU no repinta el contenido en cada cuadro.
class AuthCurvedHeader extends StatelessWidget {
  const AuthCurvedHeader({
    super.key,
    required this.height,
    required this.curve,
  });

  final double height;
  final double curve;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = Theme.of(context).colorScheme.onPrimary;
    return CustomPaint(
      foregroundPainter: _RimPainter(height: height, curve: curve, color: ink),
      child: ClipPath(
        clipper: _CurvedBottomClipper(height: height, curve: curve),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.accent),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.9),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _DotsPainter(ink.withValues(alpha: 0.12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Path _curvedPath(Size size, double height, double curve) {
  final bottom = Radius.elliptical(size.width / 2, curve);
  return Path()..addRRect(
    RRect.fromLTRBAndCorners(
      0,
      0,
      size.width,
      height.clamp(0, size.height),
      bottomLeft: bottom,
      bottomRight: bottom,
    ),
  );
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  const _CurvedBottomClipper({required this.height, required this.curve});

  final double height;
  final double curve;

  @override
  Path getClip(Size size) => _curvedPath(size, height, curve);

  @override
  bool shouldReclip(_CurvedBottomClipper old) =>
      old.height != height || old.curve != curve;
}

/// El filo de luz sobre la curva: más fuerte al centro y se apaga hacia
/// los lados.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.height,
    required this.curve,
    required this.color,
  });

  final double height;
  final double curve;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (curve <= 0 || height >= size.height) return;
    final top = (height - curve * 2).clamp(0.0, size.height);
    final rect = Rect.fromLTRB(0, top, size.width, height);
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawPath(
      _curvedPath(size, height, curve),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.height != height || old.curve != curve || old.color != color;
}

/// Trama de puntos muy suave, la textura del encabezado.
class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 2.0; y < size.height; y += 18) {
      for (var x = 2.0; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
