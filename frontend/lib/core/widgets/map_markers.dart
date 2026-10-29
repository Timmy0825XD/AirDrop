import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';

/// El dron sobre el mapa: un disco con el acento, el ícono y un halo que
/// late. Con "reducir movimiento" el halo queda quieto.
class DroneMarker extends StatefulWidget {
  const DroneMarker({super.key});

  static const double size = 64;

  @override
  State<DroneMarker> createState() => _DroneMarkerState();
}

class _DroneMarkerState extends State<DroneMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.reduced(context) ? _pulse.stop() : _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final glow = palette.accentGradient.first;
    return Semantics(
      label: 'Dron',
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = AppMotion.enterCurve.transform(_pulse.value);
              return Container(
                width: 28 + 36 * t,
                height: 28 + 36 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glow.withValues(alpha: 0.35 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: palette.accent,
              border: Border.all(color: palette.backdrop[1], width: 3),
              boxShadow: [BoxShadow(color: glow, blurRadius: 14)],
            ),
            child: Icon(
              Icons.flight_rounded,
              size: 18,
              color: palette.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un punto con nombre sobre el mapa (destino, central de origen): una
/// gota de vidrio con su ícono. Cae con rebote al aparecer.
class PlacePin extends StatelessWidget {
  const PlacePin({
    super.key,
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  static const double size = 48;

  final IconData icon;

  /// Lo que lee el lector de pantalla ("Destino").
  final String label;

  /// Con acento (el destino) o en vidrio (el origen).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight ? null : palette.bar,
            gradient: highlight ? palette.accent : null,
            border: Border.all(color: palette.glassBorder, width: 2),
            boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 12)],
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight
                ? palette.onAccent
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(width: 3, height: 10, color: palette.glassBorder),
      ],
    );
    return Semantics(
      label: label,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.of(context, AppMotion.bounce),
        curve: AppMotion.bounceCurve,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, -20 * (1 - t)),
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
        child: pin,
      ),
    );
  }
}
