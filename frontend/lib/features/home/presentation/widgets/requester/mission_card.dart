import 'package:flutter/material.dart';

import '../../../../../core/clock/sim_clock.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../orders/presentation/order_format.dart';
import '../../../../orders/presentation/widgets/order_status_chip.dart';
import '../../../../tracking/data/telemetry_models.dart';
import 'mission_route.dart';

/// El pedido que está volando, arriba del inicio: el estado con su punto
/// verde, qué va en el dron, los minutos para llegar (de la telemetría en
/// vivo) con la hora estimada, la ruta con el dron en su punto y "Ver
/// mapa". Sin telemetría todavía (o sin conexión) muestra el estado del
/// pedido y el dron en medio de la ruta. Toda la tarjeta abre el mapa.
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.order,
    required this.onWatch,
    this.telemetry,
    this.progress,
    this.forRequester = false,
  });

  final Order order;

  /// El solicitante ve el estado en sus palabras ("Preparando el envío").
  final bool forRequester;
  final VoidCallback onWatch;
  final Telemetry? telemetry;

  /// Cuánto de la ruta lleva el dron (0 a 1), si hay telemetría y ruta.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final status = forRequester
        ? OrderStatusChip.requesterLabel(order.status)
        : order.status.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onWatch,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Top(order: order, status: status, telemetry: telemetry),
            const SizedBox(height: 14),
            MissionRoute(
              endLabel: order.address.split(',').first,
              progress: progress,
            ),
            const SizedBox(height: 10),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

/// A la izquierda el estado y qué va; a la derecha los minutos.
class _Top extends StatelessWidget {
  const _Top({
    required this.order,
    required this.status,
    required this.telemetry,
  });

  final Order order;
  final String status;
  final Telemetry? telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final what = order.requiresColdChain
        ? '${unitsLabel(order.quantity)} · con nevera'
        : unitsLabel(order.quantity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveLabel(text: status),
              const SizedBox(height: 4),
              Text(
                order.medicationName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                what,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (telemetry case final t?) _Eta(telemetry: t),
      ],
    );
  }
}

/// El estado con un punto verde (sin brillo).
class _LiveLabel extends StatelessWidget {
  const _LiveLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final green = context.palette.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: green),
        ),
      ],
    );
  }
}

/// "6 min" y "llega 9:52 a. m." con la hora simulada; en destino lo dice.
class _Eta extends StatelessWidget {
  const _Eta({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = telemetry.etaMinutes;
    final arrives = eta == null
        ? null
        : formatClock(simClock.now().add(Duration(minutes: eta)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          eta == null ? 'En destino' : '$eta min',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: eta == null ? 20 : 28,
            letterSpacing: -0.5,
          ),
        ),
        if (arrives != null)
          Text('llega $arrives', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// "Ver mapa" a la derecha, en el acento.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Ver mapa',
          style: theme.textTheme.titleSmall?.copyWith(color: accent),
        ),
        Icon(Icons.chevron_right_rounded, size: 20, color: accent),
      ],
    );
  }
}
