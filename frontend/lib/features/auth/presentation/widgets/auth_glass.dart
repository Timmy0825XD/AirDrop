import 'package:flutter/material.dart';

import '../../../../theme/app_surfaces.dart';

/// Las piezas que flotan sobre el mapa del encabezado (la pastilla,
/// volver): la superficie sólida del tema con una sombra corta, como un
/// botón sobre un mapa de verdad.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.4 : 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// La hoja del formulario: sube desde abajo pegada a los bordes, con las
/// esquinas de arriba redondeadas y una sombra suave hacia el mapa. Es la
/// superficie sólida del tema (blanca en claro, gris en oscuro).
class AuthSheetPanel extends StatelessWidget {
  const AuthSheetPanel({super.key, required this.child, this.bottomInset = 0});

  final Widget child;

  /// El área segura de abajo (la barra de gestos), para que el contenido
  /// no quede debajo.
  final double bottomInset;

  static const double radius = 28;

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
          padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
          child: child,
        ),
      ),
    );
  }
}
