import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// Botón cuadrado de vidrio con un ícono: volver, controles del mapa,
/// acciones del encabezado. Se hunde al tocarlo. Con [active] se pinta con
/// el acento (seguir al dron encendido, por ejemplo).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.size = 46,
  });

  const GlassIconButton.back({
    super.key,
    required this.onPressed,
    this.size = 46,
  }) : icon = Icons.arrow_back_rounded,
       tooltip = 'Volver',
       active = false;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = active
        ? palette.onAccent
        : Theme.of(context).colorScheme.onSurface;
    return PressScale(
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? null : palette.bar,
          gradient: active ? palette.accent : null,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: palette.glassBorder),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            color: ink,
            icon: Icon(icon, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}
