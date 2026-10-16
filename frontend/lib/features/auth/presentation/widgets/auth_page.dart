import 'package:flutter/material.dart';

import 'auth_ambience.dart';

/// Andamiaje compartido por las pantallas de auth: fondo con brillo,
/// área segura y un ancho máximo legible para el formulario. El login no lo
/// usa: tiene su propio splash y encabezado curvo.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.child, this.maxWidth = 420});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _AuthGlowBackdrop()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AuthEntrance(child: child),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El brillo de siempre: centrado arriba y medio fuera de pantalla.
class _AuthGlowBackdrop extends StatelessWidget {
  const _AuthGlowBackdrop();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.translate(
        offset: const Offset(0, -60),
        child: AuthGlow(color: color),
      ),
    );
  }
}
