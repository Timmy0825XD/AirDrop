import 'package:flutter/material.dart';

import 'auth_glass.dart';
import 'drone_glyph.dart';

/// Alturas del encabezado de auth. El login lo usa alto, las pantallas de
/// paso medio y el registro compacto; al pasar de una a otra el encabezado
/// cambia de forma en vez de cortar. El alto y el de paso crecen con la
/// pantalla: en un teléfono largo el mapa ocupa más y la hoja no queda
/// vacía.
class AuthHeaderMetrics {
  AuthHeaderMetrics._();

  static double tallOf(BuildContext context) => _grow(context, 0.38, 284, 400);
  static double compact(double topInset) => topInset + 124;

  /// Pasos (código, recuperación): el dron con el ícono va en el mapa.
  static double stepOf(BuildContext context) => _grow(context, 0.34, 270, 350);

  static double _grow(
    BuildContext context,
    double share,
    double min,
    double max,
  ) {
    final size = MediaQuery.sizeOf(context);
    final inset = MediaQuery.paddingOf(context).top;
    return inset + (size.height * share).clamp(min, max);
  }

  // El recorte usa el 75 %: las esquinas de abajo quedan en unos 28 px.
  static const double tallCurve = 38;
  static const double compactCurve = 38;
  static const double stepCurve = 38;

  /// La hoja del formulario monta este tanto sobre el encabezado.
  static const double overlap = 28;

  /// Dónde van el logo y la pastilla, medidos desde arriba.
  static double brandTop(double topInset) => topInset + 20;
}

/// El logo: el dron de líneas dentro de un círculo claro con sombra, como
/// una ficha sobre el mapa. El logo final aún no está definido; este es el
/// provisional.
class AuthLogoTile extends StatelessWidget {
  const AuthLogoTile({super.key});

  static const double size = 42;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return Semantics(
      label: 'Logo de AirDrop',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? colors.onSurface : colors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.16),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: DroneGlyph(
          color: dark ? colors.surface : colors.onSurface,
          size: size * 0.62,
        ),
      ),
    );
  }
}

/// Logo y nombre en la esquina del encabezado. Es la versión quieta; el
/// login anima las mismas piezas durante la entrada.
class AuthBrandBar extends StatelessWidget {
  const AuthBrandBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AuthLogoTile(),
        const SizedBox(width: 12),
        Text('AirDrop', style: authWordmarkStyle(theme)),
      ],
    );
  }
}

/// El título de cada pantalla de auth: 28, negrita y tracking un poco
/// cerrado.
TextStyle? authTitleStyle(ThemeData theme) => theme.textTheme.headlineLarge
    ?.copyWith(fontSize: 28, letterSpacing: -0.5, height: 1.15);

TextStyle? authWordmarkStyle(ThemeData theme) =>
    theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );

/// Pastilla sobre el mapa, con un ícono opcional.
class AuthPill extends StatelessWidget {
  const AuthPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthChrome(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de volver redondo sobre el mapa, para las pantallas de paso
/// (código, recuperación).
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: AuthChrome(
        child: IconButton(
          tooltip: 'Volver',
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.onSurface,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
    );
  }
}
