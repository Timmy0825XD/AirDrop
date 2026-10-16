import 'package:flutter/material.dart';

import '../../../../../core/widgets/count_up_text.dart';

/// Los números del día en una tarjeta montada sobre la curva: centrales
/// activas, cuentas activas y lo que está suspendido. `null` en un dato
/// pinta un guion mientras carga o si Nest no respondió.
class AdminStatsCard extends StatelessWidget {
  const AdminStatsCard({
    super.key,
    required this.activeHubs,
    required this.activeAccounts,
    required this.suspended,
  });

  final int? activeHubs;
  final int? activeAccounts;
  final int? suspended;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = BorderSide(color: colors.outline);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.14),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Stat(
              value: activeHubs,
              label: 'Centrales activas',
              color: colors.primary,
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(left: divider)),
            ),
            _Stat(
              value: activeAccounts,
              label: 'Cuentas activas',
              color: colors.onSurface,
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(left: divider)),
            ),
            _Stat(value: suspended, label: 'Suspendidas', color: colors.error),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final int? value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '$label: ${value ?? 'sin dato'}',
        excludeSemantics: true,
        child: Column(
          children: [
            CountUpText(
              value: value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
