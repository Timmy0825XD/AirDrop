import 'package:flutter/material.dart';

import '../../../core/widgets/error_banner.dart';
import '../../hubs/data/hub_models.dart';
import 'widgets/home_action_card.dart';
import 'widgets/module_preview.dart';

class DispatcherCards extends StatelessWidget {
  const DispatcherCards({super.key, this.hub, this.errorMessage});

  final HubSummary? hub;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final inventoryEnabled = hub?.isApproved ?? false;
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
          onTap: () => showModulePreview(context, 'Central'),
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Inventario',
          subtitle: inventoryEnabled
              ? 'Módulo disponible en la siguiente fase.'
              : 'Se habilita cuando la central esté aprobada.',
          icon: Icons.inventory_2_outlined,
          onTap: inventoryEnabled
              ? () => showModulePreview(context, 'Inventario')
              : null,
        ),
      ],
    );
  }

  String _centralSubtitle(HubSummary? hub) {
    if (hub == null) return 'No tienes una central registrada.';
    return switch (hub.status) {
      HubStatus.approved => '${hub.name} · Aprobada',
      HubStatus.pendingApproval => '${hub.name} · Pendiente de aprobación',
      HubStatus.rejected => '${hub.name} · Rechazada',
    };
  }
}
