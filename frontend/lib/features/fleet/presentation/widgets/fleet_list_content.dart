import 'package:flutter/material.dart';
import '../../../../core/widgets/corridor_art.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/warning_banner.dart';
import '../../../../theme/app_icons.dart';
import '../../../home/presentation/widgets/home_status_card.dart';
import '../../data/fleet_models.dart';
import 'drone_tile.dart';
import 'fleet_list_values.dart';

class FleetListContent extends StatelessWidget {
  const FleetListContent({
    super.key,
    required this.data,
    required this.onManage,
    required this.onOpen,
    required this.onClear,
    required this.onRetry,
  });
  final FleetListValues data;
  final ValueChanged<Drone> onManage;
  final ValueChanged<String> onOpen;
  final VoidCallback onClear, onRetry;
  @override
  Widget build(BuildContext context) {
    if (data.loadingHubs || (data.hub != null && data.loadingDrones)) {
      return const SliverToBoxAdapter(child: SkeletonList());
    }
    if (data.hub == null || data.rows == null || data.shown.isEmpty) {
      return SliverToBoxAdapter(
        child: _FleetListState(
          data: data,
          onOpen: onOpen,
          onClear: onClear,
          onRetry: onRetry,
        ),
      );
    }
    final shown = data.shown;
    return SliverMainAxisGroup(
      slivers: [
        if (data.error case final message?)
          SliverToBoxAdapter(
            child: _FleetRetryNotice(message: message, onRetry: onRetry),
          ),
        SliverList.separated(
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final drone = shown[index];
            return DroneTile(
              drone: drone,
              modelName: data.modelName(drone.droneModelId),
              onActions: data.canManage && drone.status.isOperable
                  ? () => onManage(drone)
                  : null,
              onFlight: drone.status.isInMission
                  ? () => onOpen(data.flightPath(drone))
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _FleetListState extends StatelessWidget {
  const _FleetListState({
    required this.data,
    required this.onOpen,
    required this.onClear,
    required this.onRetry,
  });
  final FleetListValues data;
  final ValueChanged<String> onOpen;
  final VoidCallback onClear, onRetry;
  @override
  Widget build(BuildContext context) {
    if (data.error case final error?) {
      return HomeStatusCard(
        title: 'No pudimos actualizar la flota',
        message: error,
        icon: AppIcons.unavailable,
        scene: CorridorScene.broken,
        action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      );
    }
    if (data.hub == null) {
      return const HomeStatusCard(
        title: 'Sin centrales asignadas',
        message:
            'Cuando te asignen una central, podrás consultar y gestionar sus drones.',
        icon: AppIcons.hub,
      );
    }
    final noDrones = data.rows!.isEmpty;
    return HomeStatusCard(
      title: noDrones ? 'Tu flota empieza aquí' : 'No encontramos drones',
      message: noDrones
          ? 'Aún no hay drones en esta central.'
          : 'Prueba con otro identificador, modelo o estado.',
      icon: AppIcons.drone,
      action: !noDrones
          ? TextButton(onPressed: onClear, child: const Text('Limpiar filtros'))
          : data.canManage
          ? TextButton(
              onPressed: () => onOpen('/fleet/new'),
              child: const Text('Añadir dron'),
            )
          : null,
    );
  }
}

class _FleetRetryNotice extends StatelessWidget {
  const _FleetRetryNotice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      WarningBanner(icon: AppIcons.unavailable, message: message),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}
