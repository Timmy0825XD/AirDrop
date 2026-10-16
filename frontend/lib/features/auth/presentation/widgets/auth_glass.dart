import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Vidrio esmerilado: desenfoca lo que hay detrás y le pone un tinte
/// translúcido con un borde fino. Se usa con medida (la tarjeta del
/// formulario y las piezas sobre el encabezado) para no saturar.
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

  /// Vidrio sobre el encabezado de marca: blanco muy tenue.
  factory AuthGlass.onBrand({
    Key? key,
    required Widget child,
    double radius = 999,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return AuthGlass(
      key: key,
      tint: Colors.white.withValues(alpha: 0.16),
      border: Colors.white.withValues(alpha: 0.28),
      radius: radius,
      blur: 10,
      padding: padding,
      child: child,
    );
  }

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
            border: Border.all(color: border),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// La tarjeta de vidrio del formulario. En claro es casi blanca y en oscuro
/// toma la superficie del tema; la sombra es apenas perceptible.
class AuthGlassPanel extends StatelessWidget {
  const AuthGlassPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.05),
            blurRadius: 44,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: AuthGlass(
        tint: colors.surface.withValues(alpha: dark ? 0.72 : 0.80),
        border: Colors.white.withValues(alpha: dark ? 0.08 : 0.70),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: child,
      ),
    );
  }
}
