import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_glass.dart';

/// La hoja con el formulario, montada sobre el borde del encabezado y con
/// scroll propio (al abrir el teclado sube por encima del encabezado). Va
/// pegada a los lados y llega hasta abajo; en pantallas anchas se centra.
///
/// Entra con [entrance]: aparece y se desplaza desde [from] hasta su sitio.
/// El login la sube desde abajo; el registro la trae de un lado. Mientras
/// entra no recibe toques.
class AuthFormSheet extends StatelessWidget {
  const AuthFormSheet({
    super.key,
    required this.entrance,
    required this.top,
    required this.child,
    this.from = const Offset(0, 72),
  });

  final Animation<double> entrance;
  final Offset from;

  /// Distancia desde arriba a la que empieza la hoja.
  final double top;
  final Widget child;

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, child) {
        final t = entrance.value;
        return IgnorePointer(
          ignoring: t < 1,
          child: Opacity(
            opacity: t.clamp(0, 1),
            child: Transform.translate(offset: from * (1 - t), child: child),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.only(top: top),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.min(_maxWidth, constraints.maxWidth),
                maxWidth: _maxWidth,
                minHeight: math.max(0, constraints.maxHeight - top),
              ),
              child: AuthSheetPanel(bottomInset: bottom, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
