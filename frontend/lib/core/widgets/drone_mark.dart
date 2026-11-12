import 'package:flutter/material.dart';

/// El dron de la marca como ficha: un círculo claro con sombra y el dron
/// dibujado con líneas (cuatro rotores, brazos en X y el núcleo del
/// acento). Es el mismo dron del logo del auth; marca el dron en el mapa,
/// en el recorrido del pedido y en los inicios.
///
/// [halo] (0 a 1) dibuja un anillo fino del acento alrededor.
class DroneMark extends StatelessWidget {
  const DroneMark({super.key, this.size = 40, this.halo = 0});

  final double size;
  final double halo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return Semantics(
      label: 'Dron de AirDrop',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? colors.onSurface : colors.surface,
          shape: BoxShape.circle,
          border: halo > 0
              ? Border.all(
                  color: colors.primary.withValues(alpha: halo),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: CustomPaint(
          size: Size.square(size * 0.62),
          painter: _DroneLines(
            frame: dark ? colors.surface : colors.onSurface,
            core: colors.primary,
          ),
        ),
      ),
    );
  }
}

/// El dron de líneas sobre una grilla de 34 × 34.
class _DroneLines extends CustomPainter {
  const _DroneLines({required this.frame, required this.core});

  final Color frame;
  final Color core;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 34);
    final stroke = Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    canvas
      ..drawLine(const Offset(11, 11), const Offset(23, 23), stroke)
      ..drawLine(const Offset(23, 11), const Offset(11, 23), stroke);
    stroke.strokeWidth = 2;
    for (final rotor in const [
      Offset(9, 9),
      Offset(25, 9),
      Offset(9, 25),
      Offset(25, 25),
    ]) {
      canvas.drawCircle(rotor, 5.5, stroke);
    }
    final body = RRect.fromLTRBR(
      12.5,
      12.5,
      21.5,
      21.5,
      const Radius.circular(3),
    );
    canvas
      ..drawRRect(body, Paint()..color = core)
      ..drawRRect(body, stroke);
  }

  @override
  bool shouldRepaint(_DroneLines old) => old.frame != frame || old.core != core;
}
