import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../auth/data/auth_models.dart';
import '../../hubs/data/hub_providers.dart';
import '../../notifications/data/notice_providers.dart';
import '../../orders/data/order_providers.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/dispatcher/dispatcher_home_page.dart';
import 'widgets/dispatcher/dispatcher_home_values.dart';

/// Una sola lectura de cada bandeja y el mismo refresco de la operación.
class DispatcherHome extends ConsumerWidget {
  const DispatcherHome({super.key, required this.user});
  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(myHubProvider);
    final active = !hub.hasError && hub.value?.isActive == true;
    final data = DispatcherHomeValues(
      hub: hub,
      queue: active ? ref.watch(queueProvider) : const AsyncLoading(),
      pendingLoad: active
          ? ref.watch(pendingLoadProvider)
          : const AsyncLoading(),
      scheduled: active ? ref.watch(scheduledProvider) : const AsyncLoading(),
      incoming: active ? ref.watch(incomingProvider) : const AsyncLoading(),
      flights: active ? ref.watch(inFlightProvider) : const AsyncLoading(),
    );
    void refresh() {
      ref.invalidate(myHubProvider);
      ref.invalidate(unreadCountProvider);
      if (active) DispatcherCounts.refresh(ref);
    }

    void open(String path) {
      if (path == '/orders/queue') {
        context.go(path);
      } else {
        context.push(path);
      }
    }

    return AutoRefresh(
      onTick: refresh,
      child: DispatcherHomePage(
        data: data,
        fullName: user.fullName,
        unread: ref.watch(unreadCountProvider).value,
        onOpen: open,
        onRetry: refresh,
      ),
    );
  }
}
