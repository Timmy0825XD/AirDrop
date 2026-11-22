import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../core/date_format.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/operator/operator_empty_card.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import '../fleet_flight_card.dart';
import 'fleet_map_values.dart';

/// La hoja prioriza los vuelos; las centrales se consultan en sus pines.
List<Widget> fleetMapSheet({
  required BuildContext context,
  required FleetMap map,
  required List<FleetIncident> incidents,
  required ValueChanged<FleetFlight> onFlight,
  FleetMapValues? values,
  String? problem,
  VoidCallback? onRetry,
}) {
  final labels = values ?? FleetMapValues(map: map);
  return [
    Text(
      'Vuelos en curso · ${map.flights.length}',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 4),
    if (problem != null) ...[
      const SizedBox(height: 8),
      WarningBanner(
        message: 'No pudimos actualizar los vuelos.\n$problem',
        icon: AppIcons.unavailable,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ),
    ],
    for (final i in incidents)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: WarningBanner(message: incidentLine(i), icon: AppIcons.warning),
      ),
    if (map.flights.isEmpty)
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: OperatorEmptyCard(
          title: 'Sin vuelos por ahora',
          message: 'Aquí verás los drones en misión.',
        ),
      ),
    for (var i = 0; i < map.flights.length; i++) ...[
      if (i > 0) const Divider(height: 1),
      FleetFlightCard(
        flight: map.flights[i],
        title: labels.titleOf(map.flights[i]),
        routeLabel: labels.routeOf(map.flights[i]),
        onTap: () => onFlight(map.flights[i]),
      ),
    ],
  ];
}

/// "Falla de 2 motores en la ida · Aterrizaje de emergencia." y, debajo,
/// "En tierra, espera el rescate · rescate antes de las 15:40 · Con el
/// paquete a bordo · batería 62 %".
String incidentLine(FleetIncident i) {
  final what = [i.kindLabel, ?i.legLabel].join(' ');
  final status = [
    i.outcomeLabel,
    if (i.rescueDueAt case final due?)
      'rescate antes de las ${formatClock(due)}',
    i.packageLabel,
    if (i.batteryPercent case final battery?) 'batería ${battery.round()} %',
  ].join(' · ');
  return '$what · ${i.protocolLabel}.\n$status';
}
