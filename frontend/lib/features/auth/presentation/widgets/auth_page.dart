import 'package:flutter/material.dart';

import 'auth_ambience.dart';

/// Andamiaje compartido por las pantallas de auth: fondo con brillo,
/// área segura y un ancho máximo legible para el formulario.
///
/// [background] reemplaza el brillo por defecto por el fondo propio de una
/// pantalla (el login usa `LoginBackdrop`); [padding] ajusta el respiradero
/// sin tocar al resto. Ambos son opcionales: el comportamiento por defecto es
/// el de siempre.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.background,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
  });

  final Widget child;
  final double maxWidth;
  final Widget? background;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: background ?? const _AuthGlowBackdrop()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: padding,
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
