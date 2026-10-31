import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../theme/app_palette.dart';
import 'airspace_traffic.dart';

/// Los colores del plano en claro y en oscuro, sacados del tema.
@immutable
class AirspaceLook {
  const AirspaceLook({
    required this.ground,
    required this.river,
    required this.road,
    required this.accent,
    required this.trail,
    required this.hubFill,
    required this.dot,
    required this.ring,
  });

  factory AirspaceLook.of(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final dark = colors.brightness == Brightness.dark;
    final accent = colors.primary;
    return AirspaceLook(
      ground: dark
          ? palette.backdrop.last
          : Color.lerp(palette.backdrop[0], palette.backdrop[1], 0.55)!,
      river: dark
          ? palette.info.withValues(alpha: 0.14)
          : Color.lerp(palette.info, Colors.white, 0.7)!.withValues(alpha: 0.7),
      road: Colors.white.withValues(alpha: dark ? 0.06 : 1),
      accent: accent,
      trail: Color.lerp(accent, Colors.white, dark ? 0.3 : 0.08)!,
      hubFill: dark ? palette.backdrop[1] : Colors.white,
      dot: colors.onSurface,
      ring: palette.success,
    );
  }

  final Color ground;
  final Color river;
  final Color road;
  final Color accent;
  final Color trail;
  final Color hubFill;
  final Color dot;
  final Color ring;

  @override
  bool operator ==(Object other) =>
      other is AirspaceLook && other.ground == ground && other.accent == accent;

  @override
  int get hashCode => Object.hash(ground, accent);
}

/// Pinta el plano: el suelo, la red de centrales y el tráfico.
class AirspacePainter extends CustomPainter {
  AirspacePainter({
    required this.look,
    required this.traffic,
    required this.network,
    required this.flying,
    required this.clock,
  }) : super(repaint: Listenable.merge([network, flying, clock]));

  final AirspaceLook look;
  final AirspaceTraffic traffic;
  final Animation<double> network;
  final Animation<double> flying;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    const world = airspaceWorld;
    final cover = math.max(
      size.width / world.width,
      size.height / world.height,
    );
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(cover * 1.05)
      ..translate(-world.width / 2, -world.height / 2);
    _paintGround(canvas, look);
    _paintNetwork(canvas, look, network.value, clock.value);
    if (flying.value > 0) _paintTraffic(canvas, look, traffic, flying.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AirspacePainter old) => old.look != look;
}

final Path _river = Path()
  ..moveTo(-20, 330)
  ..cubicTo(80, 280, 140, 400, 230, 350)
  ..cubicTo(300, 310, 360, 280, 440, 320);

const _roads = [
  (Offset(-400, 140), Offset(820, 140)),
  (Offset(-400, 480), Offset(820, 480)),
  (Offset(90, -400), Offset(90, 1020)),
  (Offset(260, -400), Offset(260, 1020)),
  (Offset(-400, 845), Offset(820, 225)),
];

/// El suelo con su grilla, el río y las calles. Se pinta de más alrededor:
/// al inclinarse, el plano deja ver los bordes.
void _paintGround(Canvas canvas, AirspaceLook look) {
  const extra = 800.0;
  const world = airspaceWorld;
  canvas.drawRect(
    Rect.fromLTRB(-extra, -extra, world.width + extra, world.height + extra),
    Paint()..color = look.ground,
  );
  final grid = Paint()
    ..color = look.accent.withValues(alpha: 0.07)
    ..strokeWidth = 1;
  for (var v = -extra + 4; v <= world.height + extra; v += 28) {
    canvas
      ..drawLine(Offset(v, -extra), Offset(v, world.height + extra), grid)
      ..drawLine(Offset(-extra, v), Offset(world.width + extra, v), grid);
  }
  canvas.drawPath(
    _river,
    Paint()
      ..color = look.river
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18,
  );
  final road = Paint()
    ..color = look.road
    ..strokeWidth = 4;
  for (final (a, b) in _roads) {
    canvas.drawLine(a, b, road);
  }
}

