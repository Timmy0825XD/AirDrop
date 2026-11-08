import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import 'fleet_health_card.dart';
import 'fleet_incidents_card.dart';
import 'fleet_usage_card.dart';

/// El tablero de la flota en el inicio del operador (CU-20): uso, salud e
/// incidentes del periodo. Mientras carga la primera vez, un indicador; con
/// error, el mensaje de Nest.
class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({
    super.key,
    required this.state,
    required this.onOpenFleet,
  });

  final AsyncValue<FleetDashboard> state;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncValue(hasValue: true, hasError: false, :final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FleetUsageCard(dashboard: value),
          const SizedBox(height: 12),
          FleetHealthCard(dashboard: value, onOpenFleet: onOpenFleet),
          const SizedBox(height: 12),
          FleetIncidentsCard(dashboard: value),
        ],
      ),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
