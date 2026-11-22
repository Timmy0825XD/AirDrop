import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import 'fleet_health_card.dart';
import 'fleet_incidents_card.dart';
import 'fleet_usage_card.dart';

enum OperatorMetric { usage, health, incidents }

/// Los datos del periodo permanecen disponibles sin recargar ni otro endpoint.
Future<void> showOperatorDashboardDetail(
  BuildContext context, {
  required OperatorMetric section,
  required FleetDashboard dashboard,
  required VoidCallback onOpenFleet,
}) => showAppSheet<void>(
  context,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Cerrar detalle',
              icon: const Icon(AppIcons.close),
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ),
          switch (section) {
            OperatorMetric.usage => FleetUsageCard(dashboard: dashboard),
            OperatorMetric.health => FleetHealthCard(
              dashboard: dashboard,
              onOpenFleet: () {
                Navigator.of(sheetContext).pop();
                onOpenFleet();
              },
            ),
            OperatorMetric.incidents => FleetIncidentsCard(
              dashboard: dashboard,
            ),
          },
        ],
      ),
    ),
  ),
);
