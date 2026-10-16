import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import 'widgets/dispatcher/dispatcher_actions.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/dispatcher/hub_notice.dart';
import 'widgets/home_stats_card.dart';
import 'widgets/role_hero.dart';
import 'widgets/sign_out.dart';

/// Inicio del despachador: su central en el encabezado, cuánto hay en cola,
/// por cargar y en vuelo sobre la curva, y los accesos agrupados. Con la
/// central suspendida (o sin central) solo quedan Mi central y Mis planes:
/// Nest rechaza lo demás. Los números se refrescan cada 10 s.
class DispatcherHome extends ConsumerWidget {
  const DispatcherHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubState = ref.watch(myHubProvider);
    final hub = hubState.asData?.value;
    final active = hub?.isActive ?? false;
    final counts = active ? DispatcherCounts.watch(ref) : null;
    return Scaffold(
      body: AutoRefresh(
        onTick: () => active ? DispatcherCounts.refresh(ref) : null,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(user: user, hubState: hubState, counts: counts),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hubNoticeText(hubState) case final text?)
                    RiseIn(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: ErrorBanner(message: text),
                      ),
                    ),
                  DispatcherActions(hub: hub, counts: counts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El encabezado con la central y los números montados sobre la curva.
class _Hero extends ConsumerWidget {
  const _Hero({
    required this.user,
    required this.hubState,
    required this.counts,
  });

  final PublicUser user;
  final AsyncValue<Hub?> hubState;
  final DispatcherCounts? counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        RoleHero(
          roleLabel: 'Despachador',
          firstName: RoleHero.firstNameOf(user.fullName),
          tagline: _tagline(hubState),
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
            child: HomeStatsCard(
              stats: [
                HomeStat(
                  value: counts?.queue,
                  label: 'En cola',
                  color: colors.error,
                ),
                HomeStat(
                  value: counts?.pendingLoad,
                  label: 'Por cargar',
                  color: colors.primary,
                ),
                HomeStat(
                  value: counts?.inFlight,
                  label: 'En vuelo',
                  color: colors.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _tagline(AsyncValue<Hub?> state) => switch (state) {
    AsyncData(value: final hub?) =>
      '${hub.name} · ${hub.isActive ? 'Activa' : 'Suspendida'}',
    AsyncData() => 'Sin central asignada',
    AsyncError(:final error) => ApiException.messageOf(error),
    _ => 'Cargando tu central…',
  };
}
