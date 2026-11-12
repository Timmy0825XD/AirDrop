import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// La tarjeta base de la app: la superficie sólida del tema con una sombra
/// suave en claro y un filo fino en oscuro (en oscuro la sombra no se ve).
/// Con [onTap] se hunde al tocar; con [blur] desenfoca lo de atrás (solo
/// sobre el mapa). El nombre viene del diseño anterior, que era de vidrio.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.blur = false,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool blur;

  /// Panel sobre el mapa: lleva la sombra también en oscuro.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = BorderRadius.circular(radius);
    final light = Theme.of(context).brightness == Brightness.light;
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: strong ? palette.bar : palette.glass,
        borderRadius: shape,
        border: light ? null : Border.all(color: palette.glassBorder),
        boxShadow: [
          if (light || strong) ...[
            BoxShadow(
              color: palette.shadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: palette.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (blur) {
      card = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: card,
        ),
      );
    }
    return onTap == null ? card : PressScale(child: card);
  }
}
