import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_palette.dart';
import '../../../notifications/presentation/widgets/notice_bell.dart';

/// El primer nombre para el saludo.
String homeFirstName(String fullName) =>
    fullName.trim().split(RegExp(r'\s+')).first;

/// El encabezado de un inicio: el rol en una pastilla, el saludo y una
/// línea de contexto (la central, la ciudad). A la derecha, las iniciales
/// sobre el acento, la campana de avisos (si la pantalla la pasa) y cerrar
/// sesión.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.roleLabel,
    required this.fullName,
    required this.tagline,
    required this.onSignOut,
    this.onNotices,
    this.unreadNotices,
  });

  final String roleLabel;
  final String fullName;
  final String tagline;
  final VoidCallback onSignOut;

  /// Abre la bandeja de avisos; sin él no hay campana.
  final VoidCallback? onNotices;
  final int? unreadNotices;

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
                'Hola, ${homeFirstName(fullName)}',
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
        _HeaderActions(header: this),
      ],
    );
  }
}

/// La campana (si hay) y cerrar sesión.
class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.header});

  final HomeHeader header;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header.onNotices case final open?) ...[
          NoticeBell(unread: header.unreadNotices, onTap: open),
          const SizedBox(width: 4),
        ],
        IconButton.filledTonal(
          tooltip: 'Cerrar sesión',
          onPressed: header.onSignOut,
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
