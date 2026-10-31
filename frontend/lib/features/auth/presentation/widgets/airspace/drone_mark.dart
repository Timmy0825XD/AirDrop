import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../theme/app_palette.dart';

/// El dron de la marca visto desde arriba: ala, fuselaje, dos largueros con
/// cuatro hélices girando y las luces de navegación (roja a la izquierda,
/// verde a la derecha) que destellan como en un avión. En claro es grafito
/// y en oscuro, claro, para que siempre contraste con el mapa.
///
/// [halo] (0 a 1) dibuja el anillo que lo rodea en la entrada. Con
/// "reducir movimiento" las hélices y las luces quedan quietas.
class DroneMark extends StatefulWidget {
  const DroneMark({super.key, this.size = 40, this.halo = 0});

  final double size;
  final double halo;

  @override
  State<DroneMark> createState() => _DroneMarkState();
}

class _DroneMarkState extends State<DroneMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    still ? _spin.stop() : _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final dark = colors.brightness == Brightness.dark;
    return Semantics(
      label: 'Dron de AirDrop',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _DroneMarkPainter(
            spin: _spin,
            halo: widget.halo,
            body: dark ? colors.onSurface : palette.droneShell[1],
            wing: dark
                ? Color.lerp(colors.onSurface, colors.onSurfaceVariant, 0.35)!
                : palette.droneShell[0],
            boom: dark ? colors.onSurfaceVariant : palette.droneMetal[0],
            prop: Color.lerp(colors.primary, Colors.white, dark ? 0.3 : 0)!,
            accent: colors.primary,
            port: palette.danger,
            starboard: palette.success,
          ),
        ),
      ),
    );
  }
}

class _DroneMarkPainter extends CustomPainter {
  _DroneMarkPainter({
    required this.spin,
    required this.halo,
    required this.body,
    required this.wing,
    required this.boom,
    required this.prop,
    required this.accent,
    required this.port,
    required this.starboard,
  }) : super(repaint: spin);

  final Animation<double> spin;
  final double halo;
  final Color body;
  final Color wing;
  final Color boom;
  final Color prop;
  final Color accent;
  final Color port;
  final Color starboard;

  @override
  void paint(Canvas canvas, Size size) {
    // Se dibuja sobre una grilla de 160 × 160 centrada.
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.width / 160);
    final t = spin.value;

    if (halo > 0) {
      canvas.drawCircle(
        Offset.zero,
        74,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: 0.25 * halo),
      );
    }
    _paintAirframe(canvas, body: body, wing: wing, boom: boom, accent: accent);
    _paintRotors(canvas, prop, t);
    _navLight(canvas, const Offset(-70, 0), port, _flash(t));
    _navLight(canvas, const Offset(70, 0), starboard, _flash(t + 0.5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DroneMarkPainter old) =>
      old.halo != halo || old.body != body || old.prop != prop;
}

RRect _box(double l, double t, double w, double h, double r) =>
    RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(r));

/// Ala, fuselaje con la cabina y los dos largueros.
void _paintAirframe(
  Canvas canvas, {
  required Color body,
  required Color wing,
  required Color boom,
  required Color accent,
}) {
  canvas
    ..drawRRect(_box(-70, -6, 140, 12, 6), Paint()..color = wing)
    ..drawRRect(_box(-8, -40, 16, 80, 8), Paint()..color = body)
    ..drawRRect(
      _box(-4, -30, 8, 10, 3),
      Paint()..color = accent.withValues(alpha: 0.7),
    )
    ..drawRRect(_box(-40, -52, 7, 104, 3.5), Paint()..color = boom)
    ..drawRRect(_box(33, -52, 7, 104, 3.5), Paint()..color = boom);
}

const _rotors = [
  Offset(-36.5, -52),
  Offset(36.5, -52),
  Offset(-36.5, 52),
  Offset(36.5, 52),
];

/// Las cuatro hélices con su brillo; giran en pares opuestos.
void _paintRotors(Canvas canvas, Color prop, double t) {
  final blade = Paint()..color = prop.withValues(alpha: 0.75);
  for (var i = 0; i < _rotors.length; i++) {
    final at = _rotors[i];
    canvas.drawCircle(
      at,
      17,
      Paint()
        ..shader = RadialGradient(
          colors: [prop.withValues(alpha: 0.3), prop.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: at, radius: 17)),
    );
    // Unas 9 vueltas por segundo: rápido sin que el cuadro se vea al revés.
    final direction = i.isEven ? 1 : -1;
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(direction * (t * math.pi * 26 + i))
      ..drawRRect(_box(-15.5, -1.5, 31, 3, 1.5), blade)
      ..restore();
  }
}

/// Apagada casi todo el ciclo y un destello corto, como una baliza.
double _flash(double t) {
  final phase = t % 1;
  if (phase < 0.85) return 0.15;
  if (phase < 0.9) return lerpDouble(0.15, 1, (phase - 0.85) / 0.05)!;
  return lerpDouble(1, 0.15, (phase - 0.9) / 0.1)!;
}

void _navLight(Canvas canvas, Offset at, Color color, double on) {
  canvas
    ..drawCircle(
      at,
      9,
      Paint()
        ..color = color.withValues(alpha: 0.35 * on)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    )
    ..drawCircle(at, 3.5, Paint()..color = color.withValues(alpha: on));
}
