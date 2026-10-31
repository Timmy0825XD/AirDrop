import 'package:flutter/material.dart';

import 'airspace/airspace_map.dart';

Path _curvedPath(Size size, double height, double curve) {
  final bottom = Radius.circular(curve * 0.75);
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

/// El encabezado de auth: el espacio aéreo vivo ([AirspaceMap]) recortado
/// con las esquinas de abajo redondeadas.
///
/// La altura y el radio de la curva llegan desde afuera para poder
/// animarlos: en la entrada cubre toda la pantalla ([curve] en 0) y después
/// se encoge hasta ser el encabezado del formulario. El mapa ocupa siempre
/// la pantalla entera y solo cambia el recorte, así no se deforma.
///
/// [network], [traffic] y [tilt] pasan directo al mapa; por defecto la red
/// está encendida, los drones vuelan y el plano está inclinado.
class AuthCurvedHeader extends StatelessWidget {
  const AuthCurvedHeader({
    super.key,
    required this.height,
    required this.curve,
    this.network = kAlwaysCompleteAnimation,
    this.traffic = kAlwaysCompleteAnimation,
    this.tilt = kAlwaysCompleteAnimation,
  });

  final double height;
  final double curve;
  final Animation<double> network;
  final Animation<double> traffic;
  final Animation<double> tilt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxHeight;
        // El plano gira sobre el centro del encabezado visible.
        final focus = Alignment(0, (height / full).clamp(0.0, 1.0) - 1);
        return CustomPaint(
          foregroundPainter: _EdgePainter(
            height: height,
            curve: curve,
            color: dark
                ? Colors.white.withValues(alpha: 0.12)
                : colors.outline.withValues(alpha: 0.6),
          ),
          child: ClipPath(
            clipper: _CurvedBottomClipper(height: height, curve: curve),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AirspaceMap(
                    network: network,
                    traffic: traffic,
                    tilt: tilt,
                    focus: focus,
                  ),
                ),
                const _TopVeil(),
              ],
            ),
          ),
        );
      },
    );
  }
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

/// El filo fino del borde de abajo, para separar el mapa del fondo.
class _EdgePainter extends CustomPainter {
  const _EdgePainter({
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
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, height - curve, size.width, height + 1));
    canvas.drawPath(
      _curvedPath(size, height, curve),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.height != height || old.curve != curve || old.color != color;
}

/// Un velo arriba para que la hora y el logo se lean sobre el mapa.
class _TopVeil extends StatelessWidget {
  const _TopVeil();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final veil = (dark ? colors.surface : colors.surfaceContainerHighest)
        .withValues(alpha: 0.85);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 180,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [veil, veil.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
