import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../analytics/data/analytics_models.dart';
import '../../auth/data/auth_models.dart';
import '../../fleet/data/fleet_providers.dart';
import 'widgets/operator/operator_home_page.dart';
import 'widgets/operator/operator_home_values.dart';
import '../../notifications/data/notice_providers.dart';

/// La operación abarca todas las centrales; una revisión abre la del dron.
class FleetOperatorHome extends ConsumerStatefulWidget {
  const FleetOperatorHome({super.key, required this.user});

  final PublicUser user;

  @override
  ConsumerState<FleetOperatorHome> createState() => _FleetOperatorHomeState();
}

class _FleetOperatorHomeState extends ConsumerState<FleetOperatorHome> {
  int _days = 30;

  void _refresh() {
    ref.invalidate(assignedHubsProvider);
    ref.invalidate(operatorDronesProvider);
    ref.invalidate(fleetFlightsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(fleetDashboardProvider(AnalyticsQuery.lastDays(_days)));
    if (ref.read(fleetModelsProvider).hasError) {
      ref.invalidate(fleetModelsProvider);
    }
  }

  void _open(String path) {
    if (['/fleet', '/fleet/flights', '/profile'].contains(path)) {
      context.go(path);
    } else {
      context.push(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = OperatorHomeValues(
      hubs: ref.watch(assignedHubsProvider),
      drones: ref.watch(operatorDronesProvider),
      flights: ref.watch(fleetFlightsProvider),
      dashboard: ref.watch(
        fleetDashboardProvider(AnalyticsQuery.lastDays(_days)),
      ),
      models: ref.watch(fleetModelsProvider).value ?? const [],
    );
    return AutoRefresh(
      onTick: _refresh,
      child: OperatorHomePage(
        data: data,
        fullName: widget.user.fullName,
        unread: ref.watch(unreadCountProvider).value,
        days: _days,
        onDays: (days) => setState(() => _days = days),
        onOpen: _open,
        onRetry: _refresh,
        onDrone: (drone) {
          ref.read(fleetHubProvider.notifier).select(drone.hubId);
          _open('/fleet');
        },
      ),
    );
  }
}
