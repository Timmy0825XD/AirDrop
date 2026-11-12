import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/clock/sim_clock.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_models.dart';
import '../../hubs/data/hub_providers.dart';
import '../../hubs/presentation/widgets/hub_outage.dart';
import '../../orders/data/order_providers.dart';
import 'live_mission.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/dispatcher/dispatcher_tiles.dart';
import 'widgets/dispatcher/hub_notice.dart';
import 'widgets/dispatcher/next_up.dart';
import 'widgets/dispatcher/next_up_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'widgets/home_spotlight.dart';
import '../../notifications/data/notice_providers.dart';

/// Inicio del despachador: su central, las urgencias en cola como cifra
/// principal, el primer vuelo de su central como misión en curso (con su
/// telemetría), "Para atender ahora" (la urgencia más vieja, el dron que
/// espera la carga y el próximo programado), las bandejas en cuadrícula y
/// los accesos de su central que no están en la barra. Con
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
    final outage = hubOutageNote(hub);
    final counts = active ? DispatcherCounts.watch(ref) : null;
    // El primer vuelo de su central, como misión en curso.
    final flying = active
        ? ref.watch(inFlightProvider).value?.firstOrNull
        : null;
    return AutoRefresh(
      onTick: () {
        ref.invalidate(unreadCountProvider);
        // El apagón lo provoca la consola: la central se vuelve a leer.
        ref.invalidate(myHubProvider);
        if (active) DispatcherCounts.refresh(ref);
      },
      child: HomePage(
        children: [
          HomeHeader(
            roleLabel: 'Despachador',
            fullName: user.fullName,
            tagline: _tagline(hubState),
            onProfile: () => context.push('/profile'),
            onNotices: () => context.push('/notifications'),
            unreadNotices: ref.watch(unreadCountProvider).value,
          ),
          if (hubNoticeText(hubState) case final text?)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ErrorBanner(message: text),
            ),
          if (outage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: HubOutageBanner(note: outage),
            ),
          const SizedBox(height: 8),
          HomeSpotlight(
            value: counts?.queue,
            label: 'Urgencias\nen cola',
            status: StatusPill(
              label: !active
                  ? 'Sin operar'
                  : outage != null
                  ? 'Sin energía'
                  : 'Central activa',
              tone: active && outage == null
                  ? PillTone.positive
                  : PillTone.attention,
            ),
          ),
          const SizedBox(height: 12),
          if (flying != null) LiveMission(order: flying),
          if (active)
            NextUpCard(
              items: dispatcherNextUp(
                queue: ref.watch(queueProvider).value,
                pendingLoad: ref.watch(pendingLoadProvider).value,
                scheduled: ref.watch(scheduledProvider).value,
                now: simClock.now(),
              ),
              onOpen: (id) => context.push('/orders/$id'),
            ),
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
