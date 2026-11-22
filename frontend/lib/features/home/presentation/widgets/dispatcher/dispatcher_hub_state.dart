import 'package:flutter/material.dart';

import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import 'dispatcher_home_values.dart';
import '../home_status_card.dart';
import 'hub_notice.dart';

class DispatcherHubState extends StatelessWidget {
  const DispatcherHubState({
    super.key,
    required this.data,
    required this.onRetry,
  });
  final DispatcherHomeValues data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (data.hubLoading) {
      return Semantics(
        label: 'Cargando tu central',
        child: const Skeleton(height: 180, radius: 20),
      );
    }
    final failed = data.hubFailed;
    return HomeStatusCard(
      title: failed
          ? 'No pudimos consultar tu central'
          : data.hub.value == null
          ? 'Aún no tienes central'
          : 'Central suspendida',
      message: hubNoticeText(data.hub) ?? '',
      icon: failed ? AppIcons.unavailable : AppIcons.hub,
      scene: failed ? CorridorScene.broken : CorridorScene.empty,
      action: failed
          ? TextButton(onPressed: onRetry, child: const Text('Reintentar'))
          : null,
    );
  }
}
