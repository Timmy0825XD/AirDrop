import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';

/// Un acceso de un inicio rediseñado: ícono, título, descripción, cuántos
/// hay y la flecha. Se hunde al tocarlo. Con [onTap] en `null` queda
/// apagado con un candado (central suspendida, por ejemplo).
class HomeAccessCard extends StatelessWidget {
  const HomeAccessCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.count,
    this.urgent = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Color del ícono y de su cuadro.
  final Color tone;
  final VoidCallback? onTap;

  /// `null` mientras la lista carga: el contador no se muestra.
  final int? count;

  /// Con algo pendiente, el contador va en naranja para que se note.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.6,
      duration: const Duration(milliseconds: 300),
      child: PressScale(
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CardRow(card: this, enabled: enabled),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.enabled});

  final HomeAccessCard card;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        _IconTile(icon: card.icon, tone: enabled ? card.tone : muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(card.subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (enabled && card.count != null)
          _CountBadge(count: card.count!, urgent: card.urgent),
        const SizedBox(width: 6),
        Icon(
          enabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
          color: muted,
          size: enabled ? 24 : 20,
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: tone, size: 26),
    );
  }
}

/// El contador. Cuando cambia, el número nuevo entra con un rebote corto.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.urgent});

  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hot = urgent && count > 0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey('$count-$hot'),
        constraints: const BoxConstraints(minWidth: 28),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hot ? colors.secondary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: hot ? colors.onPrimary : colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
