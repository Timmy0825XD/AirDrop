import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';
import '../../../orders/data/order_models.dart';
import '../../data/telemetry_models.dart';

/// Un paso de la línea de tiempo del vuelo.
typedef _Step = ({String title, String? note, DateTime? at, _StepState state});

enum _StepState { done, now, next }

/// Los cuatro pasos con su estado según el pedido y la telemetría.
List<_Step> _flightSteps(
  Order? order,
  OrderStatus? status,
  Telemetry? telemetry,
) {
  final s = status;
  final landed =
      s == OrderStatus.awaitingDelivery || s == OrderStatus.delivered;
  final flying = s == OrderStatus.inFlight;
  _StepState stage(bool done, bool now) =>
      done ? _StepState.done : (now ? _StepState.now : _StepState.next);
  return [
    (
      title: 'Pedido autorizado',
      note: null,
      at: order?.authorizedAt,
      state: _StepState.done,
    ),
    (
      title: 'Carga confirmada',
      note: 'El dron despegó de la central',
      at: order?.loadConfirmedAt,
      state: stage(flying || landed, order?.loadConfirmedAt != null),
    ),
    (
      title: 'En vuelo',
      note: flying ? telemetry?.phase.label : null,
      at: null,
      state: stage(landed, flying),
    ),
    (
      title: 'Entrega con código',
      note: s == OrderStatus.awaitingDelivery ? 'Tienes 5 minutos' : null,
      at: null,
      state: stage(
        s == OrderStatus.delivered,
        s == OrderStatus.awaitingDelivery,
      ),
    ),
  ];
}

/// La línea de tiempo del vuelo, con las horas reales del pedido:
/// autorizado, carga confirmada (despegue), en vuelo (con la fase) y la
/// entrega con el código en destino. El paso actual se enciende.
class FlightTimeline extends StatelessWidget {
  const FlightTimeline({
    super.key,
    required this.order,
    required this.status,
    this.telemetry,
  });

  final Order? order;
  final OrderStatus? status;
  final Telemetry? telemetry;

  @override
  Widget build(BuildContext context) {
    final steps = _flightSteps(order, status, telemetry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VUELO', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        for (final (i, step) in steps.indexed)
          _StepRow(step: step, last: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = step.state != _StepState.next;
    final at = step.at?.toLocal();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(state: step.state, last: last),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: active ? null : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (step.note != null)
                    Text(step.note!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          if (at != null)
            Text(
              '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

/// El punto del paso (lleno, encendido o vacío) y la línea que baja.
class _Rail extends StatelessWidget {
  const _Rail({required this.state, required this.last});

  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = context.palette.success;
    final now = colors.primary;
    final idle = colors.onSurfaceVariant.withValues(alpha: 0.4);
    final dot = switch (state) {
      _StepState.done => done,
      _StepState.now => now,
      _StepState.next => idle,
    };
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          const SizedBox(height: 3),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state == _StepState.next ? null : dot,
              border: Border.all(color: dot, width: 2),
              boxShadow: [
                if (state == _StepState.now)
                  BoxShadow(color: now, blurRadius: 8),
              ],
            ),
          ),
          if (!last)
            Expanded(
              child: Container(
                width: 1.5,
                margin: const EdgeInsets.only(top: 3),
                color: state == _StepState.done
                    ? done.withValues(alpha: 0.5)
                    : idle,
              ),
            ),
        ],
      ),
    );
  }
}
