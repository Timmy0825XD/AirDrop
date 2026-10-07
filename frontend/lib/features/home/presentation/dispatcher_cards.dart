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
    final active = hub?.isActive ?? false;
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
          subtitle: active
              ? 'Insumos, lotes y vencimientos de tu central.'
              : _inactiveSubtitle(hub),
          icon: Icons.inventory_2_outlined,
          onTap: active ? () => context.go('/inventory') : null,
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Cola de urgencias',
          subtitle: active
              ? 'Urgencias en recibido de tu central.'
              : _inactiveSubtitle(hub),
          icon: Icons.pending_actions_outlined,
          onTap: active ? () => context.go('/orders/queue') : null,
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Programados',
          subtitle: active
              ? 'Entregas periódicas que tu central puede soltar.'
              : _inactiveSubtitle(hub),
          icon: Icons.schedule_outlined,
          onTap: active ? () => context.go('/orders/scheduled') : null,
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Pedir a otra central',
          subtitle: active
              ? 'Urgencia o abastecimiento desde otra central activa.'
              : _inactiveSubtitle(hub),
          icon: Icons.swap_horiz_outlined,
          onTap: active ? () => _pickHubSource(context) : null,
        ),
        const SizedBox(height: 12),
        HomeActionCard(
          title: 'Mis planes',
          subtitle: 'Fechas, extensión y cancelación.',
          icon: Icons.event_repeat_outlined,
          onTap: () => context.go('/orders/plans'),
        ),
      ],
    );
  }

  String _centralSubtitle(Hub? hub) {
    if (hub == null) return 'No tienes una central registrada.';
    final state = hub.isActive ? 'Activa' : 'Suspendida';
    return '${hub.name} · $state';
  }

  String _inactiveSubtitle(Hub? hub) {
    if (hub == null) return 'No tienes una central asignada.';
    return 'La central está suspendida.';
  }

  void _pickHubSource(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emergency_outlined),
              title: const Text('Urgencia'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.go('/orders/hub-emergency');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Abastecimiento'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.go('/orders/hub-plans/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}
