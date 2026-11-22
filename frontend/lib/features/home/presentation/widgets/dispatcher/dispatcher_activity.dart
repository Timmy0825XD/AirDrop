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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            for (final (index, (label, count, icon, path)) in [
              (
                'Por cargar',
                counts.pendingLoad,
                AppIcons.orders,
                '/orders/pending-load',
              ),
              (
                'En vuelo',
                counts.inFlight,
                AppIcons.flight,
                '/orders/in-flight',
              ),
              (
                'Por recibir',
                counts.toReceive,
                AppIcons.incoming,
                '/orders/incoming',
              ),
            ].indexed) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 42,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              Expanded(
                child: _Counter(
                  label: label,
                  count: count,
                  icon: icon,
                  onTap: () => onOpen(path),
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Icon(icon, size: 21),
                Text(
                  count == null ? '—' : '$count',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
