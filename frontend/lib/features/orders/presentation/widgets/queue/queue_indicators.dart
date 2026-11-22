import 'package:flutter/material.dart';

import '../../../../../core/clock/sim_clock.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../data/order_models.dart';
import '../queue_wait.dart';

/// La alarma y la espera siguen siendo señales independientes.
class QueueIndicators extends StatelessWidget {
  const QueueIndicators({super.key, required this.entry});
  final QueueEntry entry;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ClockView?>(
    valueListenable: simClock.view,
    builder: (context, _, _) {
      final alarm = entry.order.triage?.hasRedFlag == true;
      final wait = queueWaitMinutes(entry.order.createdAt, simClock.now());
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (alarm)
            const StatusPill(label: 'Signo de alarma', tone: PillTone.negative),
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
    },
  );
}
