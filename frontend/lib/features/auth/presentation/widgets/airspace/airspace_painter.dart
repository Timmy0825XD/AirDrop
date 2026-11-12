import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../theme/app_map_style.dart';
import 'airspace_traffic.dart';

/// Los colores del mapa en claro y en oscuro, sacados del tema. Imita un
/// mapa de ciudad común: tierra cálida, calles, río y parques.
@immutable
class AirspaceLook {
  const AirspaceLook({
    required this.ground,
    required this.park,
    required this.river,
    required this.road,
    required this.accent,
    required this.onAccent,
    required this.drone,
    required this.droneInk,
  });

  factory AirspaceLook.of(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final map = AppMapLook.of(colors.brightness);
    return AirspaceLook(
      ground: map.ground,
      park: map.park,
      river: map.river,
      road: map.road,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      drone: dark ? colors.onSurface : Colors.white,
      droneInk: dark ? colors.surface : colors.onSurface,
    );
  }

  final Color ground;
  final Color park;
  final Color river;
  final Color road;
  final Color accent;
  final Color onAccent;
  final Color drone;
  final Color droneInk;

  @override
  bool operator ==(Object other) =>
      other is AirspaceLook && other.ground == ground && other.accent == accent;

  @override
  int get hashCode => Object.hash(ground, accent);
}

/// Pinta el mapa: el suelo, la red de centrales y los drones.
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
    _paintNetwork(canvas, look, network.value);
    if (flying.value > 0) _paintTraffic(canvas, look, traffic, flying.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AirspacePainter old) => old.look != look;
}

final Path _river = Path()
  ..moveTo(-40, 330)
  ..cubicTo(80, 280, 140, 400, 230, 350)
  ..cubicTo(300, 310, 360, 280, 460, 320);

final List<Path> _parks = [
  Path()
    ..moveTo(250, 150)
    ..cubicTo(290, 132, 350, 146, 358, 190)
    ..cubicTo(366, 232, 318, 246, 280, 236)
    ..cubicTo(240, 226, 214, 168, 250, 150),
  Path()
    ..moveTo(30, 520)
    ..cubicTo(70, 504, 128, 516, 136, 556)
    ..cubicTo(142, 596, 100, 608, 62, 598)
    ..cubicTo(20, 588, 0, 536, 30, 520),
];

/// Avenidas (anchas) y calles (finas).
const _avenues = [
  (Offset(-400, 140), Offset(820, 100)),
  (Offset(-400, 480), Offset(820, 520)),
  (Offset(90, -400), Offset(120, 1020)),
  (Offset(270, -400), Offset(250, 1020)),
];

const _streets = [
  (Offset(-400, 40), Offset(820, 20)),
  (Offset(-400, 390), Offset(820, 370)),
  (Offset(-400, 600), Offset(820, 590)),
  (Offset(30, -400), Offset(48, 1020)),
  (Offset(180, -400), Offset(176, 1020)),
  (Offset(350, -400), Offset(336, 1020)),
];

/// El suelo con los parques, el río y las calles. Se pinta de más
/// alrededor: en la salida la cámara se acerca y no deben verse los bordes.
void _paintGround(Canvas canvas, AirspaceLook look) {
  const extra = 800.0;
  const world = airspaceWorld;
  canvas.drawRect(
    Rect.fromLTRB(-extra, -extra, world.width + extra, world.height + extra),
    Paint()..color = look.ground,
  );
  final park = Paint()..color = look.park;
  for (final path in _parks) {
    canvas.drawPath(path, park);
  }
  canvas.drawPath(
    _river,
    Paint()
      ..color = look.river
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20,
  );
  _paintRoads(canvas, _streets, look.road, 4.5);
  _paintRoads(canvas, _avenues, look.road, 9);
}

void _paintRoads(
  Canvas canvas,
  List<(Offset, Offset)> roads,
  Color color,
  double width,
) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  for (final (a, b) in roads) {
    canvas.drawLine(a, b, paint);
  }
}

/// Las rutas entre centrales, que se dibujan de punta a punta, y las
/// centrales, que aparecen una tras otra según [reveal].
void _paintNetwork(Canvas canvas, AirspaceLook look, double reveal) {
  final line = Paint()
    ..color = look.accent.withValues(alpha: 0.8)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < airspaceLinks.length; i++) {
    final p = (reveal * airspaceLinks.length - i * 0.6).clamp(0.0, 1.0);
    if (p <= 0) continue;
    final a = airspaceHubs[airspaceLinks[i].$1];
    final b = airspaceHubs[airspaceLinks[i].$2];
    canvas.drawLine(a, Offset.lerp(a, b, p)!, line);
  }
  for (var i = 0; i < airspaceHubs.length; i++) {
    final p = (reveal * airspaceHubs.length - i * 0.7).clamp(0.0, 1.0);
    if (p > 0) _paintHub(canvas, look, airspaceHubs[i], p);
  }
}

/// La central: un cuadro del acento con la cruz médica, que crece al
/// aparecer.
void _paintHub(Canvas canvas, AirspaceLook look, Offset at, double p) {
  final side = 22 * Curves.easeOutBack.transform(p);
  final box = RRect.fromRectAndRadius(
    Rect.fromCenter(center: at, width: side, height: side),
    Radius.circular(side * 0.3),
  );
  final arm = side * 0.24;
  final cross = Paint()
    ..color = look.onAccent.withValues(alpha: p)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  canvas
    ..drawRRect(box, Paint()..color = look.accent.withValues(alpha: p))
    ..drawLine(at - Offset(arm, 0), at + Offset(arm, 0), cross)
    ..drawLine(at - Offset(0, arm), at + Offset(0, arm), cross);
}

/// Cada dron: un círculo claro con su sombra y el dron de líneas encima.
void _paintTraffic(
  Canvas canvas,
  AirspaceLook look,
  AirspaceTraffic traffic,
  double alpha,
) {
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.18 * alpha)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final body = Paint()..color = look.drone.withValues(alpha: alpha);
  final ink = Paint()
    ..color = look.droneInk.withValues(alpha: alpha)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (final flight in traffic.flights) {
    final at = flight.at(flight.t);
    canvas
      ..drawCircle(at + const Offset(0, 2), 9, shadow)
      ..drawCircle(at, 9, body)
      ..drawLine(at - const Offset(3.5, 3.5), at + const Offset(3.5, 3.5), ink)
      ..drawLine(
        at + const Offset(3.5, -3.5),
        at - const Offset(3.5, -3.5),
        ink,
      );
  }
}
