import 'package:flutter/material.dart';

import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../../orders/presentation/order_format.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import '../fleet_flight_card.dart';

/// Lo que va en la hoja del mapa, de arriba abajo: los incidentes
/// abiertos, cada central con su flota y los drones en misión (tocar uno
/// abre su vuelo).
List<Widget> fleetMapSheet({
  required BuildContext context,
  required FleetMap map,
  required List<FleetIncident> incidents,
  required ValueChanged<FleetFlight> onFlight,
}) {
  final theme = Theme.of(context);
  final muted = theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
  return [
    for (final i in incidents)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: WarningBanner(message: incidentLine(i)),
      ),
    for (final hub in map.hubs)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('${hub.name} · ${hub.fleetLine}', style: muted),
      ),
    const SizedBox(height: 4),
    if (map.flights.isEmpty)
      const MessageView(
        icon: Icons.flight_land_rounded,
        message: 'No hay drones en misión ahora.',
      ),
    for (final f in map.flights)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FleetFlightCard(flight: f, onTap: () => onFlight(f)),
      ),
  ];
}

/// "Aterrizaje de emergencia · rescate antes de las 15:40".
String incidentLine(FleetIncident i) => [
  i.protocolLabel,
  if (i.rescueDueAt case final due?) 'rescate antes de las ${formatClock(due)}',
].join(' · ');
