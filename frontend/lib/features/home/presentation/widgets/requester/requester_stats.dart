import 'package:flutter/material.dart';

import '../../../../../core/widgets/bar_spark.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/ring_gauge.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../orders/data/order_models.dart';

/// Los números del solicitante, sacados de sus pedidos: a la izquierda
/// cuántos llegaron (con el anillo de entregados sobre el total) y a la
/// derecha los pedidos de las últimas cuatro semanas en barras.
class RequesterStats extends StatelessWidget {
  const RequesterStats({super.key, required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final delivered = orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _DeliveredCard(delivered: delivered, total: orders.length),
            ),
            const SizedBox(width: 12),
            Expanded(child: _WeeksCard(weeks: _lastWeeks(orders))),
          ],
        ),
      ),
    );
  }

  /// Pedidos creados en cada una de las últimas 4 semanas (la última, hoy).
  static List<int> _lastWeeks(List<Order> orders) {
    final now = DateTime.now();
    final weeks = List.filled(4, 0);
    for (final order in orders) {
      final at = order.createdAt?.toLocal();
      if (at == null) continue;
      final ago = now.difference(at).inDays ~/ 7;
      if (ago >= 0 && ago < 4) weeks[3 - ago]++;
    }
    return weeks;
  }
}

class _DeliveredCard extends StatelessWidget {
  const _DeliveredCard({required this.delivered, required this.total});

  final int delivered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENTREGADOS', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              RingGauge(
                progress: total == 0 ? 0 : delivered / total,
                size: 46,
                stroke: 5,
                child: Text('$delivered', style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'de $total\npedidos',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeksCard extends StatelessWidget {
  const _WeeksCard({required this.weeks});

  final List<int> weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = weeks.fold<int>(0, (sum, w) => sum + w);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESTE MES', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          BarSpark(values: weeks, highlight: weeks.length - 1, height: 30),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: '$total ',
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.palette.accentGradient.first,
              ),
              children: [
                TextSpan(
                  text: total == 1 ? 'pedido' : 'pedidos',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
