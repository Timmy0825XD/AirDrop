import 'package:flutter/material.dart';

/// Bloque de color de marca con el borde inferior curvo.
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
    final colors = Theme.of(context).colorScheme;
    return ClipPath(
      clipper: _CurvedBottomClipper(height: height, curve: curve),
      child: ColoredBox(
        color: colors.primary,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _DotsPainter(colors.onPrimary.withValues(alpha: 0.14)),
          ),
        ),
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  const _CurvedBottomClipper({required this.height, required this.curve});

  final double height;
  final double curve;

  @override
  Path getClip(Size size) {
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

  @override
  bool shouldReclip(_CurvedBottomClipper old) =>
      old.height != height || old.curve != curve;
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
