import 'package:flutter/material.dart';

import '../../../../core/widgets/drone_mark.dart';
import 'auth_glass.dart';

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

  static const double tallCurve = 48;
  static const double compactCurve = 36;
  static const double stepCurve = 40;

  /// La hoja del formulario monta este tanto sobre el encabezado.
  static const double overlap = 28;

  /// Dónde van el logo y la pastilla, medidos desde arriba.
  static double brandTop(double topInset) => topInset + 20;
}

/// El logo: el dron de la marca visto desde arriba, con las hélices
/// girando. El logo final aún no está definido; este es el provisional.
class AuthLogoTile extends StatelessWidget {
  const AuthLogoTile({super.key});

  static const double size = 40;

  @override
  Widget build(BuildContext context) =>
      const DroneMark(size: AuthLogoTile.size);
}

/// Logo, nombre y pastilla de vidrio en la esquina del encabezado. Es la
/// versión quieta; el login anima las mismas piezas durante la entrada.
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

/// El título de cada pantalla de auth: 32 con el tracking cerrado, como los
/// títulos grandes de iOS.
TextStyle? authTitleStyle(ThemeData theme) =>
    theme.textTheme.headlineLarge?.copyWith(letterSpacing: -1, height: 1.1);

TextStyle? authWordmarkStyle(ThemeData theme) =>
    theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );

/// Pastilla de vidrio sobre el mapa, con un punto de ubicación.
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

/// Botón de volver de vidrio, para las pantallas de paso (código,
/// recuperación).
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
