import 'package:flutter/material.dart';

import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/agenda_models.dart';
import '../../../data/order_models.dart';

class AgendaEntryChecks extends StatelessWidget {
  const AgendaEntryChecks({super.key, required this.entry});
  final AgendaOrder entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Check(
        label: entry.order.destinationKind == DestinationKind.hub
            ? 'No requiere confirmación'
            : entry.confirmed
            ? 'Entrega confirmada'
            : 'Por confirmar',
        tone: entry.order.destinationKind == DestinationKind.hub
            ? PillTone.neutral
            : entry.confirmed
            ? PillTone.positive
            : PillTone.attention,
      ),
      const SizedBox(height: 6),
      _Check(
        label: entry.stockOk
            ? 'Stock disponible: ${entry.availableQuantity}'
            : 'Stock insuficiente: ${entry.availableQuantity} de ${entry.order.quantity}',
        tone: entry.stockOk ? PillTone.positive : PillTone.negative,
      ),
      if (entry.prescriptionValid case final valid?) ...[
        const SizedBox(height: 6),
        _Check(
          label: valid ? 'Fórmula vigente' : 'Fórmula vencida',
          tone: valid ? PillTone.positive : PillTone.negative,
        ),
      ],
    ],
  );
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.tone});
  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        tone == PillTone.negative
            ? AppIcons.warning
            : tone == PillTone.attention
            ? AppIcons.clock
            : AppIcons.check,
        size: 17,
        color: StatusPill.colorOf(context, tone),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: StatusPill.colorOf(context, tone),
          ),
        ),
      ),
    ],
  );
}
