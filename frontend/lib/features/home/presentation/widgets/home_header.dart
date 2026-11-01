import 'package:flutter/material.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_palette.dart';
import '../../../../core/widgets/drone_mark.dart';
import '../../../notifications/presentation/widgets/notice_bell.dart';

/// El primer nombre para el saludo.
String homeFirstName(String fullName) =>
    fullName.trim().split(RegExp(r'\s+')).first;

/// El encabezado de un inicio, como la cabina de la app: arriba la marca
/// (el dron y "AirDrop") con la campana, las iniciales y cerrar sesión;
/// debajo el rol en una pastilla, el saludo grande y una línea de contexto
/// (la central, la ciudad).
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandRow(header: this),
        const SizedBox(height: 22),
        StatusPill(label: roleLabel, tone: PillTone.neutral),
        const SizedBox(height: 10),
        Text(
          'Hola, ${homeFirstName(fullName)}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 34,
            letterSpacing: -1.2,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tagline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// La marca a la izquierda y, a la derecha, la campana (si hay), las
/// iniciales y cerrar sesión.
class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.header});

  final HomeHeader header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const DroneMark(size: 30),
        const SizedBox(width: 8),
        Text(
          'AirDrop',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        if (header.onNotices case final open?) ...[
          NoticeBell(unread: header.unreadNotices, onTap: open),
          const SizedBox(width: 6),
        ],
        _Initials(name: header.fullName),
        const SizedBox(width: 6),
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
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: palette.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.accentGradient.first.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: palette.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
