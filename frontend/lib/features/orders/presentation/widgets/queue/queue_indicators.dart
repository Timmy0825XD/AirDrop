import 'package:flutter/material.dart';

import '../../../../../core/clock/sim_clock.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../queue_wait.dart';
import 'queue_facts.dart';

/// La alarma, la espera y el origen se muestran por separado: ninguna tapa otra.
class QueueIndicators extends StatelessWidget {
  const QueueIndicators({super.key, required this.entry});
  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final alarm = entry.order.triage?.hasRedFlag == true;
    final wait = queueWaitMinutes(entry.order.createdAt, simClock.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (alarm) ...[
          QueueFact(
            label: 'Signo de alarma',
            icon: AppIcons.warning,
            color: StatusPill.colorOf(context, PillTone.negative),
            strong: true,
          ),
          const SizedBox(height: 8),
        ],
        StatusPill(
          label: entry.order.createdAt == null
              ? 'Hora no disponible'
              : queueWaitLabel(wait),
          tone: alarm
              ? PillTone.negative
              : queueWaitTone(wait, unattended: entry.unattended),
        ),
      ],
    );
  }
}
