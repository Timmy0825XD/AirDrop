import 'package:flutter/material.dart';

import '../../../../core/widgets/detail_section.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/analytics_models.dart';

/// `92,5 %`, `14,2 min`, `44`: coma decimal y sin decimales de más.
String formatKpiValue(double? value, String unit) {
  if (value == null) return 'Sin datos';
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return unit.isEmpty ? rounded : '$rounded $unit';
}

/// La meta en palabras: "Meta: 90 % o más".
String? kpiTargetLabel(KpiTarget? target, String unit) {
  if (target == null) return null;
  String v(double? n) => formatKpiValue(n, unit);
  return switch (target.kind) {
    'min' => 'Meta: ${v(target.green)} o más',
    'max' => 'Meta: ${v(target.green)} o menos',
    'band' => 'Meta: entre ${v(target.min)} y ${v(target.max)}',
    _ => null,
  };
}

/// Semáforo → tono de la pastilla (sin meta, neutro).
PillTone kpiTone(KpiStatus status) => switch (status) {
  KpiStatus.green => PillTone.positive,
  KpiStatus.amber => PillTone.attention,
  KpiStatus.red => PillTone.negative,
  KpiStatus.none => PillTone.neutral,
};

String _statusLabel(KpiStatus status) => switch (status) {
  KpiStatus.green => 'En meta',
  KpiStatus.amber => 'Atención',
  KpiStatus.red => 'Fuera de meta',
  KpiStatus.none => 'Informativo',
};

/// Un grupo de KPI (Resultados, Oportunidades, Fallas, Deficiencias).
class KpiGroupCard extends StatelessWidget {
  const KpiGroupCard({super.key, required this.group});

  final KpiGroup group;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: group.label,
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          for (final (i, kpi) in group.kpis.indexed) ...[
            if (i > 0) const Divider(height: 20),
            KpiRow(kpi: kpi),
          ],
        ],
      ),
    );
  }
}

/// Un KPI: nombre, valor con unidad, semáforo, meta y variación contra el
/// periodo anterior.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.kpi});

  final Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final delta = kpi.delta;
    final target = kpiTargetLabel(kpi.target, kpi.unit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(kpi.label, style: theme.textTheme.titleSmall)),
            StatusPill(
              label: _statusLabel(kpi.status),
              tone: kpiTone(kpi.status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatKpiValue(kpi.value, kpi.unit),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          [
            ?target,
            if (delta != null)
              '${delta >= 0 ? '▲' : '▼'} ${formatKpiValue(delta.abs(), kpi.unit)} '
                  'frente al periodo anterior',
          ].join(' · '),
          style: muted,
        ),
      ],
    );
  }
}
