import 'package:flutter/material.dart';

import 'glass_card.dart';
import 'status_pill.dart';
import 'tone_tile.dart';

/// Una opción de [MenuList]: ícono, título, detalle opcional y, si hay,
/// cuántos pendientes. Con [onTap] en `null` queda con candado (la central
/// suspendida, por ejemplo).
class MenuItem {
  const MenuItem({
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
}

/// Una lista de opciones en una sola tarjeta, separadas por líneas finas,
/// como los ajustes de un teléfono. Es la forma de los accesos de "Más" y
/// de los inicios.
class MenuList extends StatelessWidget {
  const MenuList({super.key, required this.items});

  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0) Divider(height: 1, indent: 70, color: line),
              _MenuRow(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locked = item.onTap == null;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                ToneTile.icon(icon: item.icon, tone: colors.primary, size: 42),
                const SizedBox(width: 14),
                Expanded(child: _Texts(item: item)),
                _Trailing(item: item, locked: locked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        if (item.subtitle case final text?)
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// El contador (o el candado) y la flecha.
class _Trailing extends StatelessWidget {
  const _Trailing({required this.item, required this.locked});

  final MenuItem item;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final count = item.count ?? 0;
    final tone = item.urgent && count > 0
        ? StatusPill.colorOf(context, PillTone.attention)
        : muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!locked && item.count != null)
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(color: tone),
          ),
        const SizedBox(width: 4),
        Icon(
          locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
          size: locked ? 18 : 24,
          color: muted,
        ),
      ],
    );
  }
}
