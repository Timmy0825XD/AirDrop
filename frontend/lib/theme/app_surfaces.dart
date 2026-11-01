import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Las superficies de formulario de la app: la hoja (auth) y la tarjeta de
/// formulario (pantallas de trabajo) comparten el mismo fondo y los mismos
/// campos, así todo se siente una sola app.
abstract final class AppSurfaces {
  /// El fondo de una hoja o tarjeta de formulario: en oscuro baja de
  /// grafito a casi negro y en claro de blanco a un cielo muy suave. Con
  /// [lift] la sombra cae hacia arriba (hoja pegada abajo); sin él, hacia
  /// abajo (tarjeta suelta).
  static BoxDecoration sheet(
    BuildContext context, {
    required BorderRadius radius,
    bool lift = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    final backdrop = context.palette.backdrop;
    final dark = colors.brightness == Brightness.dark;
    final edge = dark
        ? Colors.white.withValues(alpha: 0.12)
        : colors.outline.withValues(alpha: 0.5);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? [Color.lerp(backdrop[1], colors.surface, 0.35)!, backdrop.last]
            : [colors.surface, Color.lerp(colors.surface, backdrop[1], 0.6)!],
      ),
      borderRadius: radius,
      border: lift
          ? Border(top: BorderSide(color: edge, width: 0.5))
          : Border.all(color: edge, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.45 : 0.07),
          blurRadius: 40,
          offset: Offset(0, lift ? -12 : 14),
        ),
      ],
    );
  }

  /// Campos sobre una hoja: blancos con borde en claro, translúcidos en
  /// oscuro, y el ícono se enciende con el acento al enfocarlos. El vidrio
  /// del tema general se perdía sobre el blanco.
  static InputDecorationThemeData fields(ThemeData theme) {
    final colors = theme.colorScheme;
    final dark = colors.brightness == Brightness.dark;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    final rest = dark ? Colors.white.withValues(alpha: 0.09) : colors.outline;
    return theme.inputDecorationTheme.copyWith(
      fillColor: dark ? Colors.white.withValues(alpha: 0.04) : colors.surface,
      border: border(rest),
      enabledBorder: border(rest),
      focusedBorder: border(colors.primary, 1.6),
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? colors.primary
            : colors.onSurfaceVariant,
      ),
    );
  }
}
