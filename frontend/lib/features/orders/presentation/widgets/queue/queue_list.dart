import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import 'queue_tile.dart';

/// Lista perezosa: respeta el orden recibido incluso al refrescar o recibir avisos.
class QueueList extends StatelessWidget {
  const QueueList({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onRetry,
    this.error,
  });
  final List<QueueEntry> entries;
  final String? error;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: entries.length + 1,
    separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 0 : 12),
    itemBuilder: (_, index) {
      if (index == 0) {
        return _QueueListHeading(
          count: entries.length,
          error: error,
          onRetry: onRetry,
        );
      }
      final entry = entries[index - 1];
      return QueueTile(
        key: ValueKey(entry.order.id),
        entry: entry,
        onTap: () => onOpen(entry.order.id),
      );
    },
  );
}

class _QueueListHeading extends StatelessWidget {
  const _QueueListHeading({
    required this.count,
    required this.onRetry,
    this.error,
  });
  final int count;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null) ...[
        WarningBanner(
          message:
              'No pudimos actualizar la cola. $error\nÚltimos datos disponibles.',
          icon: AppIcons.unavailable,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Text(
        count == 1
            ? '1 solicitud por atender'
            : '$count solicitudes por atender',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'En orden de prioridad',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
