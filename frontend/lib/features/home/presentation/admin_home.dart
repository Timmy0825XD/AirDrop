import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import '../../users/data/user_providers.dart';
import 'widgets/admin/admin_metrics_card.dart';
import 'widgets/home_access_card.dart';
import 'widgets/home_stats_card.dart';
import 'widgets/role_hero.dart';
import 'widgets/sign_out.dart';

/// Inicio del administrador: el encabezado con el saludo, los números del
/// día sobre la curva y los accesos a centrales y cuentas. Los números
/// salen de las listas completas (`allHubsProvider`, `allUsersProvider`);
/// si Nest no responde, se ven guiones y los accesos siguen funcionando.
class AdminHome extends ConsumerWidget {
  const AdminHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(allHubsProvider).value;
    final users = ref.watch(allUsersProvider).value;
    final heroHeight = RoleHero.heightFor(context);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              RoleHero(
                roleLabel: 'Administrador',
                firstName: RoleHero.firstNameOf(user.fullName),
                tagline: 'Así va la operación en Valledupar',
                onProfile: () => context.push('/profile'),
                onSignOut: () => signOut(context, ref),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, heroHeight - 46, 20, 0),
                child: RiseIn(
                  delay: const Duration(milliseconds: 150),
                  child: _AdminStats(hubs: hubs, users: users),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
            child: _AdminActions(
              hubCount: hubs?.length,
              userCount: users?.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  const _AdminActions({required this.hubCount, required this.userCount});

  final int? hubCount;
  final int? userCount;

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
            title: 'Centrales',
            subtitle: 'Crea, ubica en el mapa y suspende.',
            icon: Icons.domain_add_outlined,
            tone: colors.primary,
            count: hubCount,
            onTap: () => context.go('/hubs'),
          ),
        ),
        const SizedBox(height: 12),
        RiseIn(
          delay: const Duration(milliseconds: 350),
          child: HomeAccessCard(
            title: 'Cuentas institucionales',
            subtitle: 'Despachadores y operadores de flota.',
            icon: Icons.groups_outlined,
            tone: colors.secondary,
            count: userCount,
            onTap: () => context.go('/users'),
          ),
        ),
        const SizedBox(height: 12),
        const RiseIn(
          delay: Duration(milliseconds: 420),
          child: AdminMetricsCard(),
        ),
      ],
    );
  }
}

/// Centrales activas, cuentas activas y todo lo suspendido.
class _AdminStats extends StatelessWidget {
  const _AdminStats({required this.hubs, required this.users});

  final List<Hub>? hubs;
  final List<PublicUser>? users;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suspendedHubs = hubs?.where((hub) => !hub.isActive).length;
    final suspendedUsers = users
        ?.where((account) => account.status == UserStatus.suspended)
        .length;
    return HomeStatsCard(
      stats: [
        HomeStat(
          value: hubs?.where((hub) => hub.isActive).length,
          label: 'Centrales activas',
          color: colors.primary,
        ),
        HomeStat(
          value: users?.where((a) => a.status == UserStatus.active).length,
          label: 'Cuentas activas',
          color: colors.onSurface,
        ),
        HomeStat(
          value: suspendedHubs == null || suspendedUsers == null
              ? null
              : suspendedHubs + suspendedUsers,
          label: 'Suspendidas',
          color: colors.error,
        ),
      ],
    );
  }
}