/// Las líneas punteadas entre centrales (con un pulso que las recorre) y
/// las centrales, que se encienden una tras otra según [reveal].
void _paintNetwork(
  Canvas canvas,
  AirspaceLook look,
  double reveal,
  double seconds,
) {
  final line = Paint()
    ..color = look.accent.withValues(alpha: 0.35 * reveal.clamp(0, 1))
    ..strokeWidth = 1.2;
  final pulse = Paint()..color = look.accent.withValues(alpha: 0.9);
  for (var i = 0; i < airspaceLinks.length; i++) {
    final p = (reveal * airspaceLinks.length - i * 0.6).clamp(0.0, 1.0);
    if (p <= 0) continue;
    final a = airspaceHubs[airspaceLinks[i].$1];
    final b = airspaceHubs[airspaceLinks[i].$2];
    _dashed(canvas, a, Offset.lerp(a, b, p)!, line);
    if (p >= 1) {
      final k = (seconds / 1.6 + i * 0.23) % 1;
      canvas.drawCircle(Offset.lerp(a, b, k)!, 1.6, pulse);
    }
  }
  for (var i = 0; i < airspaceHubs.length; i++) {
    final p = (reveal * airspaceHubs.length - i * 0.7).clamp(0.0, 1.0);
    if (p > 0) {
      _paintHub(canvas, look, airspaceHubs[i], p, (seconds + i * 0.4) % 2 / 2);
    }
  }
}

/// La central: un cuadro con la cruz médica y una onda que se expande.
void _paintHub(
  Canvas canvas,
  AirspaceLook look,
  Offset at,
  double p,
  double wave,
) {
  canvas.drawCircle(
    at,
    6 + wave * 26,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = look.accent.withValues(alpha: 0.55 * (1 - wave) * p),
  );
  final box = RRect.fromRectAndRadius(
    Rect.fromCenter(center: at, width: 18, height: 18),
    const Radius.circular(5),
  );
  final ink = look.accent.withValues(alpha: p);
  final cross = Paint()
    ..color = ink
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas
    ..drawRRect(box, Paint()..color = look.hubFill.withValues(alpha: p))
    ..drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ink,
    )
    ..drawLine(at - const Offset(4, 0), at + const Offset(4, 0), cross)
    ..drawLine(at - const Offset(0, 4), at + const Offset(0, 4), cross);
}

/// Cada dron con su estela que se afina hacia atrás, su brillo y su
/// destino; y los anillos de los que acaban de llegar.
void _paintTraffic(
  Canvas canvas,
  AirspaceLook look,
  AirspaceTraffic traffic,
  double alpha,
) {
  const segments = 14;
  final trail = Paint()..strokeCap = StrokeCap.round;
  for (final flight in traffic.flights) {
    final start = math.max(0.0, flight.t - 0.28);
    for (var i = 0; i < segments; i++) {
      final k = i / segments;
      trail
        ..color = look.trail.withValues(alpha: alpha * 0.8 * k)
        ..strokeWidth = 2.4 * k + 0.4;
      canvas.drawLine(
        flight.at(start + (flight.t - start) * k),
        flight.at(start + (flight.t - start) * (i + 1) / segments),
        trail,
      );
    }
    _paintDrone(canvas, look, flight, alpha);
  }
  for (final ring in traffic.rings) {
    canvas.drawCircle(
      ring.at,
      4 + ring.age * 20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = look.ring.withValues(alpha: 0.8 * (1 - ring.age) * alpha),
    );
  }
}

void _paintDrone(
  Canvas canvas,
  AirspaceLook look,
  AirspaceFlight flight,
  double alpha,
) {
  final at = flight.at(flight.t);
  canvas
    ..drawCircle(
      at,
      12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            look.trail.withValues(alpha: 0.55 * alpha),
            look.trail.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: at, radius: 12)),
    )
    ..drawCircle(at, 2.6, Paint()..color = look.dot.withValues(alpha: alpha))
    ..drawCircle(
      flight.to,
      3,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = look.dot.withValues(alpha: 0.3 * alpha),
    );
}

/// Línea punteada de 3 por 6, como una ruta planeada.
void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
  final length = (b - a).distance;
  if (length == 0) return;
  final step = (b - a) / length;
  for (var d = 0.0; d < length; d += 9) {
    canvas.drawLine(a + step * d, a + step * math.min(d + 3, length), paint);
  }
}
