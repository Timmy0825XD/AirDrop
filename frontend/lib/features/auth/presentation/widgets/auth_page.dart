import 'package:flutter/material.dart';

import 'auth_ambience.dart';

/// Andamiaje compartido por las pantallas de auth: fondo con brillo,
/// área segura y un ancho máximo legible para el formulario.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(child: AuthGlow(color: colors.primary)),
            ),
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