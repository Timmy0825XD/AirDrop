import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

/// La capa de pantalla de vuelo sobre los tiles del mapa: una grilla fina
/// del acento (como una mira de navegación) y un viñeteado que apaga los
/// bordes hacia el fondo de la app, así el mapa se funde con la interfaz y
/// la ruta resalta. Va entre los tiles y las rutas; no recibe toques.
class MapHudOverlay extends StatelessWidget {
  const MapHudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final dark = colors.brightness == Brightness.dark;
    final edge = dark ? palette.backdrop.last : palette.backdrop[1];
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _HudPainter(
            line: colors.primary.withValues(alpha: dark ? 0.07 : 0.06),
            edge: edge.withValues(alpha: dark ? 0.85 : 0.6),
            glow: palette.accentGlow.withValues(
              alpha: palette.accentGlow.a * (dark ? 0.8 : 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPainter extends CustomPainter {
  const _HudPainter({
    required this.line,
    required this.edge,
    required this.glow,
  });

  final Color line;
  final Color edge;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Un velo parejo apaga los tiles para que la ruta y el dron resalten.
    canvas.drawRect(
      rect,
      Paint()..color = edge.withValues(alpha: edge.a * 0.35),
    );
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Una luz del acento arriba, donde va la barra de vuelo.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, -1),
          radius: 0.9,
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(rect),
    );
    // Los bordes se apagan hacia el fondo de la app.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [edge.withValues(alpha: 0), edge],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HudPainter old) =>
      old.line != line || old.edge != edge || old.glow != glow;
}
