import 'package:flutter/material.dart';

import '../../../../core/widgets/detail_section.dart';
import '../../data/analytics_models.dart';
import 'kpi_card.dart';

/// Una central del ranking: sus misiones y los indicadores que más pesan.
class HubRankingCard extends StatelessWidget {
  const HubRankingCard({super.key, required this.rank, required this.hub});

  /// Puesto, desde 1.
  final int rank;
  final HubRanking hub;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: '$rank. ${hub.name}',
      icon: Icons.home_work_outlined,
      child: Column(
        children: [
          DetailLine(label: 'Misiones', value: '${hub.missions}'),
          DetailLine(
            label: 'Entregas exitosas',
            value: formatKpiValue(hub.successRate, '%'),
          ),
          DetailLine(
            label: 'Retornos',
            value: formatKpiValue(hub.returnRate, '%'),
          ),
          DetailLine(
            label: 'Entrega de urgencias',
            value: formatKpiValue(hub.emergencyDeliveryMinutes, 'min'),
          ),
          DetailLine(label: 'Alertas de frío', value: '${hub.coldChainAlerts}'),
          DetailLine(
            label: 'Uso de la flota',
            value: formatKpiValue(hub.fleetUtilization, '%'),
          ),
          DetailLine(
            label: 'Drones disponibles',
            value: '${hub.availableDrones} de ${hub.totalDrones}',
          ),
        ],
      ),
    );
  }
}
