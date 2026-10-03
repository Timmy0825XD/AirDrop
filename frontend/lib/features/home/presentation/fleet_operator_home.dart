import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_shell.dart';

class FleetOperatorHome extends StatelessWidget {
  const FleetOperatorHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      user: user,
      body: Column(
        children: [
          HomeActionCard(
            title: 'Flota',
            subtitle: 'Drones, estados y mantenimiento de tus centrales.',
            icon: Icons.flight_takeoff,
            onTap: () => context.go('/fleet'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Geovallas',
            subtitle: 'Administra las zonas restringidas.',
            icon: Icons.polyline_outlined,
            onTap: () => context.go('/geofences'),
          ),
        ],
      ),
    );
  }
}
