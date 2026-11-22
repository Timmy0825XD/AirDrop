import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import 'next_up.dart';

/// Revisar abre el flujo existente; autorizar y cargar siguen siendo pasos distintos.
class DispatcherTaskCard extends StatelessWidget {
  const DispatcherTaskCard({
    super.key,
    required this.item,
    required this.onTap,
  });
  final NextUpItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusPill(label: item.label, tone: item.tone),
        const SizedBox(height: 12),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          item.detail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        TextButton(
          onPressed: onTap,
          child: Row(
            children: [
              Icon(item.icon, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(item.actionLabel)),
              const Icon(AppIcons.next, size: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
