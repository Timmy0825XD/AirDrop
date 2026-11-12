import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../core/widgets/tone_tile.dart';
import '../home_grid.dart';
import 'next_up.dart';

/// "Para atender ahora": hasta tres tareas (la urgencia más vieja, el
/// dron que espera la carga, el próximo programado). Tocar una abre su
/// pedido. Sin nada pendiente, lo dice en una línea.
class NextUpCard extends StatelessWidget {
  const NextUpCard({super.key, required this.items, required this.onOpen});

  final List<NextUpItem> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeLabel('Para atender ahora'),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Nada pendiente: la cola, la carga y los programados '
                    'están al día.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final item in items)
                      _NextUpRow(item: item, onTap: () => onOpen(item.orderId)),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Una tarea: ícono teñido, qué hacer y el detalle.
class _NextUpRow extends StatelessWidget {
  const _NextUpRow({required this.item, required this.onTap});

  final NextUpItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ToneTile.icon(
              icon: item.icon,
              tone: StatusPill.colorOf(context, item.tone),
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(item.detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
