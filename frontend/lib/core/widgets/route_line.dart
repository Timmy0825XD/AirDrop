import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'drone_mark.dart';

/// El motivo del concepto Corredor: la ruta de la central al punto de
/// entrega. Lo recorrido va en línea sólida del acento y lo que falta en
/// puntos, con la ficha del dron encima. Con [progress] (0 a 1, sale de la
/// telemetría) el dron va en su punto real. Sin él y con [hover], queda en
/// medio y sube y baja despacio, para decir "va en camino" sin inventar la
/// posición. Sin [hover] espera quieto en la central (un resumen antes de
/// pedir). Es decoración para el lector de pantalla: quien la usa dice el
/// estado en texto.
class RouteLine extends StatefulWidget {
  const RouteLine({
    super.key,
    required this.endLabel,
    this.startLabel = 'Central',
    this.progress,
    this.hover = true,
  });

  final String startLabel;
  final String endLabel;
  final double? progress;
  final bool hover;

  @override
  State<RouteLine> createState() => _RouteLineState();
}

class _RouteLineState extends State<RouteLine>
    with SingleTickerProviderStateMixin {
  late final _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool get _floats => widget.progress == null && widget.hover;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context) || !widget.hover;
    still ? _hover.stop() : _hover.repeat();
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: LayoutBuilder(
              builder: (context, box) => AnimatedBuilder(
                animation: _hover,
                builder: (context, _) => _Track(
                  width: box.maxWidth,
                  at: widget.progress ?? (widget.hover ? 0.5 : 0),
                  bob: _floats ? 3 * math.sin(_hover.value * 2 * math.pi) : 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _Ends(start: widget.startLabel, end: widget.endLabel),
        ],
      ),
    );
  }
}

/// Los nombres de los extremos, debajo de la ruta.
class _Ends extends StatelessWidget {
  const _Ends({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        Text(start, style: style),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            end,
            maxLines: 1,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// La ruta, sus extremos y el dron en [at] (0 a 1).
class _Track extends StatelessWidget {
  const _Track({required this.width, required this.at, required this.bob});

  static const double _drone = 30;

  final double width;
  final double at;
  final double bob;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = at.clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        CustomPaint(
          size: Size(width, 4),
          painter: _DotsPainter(color: colors.primary, from: width * done),
        ),
        Container(
          width: width * done,
          height: 4,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        _End(color: colors.primary, filled: true),
        Positioned(right: 0, child: _End(color: colors.primary)),
        Positioned(
          left: (width - _drone) * done,
          top: (40 - _drone) / 2 + bob,
          child: const DroneMark(size: _drone),
        ),
      ],
    );
  }
}

/// Lo que falta por volar: puntos del acento desde [from] hasta el final.
class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.color, required this.from});

  final Color color;
  final double from;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    for (var x = from + 6; x < size.width - 8; x += 8) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.from != from || old.color != color;
}

/// Un extremo de la ruta: la central (relleno) o el destino (anillo).
class _End extends StatelessWidget {
  const _End({required this.color, this.filled = false});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? color : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(filled ? 3 : 6),
        border: filled ? null : Border.all(color: color, width: 2.5),
      ),
    );
  }
}
