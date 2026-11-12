import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'drone_mark.dart';

/// El dron sobre el mapa: la ficha del dron de la marca apuntando hacia
/// donde va ([heading], en radianes desde el norte) y un anillo suave que
/// late debajo. Con "reducir movimiento" el anillo queda quieto.
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
    duration: const Duration(milliseconds: 2200),
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
    final accent = Theme.of(context).colorScheme.primary;
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
                width: 40 + 32 * t,
                height: 40 + 32 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.22 * (1 - t)),
                ),
              );
            },
          ),
          Transform.rotate(
            angle: widget.heading,
            child: const DroneMark(size: 42),
          ),
        ],
      ),
    );
  }
}

/// La central de origen sobre el mapa: un cuadro del acento con la cruz
/// médica, como en el mapa del login.
class HubMarker extends StatelessWidget {
  const HubMarker({super.key});

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Central de origen',
      child: Container(
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, size: 22, color: colors.onPrimary),
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
