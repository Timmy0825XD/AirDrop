import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/radar_sweep.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../orders/data/order_models.dart';
import '../../../../tracking/data/telemetry_models.dart';
import 'mission_route.dart';

/// El pedido que está volando, arriba del inicio, como una misión en
/// curso: la luz verde, los minutos para llegar en grande (de la
/// telemetría en vivo), qué va en el dron, la ruta con el dron en su punto
/// y la altitud, la velocidad y la fase. Detrás, un radar que barre. Sin
/// telemetría todavía (o sin conexión) muestra el estado del pedido y el
/// dron flotando en la ruta. Toda la tarjeta abre el mapa.
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.order,
    required this.onWatch,
    this.telemetry,
    this.progress,
  });

  final Order order;
  final VoidCallback onWatch;
  final Telemetry? telemetry;

  /// Cuánto de la ruta lleva el dron (0 a 1), si hay telemetría y ruta.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 28,
        onTap: onWatch,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              top: -30,
              right: -40,
              width: 180,
              height: 180,
              child: RadarSweep(reach: 0.5),
            ),
            _MissionBody(card: this),
          ],
        ),
      ),
    );
  }
}

/// El rótulo, la cifra, qué va en el dron, la ruta y los datos de vuelo.
class _MissionBody extends StatelessWidget {
  const _MissionBody({required this.card});

  final MissionCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = card.order;
    final t = card.telemetry;
    final what = order.requiresColdChain
        ? 'cadena de frío'
        : '${order.quantity} und.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LiveLabel(text: 'MISIÓN EN CURSO'),
        const SizedBox(height: 8),
        _Headline(telemetry: t, status: order.status),
        const SizedBox(height: 6),
        Text(
          '${order.medicationName} · $what',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        MissionRoute(
          endLabel: order.address.split(',').first,
          progress: card.progress,
        ),
        const SizedBox(height: 10),
        if (t != null) _FlightChips(telemetry: t),
      ],
    );
  }
}

/// La luz verde que late y el rótulo.
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
          decoration: BoxDecoration(
            color: green,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: green, blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: green),
        ),
      ],
    );
  }
}

/// "07 min para llegar" con la telemetría; si no, el estado del pedido.
class _Headline extends StatelessWidget {
  const _Headline({required this.telemetry, required this.status});

  final Telemetry? telemetry;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = telemetry?.etaMinutes;
    if (telemetry == null) {
      return Text(
        status.label,
        style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: -0.8),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          eta == null ? '00' : eta.toString().padLeft(2, '0'),
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 60,
            letterSpacing: -3,
            height: 0.95,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            eta == null ? 'en\ndestino' : 'min\npara llegar',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.15),
          ),
        ),
      ],
    );
  }
}

/// Altitud, velocidad y fase en tres casillas de vidrio.
class _FlightChips extends StatelessWidget {
  const _FlightChips({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    return Row(
      children: [
        _Chip(label: 'ALT', value: '${t.altitudeM.round()}', unit: 'm'),
        const SizedBox(width: 8),
        _Chip(label: 'VEL', value: '${t.speedKmh.round()}', unit: 'km/h'),
        const SizedBox(width: 8),
        _Chip(label: 'FASE', value: t.phase.label, unit: ''),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: ' $unit', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
