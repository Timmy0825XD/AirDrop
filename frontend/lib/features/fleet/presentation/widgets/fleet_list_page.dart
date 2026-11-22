import 'package:flutter/material.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/warning_banner.dart';
import '../../../../theme/app_icons.dart';
import '../../data/fleet_models.dart';
import 'fleet_list_content.dart';
import 'fleet_list_header.dart';
import 'fleet_list_values.dart';

class FleetListPage extends StatelessWidget {
  const FleetListPage({
    super.key,
    required this.data,
    required this.search,
    required this.onQuery,
    required this.onFilter,
    required this.onHub,
    required this.onOpen,
    required this.onManage,
    required this.onClear,
    required this.onRefresh,
  });
  final FleetListValues data;
  final TextEditingController search;
  final ValueChanged<String> onQuery, onHub, onOpen;
  final ValueChanged<FleetFilter> onFilter;
  final ValueChanged<Drone> onManage;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Flota',
    subtitle: 'Drones de tus centrales',
    onRefresh: onRefresh,
    trailing: data.canManage
        ? OutlinedButton.icon(
            onPressed: () => onOpen('/fleet/new'),
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Añadir'),
          )
        : null,
    slivers: [
      if (data.hub != null)
        SliverToBoxAdapter(
          child: FleetListHeader(
            data: data,
            search: search,
            onQuery: onQuery,
            onFilter: onFilter,
            onHub: onHub,
          ),
        ),
      if (data.hub != null && !data.canManage)
        const SliverToBoxAdapter(child: _SuspendedHubNotice()),
      FleetListContent(
        data: data,
        onManage: onManage,
        onOpen: onOpen,
        onClear: onClear,
        onRetry: () => onRefresh(),
      ),
    ],
  );
}

class _SuspendedHubNotice extends StatelessWidget {
  const _SuspendedHubNotice();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: WarningBanner(
      icon: AppIcons.lock,
      message:
          'La central está suspendida. Puedes consultar sus drones, pero no modificarlos.',
    ),
  );
}
