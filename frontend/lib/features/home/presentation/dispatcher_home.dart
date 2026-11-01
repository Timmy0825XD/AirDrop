import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import '../../orders/data/order_providers.dart';
import 'live_mission.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/dispatcher/dispatcher_tiles.dart';
import 'widgets/dispatcher/hub_notice.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/sign_out.dart';
import '../../notifications/data/notice_providers.dart';

/// Inicio del despachador: su central, las urgencias en cola como cifra
/// principal, el primer vuelo de su central como misión en curso (con su
/// telemetría), las bandejas en cuadrícula y los accesos de su central. Con
/// la central suspendida (o sin central) solo quedan Mi central y Mis
/// planes: Nest rechaza lo demás. Los números se refrescan cada 10 s.
class DispatcherHome extends ConsumerWidget {
  const DispatcherHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubState = ref.watch(myHubProvider);
    final hub = hubState.value;
    final active = hub?.isActive ?? false;
    final counts = active ? DispatcherCounts.watch(ref) : null;
    // El primer vuelo de su central, como misión en curso.
    final flying = active
        ? ref.watch(inFlightProvider).value?.firstOrNull
        : null;
    return AutoRefresh(
      onTick: () {
        ref.invalidate(unreadCountProvider);
        if (active) DispatcherCounts.refresh(ref);
      },
      child: HomePage(
        children: [
          HomeHeader(
            roleLabel: 'Despachador',
            fullName: user.fullName,
            tagline: _tagline(hubState),
            onSignOut: () => signOut(context, ref),
            onNotices: () => context.push('/notifications'),
            unreadNotices: ref.watch(unreadCountProvider).value,
          ),
          if (hubNoticeText(hubState) case final text?)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ErrorBanner(message: text),
            ),
          const SizedBox(height: 8),
          HomeSpotlight(
            value: counts?.queue,
            label: 'Urgencias\nen cola',
            status: StatusPill(
              label: active ? 'Central activa' : 'Sin operar',
              tone: active ? PillTone.positive : PillTone.attention,
            ),
          ),
          const SizedBox(height: 12),
          if (flying != null) LiveMission(order: flying),
          DispatcherTiles(hub: hub, counts: counts),
        ],
      ),
    );
  }

  static String _tagline(AsyncValue<Hub?> state) => switch (state) {
    AsyncValue(hasValue: true, hasError: false, value: final hub?) =>
      '${hub.name} · ${hub.isActive ? 'Activa' : 'Suspendida'}',
    AsyncValue(hasValue: true, hasError: false) => 'Sin central asignada',
    AsyncError(:final error) => ApiException.messageOf(error),
    _ => 'Cargando tu central…',
  };
}
