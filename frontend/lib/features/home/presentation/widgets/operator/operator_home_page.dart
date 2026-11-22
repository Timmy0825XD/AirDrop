import 'package:flutter/material.dart';

import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_models.dart';
import '../home_page.dart';
import '../home_status_card.dart';
import 'operator_home_content.dart';
import 'operator_home_header.dart';
import 'operator_home_values.dart';

class OperatorHomePage extends StatelessWidget {
  const OperatorHomePage({
    super.key,
    required this.data,
    required this.fullName,
    required this.days,
    required this.onDays,
    required this.onOpen,
    required this.onDrone,
    required this.onRetry,
    this.unread,
  });
  final OperatorHomeValues data;
  final String fullName;
  final int days;
  final int? unread;
  final ValueChanged<int> onDays;
  final ValueChanged<String> onOpen;
  final ValueChanged<Drone> onDrone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => HomePage(
    children: [
      OperatorHomeHeader(
        fullName: fullName,
        scope: data.scope,
        unread: unread,
        onNotices: () => onOpen('/notifications'),
      ),
      const SizedBox(height: 24),
      if (data.hubs.value?.isNotEmpty ?? false)
        OperatorHomeContent(
          data: data,
          days: days,
          onDays: onDays,
          onOpen: onOpen,
          onDrone: onDrone,
          onRetry: onRetry,
        )
      else
        _OperatorHubState(data: data, onRetry: onRetry, onOpen: onOpen),
    ],
  );
}

class _OperatorHubState extends StatelessWidget {
  const _OperatorHubState({
    required this.data,
    required this.onRetry,
    required this.onOpen,
  });
  final OperatorHomeValues data;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (data.hubsFailed) {
      return HomeStatusCard(
        title: 'No pudimos cargar tus centrales',
        message: data.error!,
        scene: CorridorScene.broken,
        icon: AppIcons.unavailable,
        action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      );
    }
    if (data.hubs.value == null) return const SkeletonList();
    return HomeStatusCard(
      title: 'Sin centrales asignadas',
      message:
          'Cuando te asignen una central, aquí verás su flota y sus vuelos.',
      icon: AppIcons.hub,
      action: TextButton(
        onPressed: () => onOpen('/profile'),
        child: const Text('Ver mi perfil'),
      ),
    );
  }
}
