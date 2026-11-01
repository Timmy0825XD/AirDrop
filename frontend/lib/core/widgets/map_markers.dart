import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'drone_mark.dart';

/// El dron sobre el mapa: el dron de la marca visto desde arriba, con
/// las hélices girando, apuntando hacia donde va ([heading], en radianes
/// desde el norte) y un halo que late debajo. Con "reducir movimiento" el
/// halo queda quieto.
class DroneMarker extends StatefulWidget {
  const DroneMarker({super.key, this.heading = 0});

  static const double size = 72;

  final double heading;

  @override
  State<DroneMarker> createState() => _DroneMarkerState();
}

class _DroneMarkerState extends State<DroneMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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
    final glow = context.palette.accentGradient.first;
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
                width: 30 + 42 * t,
                height: 30 + 42 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: glow.withValues(alpha: 0.7 * (1 - t)),
                    width: 1.5,
                  ),
                  color: glow.withValues(alpha: 0.12 * (1 - t)),
                ),
              );
            },
          ),
          _DroneBody(heading: widget.heading, glow: glow),
        ],
      ),
    );
  }
}

/// El disco oscuro con brillo del acento y el dron girado hacia su rumbo.
class _DroneBody extends StatelessWidget {
  const _DroneBody({required this.heading, required this.glow});

  final double heading;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.backdrop.last.withValues(alpha: 0.85),
        border: Border.all(color: glow.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: 16),
        ],
      ),
      child: Transform.rotate(
        angle: heading,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: DroneMark(size: 34),
        ),
      ),
    );
  }
}

/// La central de origen sobre el mapa: un cuadro de vidrio con la cruz
/// médica y el borde del acento, como en el plano del login.
class HubMarker extends StatelessWidget {
  const HubMarker({super.key});

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Central de origen',
      child: Container(
        decoration: BoxDecoration(
          color: palette.bar,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: 1.5),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12),
          ],
        ),
        child: Icon(Icons.add_rounded, size: 20, color: accent),
      ),
    );
  }
}

/// El destino: un blanco de anillos con una onda que se expande.
class TargetMarker extends StatelessWidget {
  const TargetMarker({super.key});

  static const double size = 46;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'Destino',
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.bar,
              border: Border.all(color: ink, width: 2.5),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
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
