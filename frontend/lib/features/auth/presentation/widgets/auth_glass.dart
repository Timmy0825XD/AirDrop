import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../theme/app_surfaces.dart';

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
      decoration: AppSurfaces.sheet(
        context,
        radius: const BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Theme(
        data: theme.copyWith(inputDecorationTheme: AppSurfaces.fields(theme)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 26, 22, 24 + bottomInset),
          child: child,
        ),
      ),
    );
  }
}
