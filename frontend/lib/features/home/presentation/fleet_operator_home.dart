import 'package:flutter/material.dart';

import '../../auth/data/auth_models.dart';
import 'widgets/home_action_card.dart';
import 'widgets/home_shell.dart';
import 'widgets/module_preview.dart';

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
            subtitle: 'Consulta la disponibilidad de los drones.',
            icon: Icons.flight_takeoff,
            onTap: () => showModulePreview(context, 'Flota'),
          ),
          const SizedBox(height: 12),
          HomeActionCard(
            title: 'Geovallas',
            subtitle: 'Administra las zonas restringidas.',
            icon: Icons.polyline_outlined,
            onTap: () => showModulePreview(context, 'Geovallas'),
          ),
        ],
      ),
    );
  }
}
