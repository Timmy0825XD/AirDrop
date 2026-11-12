import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/widgets/drone_mark.dart';

/// La ruta de la misión, de la central al destino, como una barra: lo
/// recorrido en el acento y la ficha del dron encima. Con [progress] (0 a
/// 1, sale de la telemetría) el dron va en su punto real; sin él, queda en
/// medio y sube y baja despacio, para decir "va en camino" sin inventar la
/// posición.
class MissionRoute extends StatefulWidget {
  const MissionRoute({super.key, required this.endLabel, this.progress});

  final String endLabel;
  final double? progress;

  @override
  State<MissionRoute> createState() => _MissionRouteState();
}

class _MissionRouteState extends State<MissionRoute>
    with SingleTickerProviderStateMixin {
  late final _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    still ? _hover.stop() : _hover.repeat();
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, box) => AnimatedBuilder(
              animation: _hover,
              builder: (context, _) => _Track(
                width: box.maxWidth,
                progress: widget.progress,
                bob: widget.progress == null
                    ? 3 * math.sin(_hover.value * 2 * math.pi)
                    : 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Central', style: style),
            const Spacer(),
            Flexible(
              child: Text(
                widget.endLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// La barra, sus extremos y el dron en [progress] (o en medio).
class _Track extends StatelessWidget {
  const _Track({
    required this.width,
    required this.progress,
    required this.bob,
  });

  static const double _drone = 30;

  final double width;
  final double? progress;
  final double bob;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final at = (progress ?? 0.5).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        _Bar(width: width, color: colors.outline.withValues(alpha: 0.5)),
        _Bar(width: width * at, color: colors.primary),
        _End(color: colors.primary, filled: true),
        Positioned(right: 0, child: _End(color: colors.onSurface)),
        Positioned(
          left: (width - _drone) * at,
          top: (40 - _drone) / 2 + bob,
          child: const DroneMark(size: _drone),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
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
