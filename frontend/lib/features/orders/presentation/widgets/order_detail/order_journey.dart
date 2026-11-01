import 'package:flutter/material.dart';

import '../../../../../core/widgets/drone_mark.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/order_models.dart';

const _flown = {
  OrderStatus.inFlight,
  OrderStatus.awaitingDelivery,
  OrderStatus.delivered,
  OrderStatus.returning,
  OrderStatus.returned,
};

const _failed = {
  OrderStatus.rejected,
  OrderStatus.cancelled,
  OrderStatus.expired,
  OrderStatus.skipped,
  OrderStatus.returned,
};

/// Cuántos puntos ya se cumplieron (1 a 5).
int _journeyDone(Order order) {
  final s = order.status;
  if (s == OrderStatus.delivered) return 5;
  if (s == OrderStatus.awaitingDelivery ||
      s == OrderStatus.returning ||
      s == OrderStatus.returned) {
    return 4;
  }
  if (order.loadConfirmedAt != null || _flown.contains(s)) return 3;
  if (order.authorizedAt != null ||
      s == OrderStatus.assigned ||
      s == OrderStatus.pendingLoad) {
    return 2;
  }
  return 1;
}

/// El recorrido del pedido como un plan de vuelo de cinco puntos: pedido,
/// autorizado, carga, vuelo y entrega (el flujo del negocio). Lo hecho va
/// encendido, el paso actual lleva el dron encima y, si el pedido terminó
/// mal (rechazado, devuelto, cancelado), ese punto se marca con una equis.
/// Todo sale del estado y las fechas del pedido.
class OrderJourney extends StatelessWidget {
  const OrderJourney({super.key, required this.order});

  final Order order;

  static const _labels = ['Pedido', 'Autorizado', 'Carga', 'Vuelo', 'Entrega'];

  @override
  Widget build(BuildContext context) {
    final done = _journeyDone(order);
    final failed = _failed.contains(order.status);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECORRIDO', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Semantics(
            label: 'Recorrido: ${order.status.label}',
            excludeSemantics: true,
            child: _Track(done: done, failed: failed, labels: _labels),
          ),
        ],
      ),
    );
  }
}

/// La línea con los cinco puntos, el dron sobre el actual y los nombres.
class _Track extends StatelessWidget {
  const _Track({
    required this.done,
    required this.failed,
    required this.labels,
  });

  final int done;
  final bool failed;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final active = done.clamp(0, labels.length - 1);
    final finished = done >= labels.length;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _Stop(
              label: labels[i],
              state: i < done && !(failed && i == active)
                  ? _StopState.done
                  : i == active && !finished
                  ? (failed ? _StopState.failed : _StopState.now)
                  : _StopState.next,
              first: i == 0,
              last: i == labels.length - 1,
              litLeft: i <= done,
            ),
          ),
      ],
    );
  }
}

enum _StopState { done, now, next, failed }

/// Un punto del recorrido: el dron (si es el actual), el punto con su
/// tramo a cada lado y el nombre debajo.
class _Stop extends StatelessWidget {
  const _Stop({
    required this.label,
    required this.state,
    required this.first,
    required this.last,
    required this.litLeft,
  });

  final String label;
  final _StopState state;
  final bool first;
  final bool last;
  final bool litLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stopColor(context, state);
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: state == _StopState.now ? const DroneMark(size: 30) : null,
        ),
        Row(
          children: [
            first ? const Spacer() : _Rail(lit: litLeft),
            _Dot(color: color, state: state),
            last ? const Spacer() : _Rail(lit: state == _StopState.done),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.6,
            color: state == _StopState.next ? null : color,
          ),
        ),
      ],
    );
  }
}

/// El tramo entre dos puntos, encendido si ya se recorrió.
class _Rail extends StatelessWidget {
  const _Rail({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 2,
        color: lit
            ? colors.primary.withValues(alpha: 0.7)
            : colors.onSurfaceVariant.withValues(alpha: 0.35),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.state});

  final Color color;
  final _StopState state;

  @override
  Widget build(BuildContext context) {
    final filled = state == _StopState.done || state == _StopState.failed;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : context.palette.bar,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          if (state == _StopState.now) BoxShadow(color: color, blurRadius: 10),
        ],
      ),
      child: state == _StopState.failed
          ? const Icon(Icons.close_rounded, size: 11, color: Colors.white)
          : state == _StopState.done
          ? Icon(Icons.check_rounded, size: 11, color: context.palette.onAccent)
          : null,
    );
  }
}

/// El color de un punto según cómo va.
Color _stopColor(BuildContext context, _StopState state) {
  final colors = Theme.of(context).colorScheme;
  return switch (state) {
    _StopState.done || _StopState.now => colors.primary,
    _StopState.failed => context.palette.danger,
    _StopState.next => colors.onSurfaceVariant.withValues(alpha: 0.35),
  };
}
