import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_shell.dart';

class RequesterHome extends StatelessWidget {
  const RequesterHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      body: Column(
        children: [
          HomeActionCard(
            title: 'Urgencia',
            subtitle: 'Pide un medicamento a tu dirección.',
            icon: Icons.emergency_outlined,
            onTap: () => context.go('/orders/emergency'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Entrega periódica',
            subtitle: 'Programa una entrega a tu dirección.',
            icon: Icons.calendar_month_outlined,
            onTap: () => context.go('/orders/plans/new'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Mis planes',
            subtitle: 'Fechas, extensión y cancelación.',
            icon: Icons.event_repeat_outlined,
            onTap: () => context.go('/orders/plans'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Historial',
            subtitle: 'Estado de tus pedidos.',
            icon: Icons.history_outlined,
            onTap: () => context.go('/orders/mine'),
          ),
        ],
      ),
    );
  }
}
