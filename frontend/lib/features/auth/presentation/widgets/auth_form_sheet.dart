import 'package:flutter/material.dart';

import 'auth_glass.dart';

/// La tarjeta de vidrio con el formulario, montada sobre la curva del
/// encabezado y con scroll propio (al abrir el teclado sube por encima del
/// encabezado).
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

  /// Distancia desde arriba a la que empieza la tarjeta.
  final double top;
  final Widget child;

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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, top, 16, 24 + bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AuthGlassPanel(child: child),
          ),
        ),
      ),
    );
  }
}
