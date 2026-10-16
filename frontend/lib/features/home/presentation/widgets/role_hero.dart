import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/auth_brand.dart';
import '../../../auth/presentation/widgets/auth_curved_header.dart';
import '../../../auth/presentation/widgets/auth_glass.dart';
import '../../../auth/presentation/widgets/drone_glyph.dart';

/// El encabezado de un inicio rediseñado: marca, perfil y salir, la
/// pastilla del rol, el saludo y una línea de contexto. El dron de fondo
/// flota despacio. Lo usan el administrador y el despachador.
class RoleHero extends StatelessWidget {
  const RoleHero({
    super.key,
    required this.roleLabel,
    required this.firstName,
    required this.tagline,
    required this.onProfile,
    required this.onSignOut,
  });

  final String roleLabel;
  final String firstName;

  /// La línea bajo el saludo ("Así va la operación…", la central).
  final String tagline;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  static double heightFor(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 250;

  /// El primer nombre para el saludo.
  static String firstNameOf(String fullName) =>
      fullName.trim().split(RegExp(r'\s+')).first;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = heightFor(context);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: AuthCurvedHeader(height: height, curve: 40)),
          Positioned(right: -18, top: top + 64, child: const _FloatingDrone()),
          Positioned(
            left: 20,
            right: 20,
            top: top + 14,
            child: _BrandRow(onProfile: onProfile, onSignOut: onSignOut),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: top + 84,
            child: _Greeting(hero: this),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.onProfile, required this.onSignOut});

  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AuthLogoTile(),
        const SizedBox(width: 10),
        Text('AirDrop', style: authWordmarkStyle(theme)),
        const Spacer(),
        _GlassIconButton(
          tooltip: 'Perfil',
          icon: Icons.person_outline_rounded,
          onPressed: onProfile,
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          tooltip: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: AuthGlass.onBrand(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.onPrimary,
          icon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.hero});

  final RoleHero hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = theme.colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthPill(text: hero.roleLabel),
        const SizedBox(height: 12),
        Text(
          'Hola, ${hero.firstName}',
          style: theme.textTheme.headlineLarge?.copyWith(color: onBrand),
        ),
        const SizedBox(height: 4),
        Text(
          hero.tagline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onBrand.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

/// El dron de fondo, muy tenue, que se mece en un bucle lento. Con
/// "reducir movimiento" se queda quieto.
class _FloatingDrone extends StatefulWidget {
  const _FloatingDrone();

  @override
  State<_FloatingDrone> createState() => _FloatingDroneState();
}

class _FloatingDroneState extends State<_FloatingDrone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drone = Opacity(
      opacity: 0.16,
      child: DroneGlyph(
        color: Theme.of(context).colorScheme.onPrimary,
        size: 130,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return drone;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        return Transform.translate(
          offset: Offset(6 * t, -5 * t),
          child: Transform.rotate(angle: -0.14 + 0.07 * t, child: child),
        );
      },
      child: drone,
    );
  }
}
