import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_banner.dart';
import '../../hubs/data/hub_models.dart';
import 'widgets/home_action_card.dart';

class DispatcherCards extends StatelessWidget {
  const DispatcherCards({super.key, this.hub, this.errorMessage});

  final Hub? hub;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final inventoryEnabled = hub?.isActive ?? false;
    return Column(
      children: [
        if (errorMessage != null) ...[
          ErrorBanner(message: errorMessage!),
          const SizedBox(height: 12),
        ],
        HomeActionCard(
          title: 'Central',
          subtitle: _centralSubtitle(hub),
          icon: Icons.home_work_outlined,
          onTap: hub == null ? null : () => context.go('/hubs/me'),
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Inventario',
          subtitle: inventoryEnabled
              ? 'Insumos, lotes y vencimientos de tu central.'
              : _inventorySubtitle(hub),
          icon: Icons.inventory_2_outlined,
          onTap: inventoryEnabled ? () => context.go('/inventory') : null,
        ),
      ],
    );
  }

  String _centralSubtitle(Hub? hub) {
    if (hub == null) return 'No tienes una central registrada.';
    final state = hub.isActive ? 'Activa' : 'Suspendida';
    return '${hub.name} · $state';
  }

  /// La central suspendida es un estado del sistema, no una omisión:
  /// el mensaje viene de `HubsService.requireActive` en Nest.
  String _inventorySubtitle(Hub? hub) {
    if (hub == null) return 'No tienes una central asignada.';
    return 'La central está suspendida.';
  }
}
