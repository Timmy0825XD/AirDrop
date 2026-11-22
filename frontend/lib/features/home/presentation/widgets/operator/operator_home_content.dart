import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_models.dart';
import 'dashboard_period.dart';
import 'operator_dashboard.dart';
import 'operator_fleet_summary.dart';
import 'operator_flights.dart';
import 'operator_home_values.dart';
import 'operator_tasks.dart';

class OperatorHomeContent extends StatelessWidget {
  const OperatorHomeContent({
    super.key,
    required this.data,
    required this.days,
    required this.onDays,
    required this.onOpen,
    required this.onDrone,
    required this.onRetry,
  });
  final OperatorHomeValues data;
  final int days;
  final ValueChanged<int> onDays;
  final ValueChanged<String> onOpen;
  final ValueChanged<Drone> onDrone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final hub in data.hubs.value!.where((h) => !h.isActive)) ...[
        WarningBanner(
          icon: AppIcons.lock,
          message:
              '${hub.name} está suspendida. Su flota se puede consultar; los cambios están bloqueados.',
        ),
        const SizedBox(height: 16),
      ],
      OperatorFleetSummary(data: data),
      const SizedBox(height: 24),
      OperatorTasks(
        data: data,
        onOpen: onOpen,
        onDrone: onDrone,
        onRetry: onRetry,
      ),
      const SizedBox(height: 24),
      OperatorFlights(data: data, onOpen: onOpen, onRetry: onRetry),
      const SizedBox(height: 24),
      _PeriodHeading(days: days, onDays: onDays),
      const SizedBox(height: 12),
      OperatorDashboard(
        state: data.dashboard,
        onOpenFleet: () => onOpen('/fleet'),
        onRetry: onRetry,
      ),
    ],
  );
}

class _PeriodHeading extends StatelessWidget {
  const _PeriodHeading({required this.days, required this.onDays});
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 12,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        'Tu flota en el periodo',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      DashboardPeriod(days: days, onDays: onDays),
    ],
  );
}
