import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/bar_spark.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../fleet/data/fleet_models.dart';
import '../../fleet/data/fleet_providers.dart';
import '../../geofences/data/geofence_providers.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/quick_tile.dart';
import 'widgets/sign_out.dart';

/// Inicio del operador de flota: sus centrales, los drones disponibles de
/// la central elegida como cifra principal (el anillo dice qué parte de la
/// flota está lista), el estado de la flota en barras y los accesos.
class FleetOperatorHome extends ConsumerWidget {
  const FleetOperatorHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    final hubs = ref.watch(assignedHubsProvider).value;
    final drones = ref.watch(dronesProvider).value;
    final geofences = ref.watch(geofencesProvider).value;
    int? count(bool Function(DroneStatus s) test) =>
        drones?.where((d) => test(d.status)).length;
    final available = count((s) => s == DroneStatus.available);
    final total = drones?.length ?? 0;
    return HomePage(
      children: [
        HomeHeader(
          roleLabel: 'Operador de flota',
          fullName: user.fullName,
          tagline: _tagline(hub?.name, hubs?.length),
          onSignOut: () => signOut(context, ref),
        ),
        const SizedBox(height: 8),
        HomeSpotlight(
          value: available,
          label: 'Drones\ndisponibles',
          progress: total == 0 ? 0 : (available ?? 0) / total,
          status: StatusPill(
            label: (available ?? 0) > 0 ? 'Flota lista' : 'Sin drones libres',
            tone: (available ?? 0) > 0 ? PillTone.positive : PillTone.attention,
          ),
        ),
        const HomeLabel('Estado de la flota'),
        HomeGrid(
          startIndex: 3,
          children: [
            MetricTile(
              label: 'En misión',
              value: count((s) => s == DroneStatus.inMission),
              color: StatusPill.colorOf(context, PillTone.positive),
              onTap: () => context.go('/fleet/flights'),
              footer: BarSpark(
                height: 40,
                highlight: 1,
                values: [
                  for (final s in DroneStatus.values) count((d) => d == s) ?? 0,
                ],
              ),
            ),
            MetricTile(
              label: 'En taller',
              value: count(
                (s) =>
                    s == DroneStatus.maintenance ||
                    s == DroneStatus.outOfService,
              ),
              caption: 'Mantenimiento o fuera de servicio',
              color: StatusPill.colorOf(context, PillTone.negative),
              onTap: () => context.go('/fleet'),
            ),
          ],
        ),
        const HomeLabel('Gestionar'),
        HomeGrid(
          startIndex: 5,
          children: [
            QuickTile(
              title: 'Flota',
              subtitle: 'Drones, estados y mantenimiento.',
              icon: Icons.flight_rounded,
              count: drones?.length,
              onTap: () => context.go('/fleet'),
            ),
            QuickTile(
              title: 'Geovallas',
              subtitle: 'Zonas donde el dron no pasa.',
              icon: Icons.hexagon_outlined,
              count: geofences?.length,
              onTap: () => context.go('/geofences'),
            ),
          ],
        ),
      ],
    );
  }

  static String _tagline(String? hubName, int? hubCount) {
    if (hubCount == 0) return 'Sin centrales asignadas';
    if (hubName == null) return 'Cargando tus centrales…';
    return hubCount == 1 ? hubName : '$hubName y ${hubCount! - 1} más';
  }
}
