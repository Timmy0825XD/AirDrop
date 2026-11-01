import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// La pieza base del diseño: vidrio translúcido con borde fino. Con
/// [onTap] se hunde al tocar; con [blur] desenfoca lo de atrás (solo sobre
/// el mapa o una imagen: sobre el fondo plano no se nota y cuesta GPU).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.onTap,
    this.blur = false,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool blur;

  /// Vidrio casi opaco (barra flotante, paneles sobre el mapa).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = BorderRadius.circular(radius);
    // En oscuro la sombra se vería a través del vidrio y lo ensuciaría:
    // solo la llevan el vidrio fuerte y el modo claro.
    final light = Theme.of(context).brightness == Brightness.light;
    // En oscuro el vidrio lleva luz arriba y se apaga hacia abajo, como un
    // panel iluminado desde el techo; en claro y el fuerte, color parejo.
    final lit = !strong && !light;
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: lit ? null : (strong ? palette.bar : palette.glass),
        gradient: lit
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.glass,
                  palette.glass.withValues(alpha: palette.glass.a * 0.4),
                ],
              )
            : null,
        borderRadius: shape,
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          if (strong || light)
            BoxShadow(
              color: palette.shadow,
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
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
