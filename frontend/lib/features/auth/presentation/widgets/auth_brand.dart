import 'package:flutter/material.dart';

import 'auth_glass.dart';

/// Alturas del encabezado curvo de auth. El login lo usa alto (con la ruta)
/// y las demás pantallas, compacto; al pasar de una a otra el encabezado
/// cambia de forma en vez de cortar.
class AuthHeaderMetrics {
  AuthHeaderMetrics._();

  static double tall(double topInset) => topInset + 284;
  static double compact(double topInset) => topInset + 124;

  /// Pasos con ícono (código, recuperación): un poco más alto que el
  /// compacto para que el ícono quede montado sobre la curva.
  static double step(double topInset) => topInset + 172;

  static const double tallCurve = 48;
  static const double compactCurve = 36;
  static const double stepCurve = 40;

  /// La tarjeta del formulario monta este tanto sobre la curva.
  static const double overlap = 28;

  /// Dónde van el logo y la pastilla, medidos desde arriba.
  static double brandTop(double topInset) => topInset + 20;
}

/// El logo sobre el encabezado: un cuadro de vidrio con el ícono. El logo
/// final aún no está definido; va un ícono provisional.
class AuthLogoTile extends StatelessWidget {
  const AuthLogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: AuthGlass.onBrand(
        radius: 14,
        child: Icon(
          Icons.route_rounded,
          size: 22,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Logo, nombre y pastilla de vidrio en la esquina del encabezado. Es la
/// versión quieta; el login anima las mismas piezas durante el splash.
class AuthBrandBar extends StatelessWidget {
  const AuthBrandBar({super.key, required this.pill});

  /// Texto de la pastilla de la derecha ("Valledupar", "Paso 1 de 2"…).
  final String pill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AuthLogoTile(),
        const SizedBox(width: 10),
        Text('AirDrop', style: authWordmarkStyle(theme)),
        const Spacer(),
        AuthPill(text: pill),
      ],
    );
  }
}

TextStyle? authWordmarkStyle(ThemeData theme) =>
    theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: 19,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );

/// Pastilla de vidrio sobre el encabezado.
class AuthPill extends StatelessWidget {
  const AuthPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthGlass.onBrand(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Botón de volver de vidrio, para las pantallas de paso (código,
/// recuperación).
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: AuthGlass.onBrand(
        radius: 14,
        child: IconButton(
          tooltip: 'Volver',
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.onPrimary,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
    );
  }
}
