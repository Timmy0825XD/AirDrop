import 'package:flutter/material.dart';

import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_status_card.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../../hubs/presentation/widgets/hub_labels.dart';
import '../requester_profile/requester_profile_group.dart';

class OperatorProfileHubs extends StatelessWidget {
  const OperatorProfileHubs({
    super.key,
    required this.hubs,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
  });
  final List<Hub>? hubs;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Hub> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = hubs;
    if (loading && rows == null) return const Skeleton(height: 144, radius: 20);
    if (rows == null || rows.isEmpty) {
      return HomeStatusCard(
        title: error != null
            ? 'No pudimos cargar tus centrales'
            : 'Sin centrales asignadas',
        message:
            error ?? 'El administrador puede asignarte centrales para operar.',
        icon: AppIcons.hub,
        action: error == null
            ? null
            : TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error case final message?) ...[
          _HubsRetryNotice(message: message, onRetry: onRetry),
          const SizedBox(height: 8),
        ],
        RequesterProfileGroup(
          items: [
            for (final hub in rows)
              MenuItem(
                title: hub.name,
                subtitle: hub.isActive
                    ? 'Central asignada'
                    : 'Central asignada · ${HubLabels.status(hub.status).toLowerCase()}',
                icon: AppIcons.hub,
                onTap: () => onOpen(hub),
              ),
          ],
        ),
      ],
    );
  }
}

class _HubsRetryNotice extends StatelessWidget {
  const _HubsRetryNotice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'No pudimos actualizar tus centrales.\n$message',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ),
    ],
  );
}
