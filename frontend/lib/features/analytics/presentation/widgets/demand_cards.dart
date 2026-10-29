import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/bar_spark.dart';
import '../../../../core/widgets/detail_section.dart';
import '../../../../theme/app_palette.dart';
import '../../../orders/presentation/order_format.dart';
import '../../data/analytics_models.dart';

/// Lo más pedido en el periodo, con las unidades y lo que no se atendió.
class TopMedicationsCard extends StatelessWidget {
  const TopMedicationsCard({super.key, required this.rows});

  final List<MedicationDemand> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailSection(
      title: 'Lo más pedido',
      icon: Icons.medication_outlined,
      child: rows.isEmpty
          ? Text(
              'Sin pedidos en el periodo.',
              style: theme.textTheme.bodyMedium,
            )
          : Column(
              children: [
                for (final m in rows)
                  DetailLine(
                    label: m.name,
                    value:
                        '${m.orders} pedidos · ${m.units} und.'
                        '${m.unmet > 0 ? ' · ${m.unmet} sin atender' : ''}',
                  ),
              ],
            ),
    );
  }
}

/// Pedidos por día (urgencias más programados) en barras.
class DemandByDayCard extends StatelessWidget {
  const DemandByDayCard({super.key, required this.days});

  final List<DayDemand> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = days.fold(0, (sum, d) => sum + d.total);
    return DetailSection(
      title: 'Pedidos por día',
      icon: Icons.bar_chart_rounded,
      child: days.isEmpty
          ? Text(
              'Sin pedidos en el periodo.',
              style: theme.textTheme.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('$total pedidos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                BarSpark(values: [for (final d in days) d.total], height: 64),
                const SizedBox(height: 6),
                Text(
                  '${formatShortDate(days.first.date)} – '
                  '${formatShortDate(days.last.date)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

/// Las zonas con más pedidos sobre el mapa (celdas de ~1 km). Las de menos
/// de [DemandReport.minOrders] pedidos no se muestran, por privacidad.
class DemandZonesCard extends StatelessWidget {
  const DemandZonesCard({super.key, required this.report});

  final DemandReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.palette.warning;
    final top = report.cells.fold(1, (m, c) => c.orders > m ? c.orders : m);
    final points = [
      for (final c in report.cells) LatLng(c.latitude, c.longitude),
    ];
    return DetailSection(
      title: 'Zonas de demanda',
      icon: Icons.map_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: AppMap(
                fit: points,
                interactive: false,
                showControls: false,
                layers: [
                  CircleLayer(
                    circles: [
                      for (final c in report.cells)
                        CircleMarker(
                          point: LatLng(c.latitude, c.longitude),
                          radius: 10 + 18 * c.orders / top,
                          color: color.withValues(alpha: 0.35),
                          borderColor: color,
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las zonas con menos de ${report.minOrders} pedidos no se '
            'muestran${report.hiddenOrders > 0 ? ' (${report.hiddenOrders} pedidos)' : ''}.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
