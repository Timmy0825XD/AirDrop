import 'package:flutter/material.dart';

import '../../../../../core/widgets/status_pill.dart';
import '../../../data/agenda_models.dart';
import '../../order_format.dart';
import '../order_status_chip.dart';

/// Confirmada, stock y fórmula, en verde o rojo.
List<Widget> agendaChecks(AgendaOrder entry) {
  StatusPill check(String label, bool ok) => StatusPill(
    label: label,
    tone: ok ? PillTone.positive : PillTone.negative,
  );
  return [
    check(entry.confirmed ? 'Confirmada' : 'Sin confirmar', entry.confirmed),
    check(
      entry.stockOk ? 'Stock' : 'Stock: ${entry.availableQuantity}',
      entry.stockOk,
    ),
    if (entry.prescriptionValid case final valid?)
      check(valid ? 'Fórmula vigente' : 'Fórmula vencida', valid),
  ];
}

/// Una entrega de la franja: qué y cuánto, su estado, las tres
/// verificaciones (confirmada, stock, fórmula) y la hora límite para
/// despegar. La agenda no decide nada: solo informa.
class AgendaEntryTile extends StatelessWidget {
  const AgendaEntryTile({super.key, required this.entry, required this.onTap});

  final AgendaOrder entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = entry.order;
    final depart = entry.departBefore;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.medicationName} · ${order.quantity} und.',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: agendaChecks(entry)),
            const SizedBox(height: 6),
            Text(
              depart == null
                  ? 'Sin ruta disponible'
                  : 'Despegar antes de las ${formatClock(depart)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
