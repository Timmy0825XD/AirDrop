import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../../orders/presentation/widgets/order_status_chip.dart';
import '../../data/fleet_flight.dart';

/// "Crucero · Ida · 82 % · llega en 4 min".
String _flightDetails(FleetFlight f) => [
  f.phase?.label ?? 'Por despegar',
  f.returning ? 'Regreso' : 'Ida',
  if (f.batteryPercent case final b?) '${b.round()} %',
  if (f.etaSeconds case final s? when !f.returning)
    'llega en ${(s / 60).ceil()} min',
].join(' · ');

List<String> _flightAlerts(FleetFlight f) => [
  if (f.batteryAlert) 'Batería baja',
  if (f.failureAlert) 'Falla',
  if (f.coldChainAlert) 'Frío fuera de rango',
];

/// Un dron en misión: su nombre, el estado del pedido, la fase, la batería
/// y la llegada, y las alertas si hay. Tocarla abre el mapa del vuelo.
class FleetFlightCard extends StatelessWidget {
  const FleetFlightCard({super.key, required this.flight, required this.onTap});

  final FleetFlight flight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = flight;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToneTile.icon(
            icon: Icons.flight_rounded,
            tone: f.hasAlert
                ? StatusPill.colorOf(context, PillTone.negative)
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.identifier, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(_flightDetails(f), style: theme.textTheme.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    OrderStatusChip(status: f.orderStatus),
                    for (final alert in _flightAlerts(f))
                      StatusPill(label: alert, tone: PillTone.negative),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.map_outlined, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
