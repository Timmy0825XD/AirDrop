import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../home_section_heading.dart';
import 'dispatcher_counts.dart';

class DispatcherActivity extends StatelessWidget {
  const DispatcherActivity({
    super.key,
    required this.counts,
    required this.onOpen,
  });
  final DispatcherCounts counts;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HomeSectionHeading(title: 'Hoy en tu central'),
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Counter(
                label: 'Por cargar',
                count: counts.pendingLoad,
                icon: AppIcons.orders,
                onTap: () => onOpen('/orders/pending-load'),
              ),
            ),
            Expanded(
              child: _Counter(
                label: 'En vuelo',
                count: counts.inFlight,
                icon: AppIcons.flight,
                onTap: () => onOpen('/orders/in-flight'),
              ),
            ),
            Expanded(
              child: _Counter(
                label: 'Por recibir',
                count: counts.toReceive,
                icon: AppIcons.incoming,
                onTap: () => onOpen('/orders/incoming'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int? count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${count ?? 'sin actualizar'}',
    button: true,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Icon(
              icon,
              size: 21,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              count == null ? '—' : '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
