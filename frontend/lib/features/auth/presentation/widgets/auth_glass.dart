import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';

/// Campos de la hoja: blancos con borde en claro, translúcidos en oscuro,
/// y el ícono se enciende con el acento al enfocarlos. El vidrio del tema
/// general se perdía sobre el blanco.
InputDecorationThemeData _sheetFields(ThemeData theme) {
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

/// El fondo de la hoja: en oscuro baja de grafito a casi negro y en claro
/// de blanco a un cielo muy suave, así una hoja larga no se ve plana.
BoxDecoration _sheetDecoration(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final backdrop = context.palette.backdrop;
  final dark = colors.brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? [Color.lerp(backdrop[1], colors.surface, 0.35)!, backdrop.last]
          : [colors.surface, Color.lerp(colors.surface, backdrop[1], 0.6)!],
    ),
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AuthSheetPanel.radius),
    ),
    border: Border(
      top: BorderSide(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : colors.outline.withValues(alpha: 0.5),
        width: 0.5,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.45 : 0.07),
        blurRadius: 40,
        offset: const Offset(0, -12),
      ),
    ],
  );
}

/// Vidrio esmerilado: desenfoca lo que hay detrás y le pone un tinte
/// translúcido con un borde fino. Se usa con medida para no saturar.
class AuthGlass extends StatelessWidget {
  const AuthGlass({
    super.key,
    required this.child,
    required this.tint,
    required this.border,
    this.radius = 28,
    this.blur = 18,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color tint;
  final Color border;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: shape,
            border: Border.all(color: border, width: 0.5),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// El vidrio de las piezas que flotan sobre el mapa del encabezado (la
/// pastilla, volver): la superficie del tema casi opaca, para que el texto
/// se lea aunque pasen drones por detrás.
class AuthChrome extends StatelessWidget {
  const AuthChrome({
    super.key,
    required this.child,
    this.radius = 999,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return AuthGlass(
      tint: colors.surface.withValues(alpha: dark ? 0.62 : 0.78),
      border: dark
          ? Colors.white.withValues(alpha: 0.12)
          : colors.outline.withValues(alpha: 0.7),
      radius: radius,
      blur: 16,
      padding: padding,
      child: child,
    );
  }
}

/// La hoja del formulario: sube desde abajo pegada a los bordes, con las
/// esquinas de arriba redondeadas y una sombra suave hacia el mapa. En
/// oscuro baja de grafito a casi negro; en claro es blanca.
class AuthSheetPanel extends StatelessWidget {
  const AuthSheetPanel({super.key, required this.child, this.bottomInset = 0});

  final Widget child;

  /// El área segura de abajo (la barra de gestos), para que el contenido
  /// no quede debajo.
  final double bottomInset;

  static const double radius = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: _sheetDecoration(context),
      child: Theme(
        data: theme.copyWith(inputDecorationTheme: _sheetFields(theme)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 26, 22, 24 + bottomInset),
          child: child,
        ),
      ),
    );
  }
}
