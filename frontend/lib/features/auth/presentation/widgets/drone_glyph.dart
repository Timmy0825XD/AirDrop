import 'package:flutter/material.dart';

/// El dron de AirDrop dibujado a mano: cuatro rotores, brazos en X y el
/// núcleo naranja de señal. Se usa en la ruta del splash y en el botón
/// mientras carga.
class DroneGlyph extends StatelessWidget {
  const DroneGlyph({super.key, required this.color, this.size = 34});

  /// Color de brazos y rotores. El núcleo siempre es `colorScheme.secondary`.
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DronePainter(
        frame: color,
        core: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

/// El dron girando sobre su centro. Es el indicador de carga del botón.
class SpinningDrone extends StatefulWidget {
  const SpinningDrone({super.key, required this.color, this.size = 30});

  final Color color;
  final double size;

  @override
  State<SpinningDrone> createState() => _SpinningDroneState();
}

class _SpinningDroneState extends State<SpinningDrone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      child: DroneGlyph(color: widget.color, size: widget.size),
    );
  }
}

/// Dibuja sobre una grilla de 34 × 34 y escala al tamaño pedido.
class _DronePainter extends CustomPainter {
  const _DronePainter({required this.frame, required this.core});

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
    for (final rotor in const [
      Offset(9, 9),
      Offset(25, 9),
      Offset(9, 25),
      Offset(25, 25),
    ]) {
      canvas.drawCircle(rotor, 5.5, stroke..strokeWidth = 2);
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
  bool shouldRepaint(_DronePainter old) =>
      old.frame != frame || old.core != core;
}
