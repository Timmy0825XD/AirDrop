import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_palette.dart';

/// El encabezado de un inicio: el rol en una pastilla, el saludo y una
/// línea de contexto (la central, la ciudad). A la derecha, las iniciales
/// sobre el acento y cerrar sesión.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.roleLabel,
    required this.fullName,
    required this.tagline,
    required this.onSignOut,
  });

  final String roleLabel;
  final String fullName;
  final String tagline;
  final VoidCallback onSignOut;

  /// El primer nombre para el saludo.
  static String firstNameOf(String fullName) =>
      fullName.trim().split(RegExp(r'\s+')).first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(label: roleLabel, tone: PillTone.neutral),
              const SizedBox(height: 10),
              Text(
                'Hola, ${firstNameOf(fullName)}',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Initials(name: fullName),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Cerrar sesión',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, size: 20),
        ),
      ],
    );
  }
}

/// Las iniciales del nombre sobre el acento en degradado.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: palette.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: palette.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
