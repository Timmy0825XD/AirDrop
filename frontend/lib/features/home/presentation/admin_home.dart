import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_providers.dart';
import '../../users/data/user_providers.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/quick_tile.dart';
import 'widgets/sign_out.dart';

/// Resumen del administrador: las centrales activas como cifra principal
/// (el anillo dice qué parte de la red opera), las cuentas en cifras y
/// los accesos. Los números salen de las listas completas
/// (`allHubsProvider`, `allUsersProvider`); si Nest no responde se ven
/// guiones y los accesos siguen funcionando.
class AdminHome extends ConsumerWidget {
  const AdminHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(allHubsProvider).value;
    final users = ref.watch(allUsersProvider).value;
    final activeHubs = hubs?.where((hub) => hub.isActive).length;
    final suspendedHubs = hubs?.where((hub) => !hub.isActive).length;
    final suspendedUsers = users
        ?.where((a) => a.status == UserStatus.suspended)
        .length;
    return HomePage(
      children: [
        HomeHeader(
          roleLabel: 'Administrador',
          fullName: user.fullName,
          tagline: 'Así va la operación en Valledupar',
          onSignOut: () => signOut(context, ref),
        ),
        const SizedBox(height: 8),
        HomeSpotlight(
          value: activeHubs,
          label: 'Centrales\nactivas',
          progress: (hubs?.isEmpty ?? true) ? 0 : activeHubs! / hubs!.length,
          status: const StatusPill(
            label: 'Red AirDrop',
            tone: PillTone.neutral,
          ),
        ),
        const HomeLabel('Cuentas'),
        HomeGrid(
          startIndex: 3,
          children: [
            MetricTile(
              label: 'Cuentas activas',
              value: users?.where((a) => a.status == UserStatus.active).length,
              onTap: () => context.go('/users'),
            ),
            MetricTile(
              label: 'Suspendidas',
              value: suspendedHubs == null || suspendedUsers == null
                  ? null
                  : suspendedHubs + suspendedUsers,
              caption: 'Centrales y cuentas',
              color: StatusPill.colorOf(context, PillTone.negative),
            ),
          ],
        ),
        const HomeLabel('Gestionar'),
        HomeGrid(
          startIndex: 5,
          children: [
            QuickTile(
              title: 'Centrales',
              subtitle: 'Crea, ubica y suspende.',
              icon: Icons.home_work_outlined,
              count: hubs?.length,
              onTap: () => context.go('/hubs'),
            ),
            QuickTile(
              title: 'Cuentas institucionales',
              icon: Icons.badge_outlined,
              count: users?.length,
              onTap: () => context.go('/users'),
            ),
            // Nest ya tiene `/analytics/*`, pero el frontend todavía no
            // tiene su capa de datos: queda con candado.
            const QuickTile(
              title: 'Métricas',
              subtitle: 'Próximamente.',
              icon: Icons.insights_rounded,
              onTap: null,
            ),
          ],
        ),
      ],
    );
  }
}
