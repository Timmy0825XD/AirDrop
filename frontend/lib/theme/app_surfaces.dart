import 'package:flutter/material.dart';

/// Las superficies de formulario de la app: la hoja (auth) y la tarjeta de
/// formulario (pantallas de trabajo) comparten el mismo fondo y los mismos
/// campos, así todo se siente una sola app.
abstract final class AppSurfaces {
  /// El fondo de una hoja o tarjeta de formulario: la superficie sólida del
  /// tema con una sombra suave. Con [lift] la sombra cae hacia arriba (hoja
  /// pegada abajo); sin él, hacia abajo (tarjeta suelta).
  static BoxDecoration sheet(
    BuildContext context, {
    required BorderRadius radius,
    bool lift = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: radius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.4 : 0.1),
          blurRadius: 24,
          offset: Offset(0, lift ? -4 : 4),
        ),
      ],
    );
  }

  /// Campos sobre una hoja: blancos con borde gris cálido en claro, gris
  /// un poco más claro que la hoja en oscuro, y el ícono se enciende con el
  /// acento al enfocarlos.
  static InputDecorationThemeData fields(ThemeData theme) {
    final colors = theme.colorScheme;
    final dark = colors.brightness == Brightness.dark;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return theme.inputDecorationTheme.copyWith(
      fillColor: dark ? colors.surfaceContainerHighest : colors.surface,
      border: border(colors.outline),
      enabledBorder: border(colors.outline),
      focusedBorder: border(colors.primary, 2),
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? colors.primary
            : colors.onSurfaceVariant,
      ),
    );
  }
}
