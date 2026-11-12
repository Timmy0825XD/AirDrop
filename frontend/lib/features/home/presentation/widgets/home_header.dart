import 'package:flutter/material.dart';

import '../../../../core/widgets/sim_clock_badge.dart';
import '../../../notifications/presentation/widgets/notice_bell.dart';

/// El primer nombre para el saludo.
String homeFirstName(String fullName) =>
    fullName.trim().split(RegExp(r'\s+')).first;

/// El encabezado de un inicio: arriba, en gris, el rol y el contexto (la
/// central, la ciudad); debajo el saludo grande. A la derecha la campana
/// (si hay) y las iniciales, que abren el perfil. Si la consola cambió el
/// ritmo del reloj, el aviso de la simulación va debajo.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.roleLabel,
    required this.fullName,
    required this.tagline,
    required this.onProfile,
    this.onNotices,
    this.unreadNotices,
  });

  final String roleLabel;
  final String fullName;
  final String tagline;

  /// Abre el perfil (tocar las iniciales). Cerrar sesión vive allá.
  final VoidCallback onProfile;

  /// Abre la bandeja de avisos; sin él no hay campana.
  final VoidCallback? onNotices;
  final int? unreadNotices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Greeting(header: this)),
            const SizedBox(width: 12),
            if (onNotices case final open?) ...[
              NoticeBell(unread: unreadNotices, onTap: open),
              const SizedBox(width: 8),
            ],
            _Initials(name: fullName, onTap: onProfile),
          ],
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: SimClockBadge(top: 10),
        ),
      ],
    );
  }
}

/// "Despachador · Central Norte" en gris y "Hola, Diego" grande.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.header});

  final HomeHeader header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Context(role: header.roleLabel, tagline: header.tagline),
        const SizedBox(height: 2),
        Text(
          'Hola, ${homeFirstName(header.fullName)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// El rol y, después de un punto, el contexto (la central, la ciudad), en
/// gris y en una línea; el contexto se corta si no cabe.
class _Context extends StatelessWidget {
  const _Context({required this.role, required this.tagline});

  final String role;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        Text(role, style: style?.copyWith(fontWeight: FontWeight.w600)),
        Text('  ·  ', style: style),
        Flexible(
          child: Text(
            tagline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// Las iniciales en un círculo suave del acento. Son un botón de 44 px que
/// abre el perfil.
class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return Semantics(
      button: true,
      label: 'Mi perfil',
      excludeSemantics: true,
      child: Material(
        color: colors.primary.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
