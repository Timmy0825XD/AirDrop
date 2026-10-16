import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../fleet/data/fleet_models.dart';
import '../../fleet/data/fleet_providers.dart';
import '../../geofences/data/geofence_providers.dart';
import 'widgets/home_access_card.dart';
import 'widgets/home_stats_card.dart';
import 'widgets/role_hero.dart';
import 'widgets/sign_out.dart';

/// Inicio del operador de flota: sus centrales en el encabezado, cómo
/// están los drones de la central elegida (disponibles, en misión, en
/// taller) y los accesos a la flota y a las geovallas.
class FleetOperatorHome extends ConsumerWidget {
  const FleetOperatorHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    final hubs = ref.watch(assignedHubsProvider).asData?.value;
    final drones = ref.watch(dronesProvider).asData?.value;
    final geofences = ref.watch(geofencesProvider).asData?.value;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              RoleHero(
                roleLabel: 'Operador de flota',
                firstName: RoleHero.firstNameOf(user.fullName),
                tagline: _tagline(hub?.name, hubs?.length),
                onProfile: () => context.push('/profile'),
                onSignOut: () => signOut(context, ref),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  RoleHero.heightFor(context) - 46,
                  20,
                  0,
                ),
                child: RiseIn(
                  delay: const Duration(milliseconds: 150),
                  child: _DroneStats(drones: drones),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
            child: _OperatorActions(
              droneCount: drones?.length,
              geofenceCount: geofences?.length,
            ),
          ),
        ],
      ),
    );
  }

  static String _tagline(String? hubName, int? hubCount) {
    if (hubCount == 0) return 'Sin centrales asignadas';
    if (hubName == null) return 'Cargando tus centrales…';
    return hubCount == 1 ? hubName : '$hubName y ${hubCount! - 1} más';
  }
}

/// Disponibles, en misión y en taller (mantenimiento o fuera de servicio).
class _DroneStats extends StatelessWidget {
  const _DroneStats({required this.drones});

  final List<Drone>? drones;

  int? _count(bool Function(DroneStatus s) test) =>
      drones?.where((d) => test(d.status)).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return HomeStatsCard(
      stats: [
        HomeStat(
          value: _count((s) => s == DroneStatus.available),
          label: 'Disponibles',
          color: colors.tertiary,
        ),
        HomeStat(
          value: _count((s) => s == DroneStatus.inMission),
          label: 'En misión',
          color: colors.secondary,
        ),
        HomeStat(
          value: _count(
            (s) =>
                s == DroneStatus.maintenance || s == DroneStatus.outOfService,
          ),
          label: 'En taller',
          color: colors.error,
        ),
      ],
    );
  }
}

class _OperatorActions extends StatelessWidget {
  const _OperatorActions({
    required this.droneCount,
    required this.geofenceCount,
  });

  final int? droneCount;
  final int? geofenceCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiseIn(
          delay: const Duration(milliseconds: 220),
          child: Text(
            'GESTIONAR',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 12),
        RiseIn(
          delay: const Duration(milliseconds: 280),
          child: HomeAccessCard(
            title: 'Flota',
            subtitle: 'Drones, estados y mantenimiento.',
            icon: Icons.flight_takeoff_rounded,
            tone: colors.secondary,
            count: droneCount,
            onTap: () => context.go('/fleet'),
          ),
        ),
        const SizedBox(height: 10),
        RiseIn(
          delay: const Duration(milliseconds: 350),
          child: HomeAccessCard(
            title: 'Geovallas',
            subtitle: 'Zonas por donde el dron no puede pasar.',
            icon: Icons.polyline_outlined,
            tone: colors.error,
            count: geofenceCount,
            onTap: () => context.go('/geofences'),
          ),
        ),
      ],
    );
  }
}
