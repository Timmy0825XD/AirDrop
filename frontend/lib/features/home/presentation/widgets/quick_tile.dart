import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';

/// Un acceso en la cuadrícula del inicio: ícono teñido, título y, si hay,
/// cuántos pendientes. Con `onTap` en `null` queda con candado (la central
/// suspendida, por ejemplo) y se ve apagado.
class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.count,
    this.urgent = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final int? count;

  /// Con pendientes, el contador va en el color de atención.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = onTap == null;
    final tone = urgent && (count ?? 0) > 0
        ? StatusPill.colorOf(context, PillTone.attention)
        : theme.colorScheme.primary;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TileHead(icon: icon, tone: tone, locked: locked, count: count),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleSmall, maxLines: 2),
            if (subtitle != null)
              Text(subtitle!, style: theme.textTheme.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

/// El ícono teñido y, a la derecha, el contador o el candado.
class _TileHead extends StatelessWidget {
  const _TileHead({
    required this.icon,
    required this.tone,
    required this.locked,
    required this.count,
  });

  final IconData icon;
  final Color tone;
  final bool locked;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ToneTile.icon(icon: icon, tone: tone, size: 40),
        const Spacer(),
        if (locked)
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          )
        else if (count != null)
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(color: tone),
          ),
      ],
    );
  }
}
