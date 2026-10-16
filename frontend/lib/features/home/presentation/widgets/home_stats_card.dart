import 'package:flutter/material.dart';

import '../../../../core/widgets/count_up_text.dart';

/// Un número del día: cuánto, qué es y de qué color va.
class HomeStat {
  const HomeStat({
    required this.value,
    required this.label,
    required this.color,
  });

  /// `null` pinta un guion mientras carga o si Nest no respondió.
  final int? value;
  final String label;
  final Color color;
}

/// Los números del día en una tarjeta montada sobre la curva del inicio,
/// separados por líneas finas. Cuentan desde 0 al aparecer.
class HomeStatsCard extends StatelessWidget {
  const HomeStatsCard({super.key, required this.stats});

  final List<HomeStat> stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.outline)),
      ),
    );
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
            for (final (i, stat) in stats.indexed) ...[
              if (i > 0) divider,
              _Stat(stat: stat),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.stat});

  final HomeStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: '${stat.label}: ${stat.value ?? 'sin dato'}',
        excludeSemantics: true,
        child: Column(
          children: [
            CountUpText(
              value: stat.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: stat.color,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.label,
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
