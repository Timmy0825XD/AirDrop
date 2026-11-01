import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../orders/data/order_models.dart';

const _days = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
const _months = [
  'ENE',
  'FEB',
  'MAR',
  'ABR',
  'MAY',
  'JUN',
  'JUL',
  'AGO',
  'SEP',
  'OCT',
  'NOV',
  'DIC',
];

/// "LUN 03 NOV · 08:00".
String deliveryWhen(DateTime at) {
  final local = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${_days[local.weekday - 1]} ${two(local.day)} '
      '${_months[local.month - 1]} · ${two(local.hour)}:${two(local.minute)}';
}

/// La próxima entrega programada del solicitante (de un plan o una
/// entrega por confirmar): el medicamento, el día y la hora, y si viene de
/// un plan. Abre el pedido.
class NextDeliveryCard extends StatelessWidget {
  const NextDeliveryCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amber = context.palette.warning;
    final at = order.scheduledAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 24,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.event_repeat_rounded, color: amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.medicationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (at != null)
                    Text(
                      deliveryWhen(at),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            _Tag(text: order.planId == null ? 'Programada' : 'Plan'),
          ],
        ),
      ),
    );
  }
}

/// La etiqueta ámbar de la derecha.
class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final amber = context.palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: amber),
      ),
    );
  }
}
