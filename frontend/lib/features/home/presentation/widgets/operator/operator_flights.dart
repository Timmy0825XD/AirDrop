import 'package:flutter/material.dart';

import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_flight.dart';
import '../home_section_heading.dart';
import '../home_status_card.dart';
import 'operator_flight_values.dart';
import 'operator_home_values.dart';
import 'operator_work_card.dart';
import 'operator_empty_card.dart';

class OperatorFlights extends StatelessWidget {
  const OperatorFlights({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onRetry,
  });
  final OperatorHomeValues data;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(
        title: 'Vuelos en curso',
        onViewAll: data.flights.value?.isNotEmpty == true
            ? () => onOpen('/fleet/flights')
            : null,
      ),
      _FlightState(data: data, onRetry: onRetry),
      for (final flight in (data.flights.value ?? <FleetFlight>[]).take(2)) ...[
        _FlightPreview(
          data: data,
          flight: flight,
          onTap: () => onOpen('/tracking/${flight.orderId}'),
        ),
        const SizedBox(height: 12),
      ],
      if ((data.flights.value?.length ?? 0) > 2)
        TextButton(
          onPressed: () => onOpen('/fleet/flights'),
          child: Text(
            'Ver los ${data.flights.value!.length} vuelos en el mapa',
          ),
        ),
    ],
  );
}

class _FlightState extends StatelessWidget {
  const _FlightState({required this.data, required this.onRetry});
  final OperatorHomeValues data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (data.flightsLoading) return const Skeleton(height: 160, radius: 20);
    if (data.flights.value?.isNotEmpty ?? false) return const SizedBox.shrink();
    if (data.flightsFailed) {
      return HomeStatusCard(
        title: 'Vuelos sin actualizar',
        message: 'Reintenta para consultar los vuelos en curso.',
        icon: AppIcons.unavailable,
        scene: CorridorScene.broken,
        action: TextButton(
          onPressed: onRetry,
          child: const Text('Actualizar vuelos'),
        ),
      );
    }
    return const OperatorEmptyCard(
      title: 'Sin vuelos por ahora',
      message: 'Aquí verás los drones en misión.',
    );
  }
}

class _FlightPreview extends StatelessWidget {
  const _FlightPreview({
    required this.data,
    required this.flight,
    required this.onTap,
  });
  final OperatorHomeValues data;
  final FleetFlight flight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OperatorWorkCard(
    titleFirst: true,
    batteryPercent: flight.batteryPercent,
    title: data.droneTitle(flight.identifier, flight.droneId),
    label: operatorFlightPhase(flight),
    detail: [
      flight.returning
          ? 'Regresa a ${data.hubName(flight.hubId)}'
          : 'Desde ${data.hubName(flight.hubId)}',
      operatorFlightReadings(flight),
    ].where((s) => s.isNotEmpty).join('\n'),
    action: 'Ver vuelo',
    icon: AppIcons.drone,
    tone: operatorFlightNeedsReview(flight)
        ? PillTone.attention
        : PillTone.positive,
    onTap: onTap,
  );
}
