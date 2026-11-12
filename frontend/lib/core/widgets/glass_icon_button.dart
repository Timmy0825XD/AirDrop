import 'package:flutter/material.dart';

import 'press_scale.dart';

/// Botón redondo con un ícono: volver, controles del mapa, acciones del
/// encabezado. Es la superficie del tema con una sombra corta y se hunde
/// al tocarlo. Con [active] se pinta con el acento (seguir al dron
/// encendido, por ejemplo).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.size = 44,
  });

  const GlassIconButton.back({
    super.key,
    required this.onPressed,
    this.size = 44,
  }) : icon = Icons.arrow_back_ios_new_rounded,
       tooltip = 'Volver',
       active = false;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return PressScale(
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.4 : 0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            color: active ? colors.onPrimary : colors.onSurface,
            icon: Icon(icon, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}
