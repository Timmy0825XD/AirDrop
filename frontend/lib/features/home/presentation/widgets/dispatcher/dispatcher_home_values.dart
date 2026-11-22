import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/clock/sim_clock.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../../orders/data/order_models.dart';
import 'dispatcher_counts.dart';
import 'next_up.dart';

/// Datos de las bandejas: un error o una carga inicial nunca equivalen a cero.
class DispatcherHomeValues {
  const DispatcherHomeValues({
    required this.hub,
    this.queue = const AsyncLoading(),
    this.pendingLoad = const AsyncLoading(),
    this.scheduled = const AsyncLoading(),
    this.incoming = const AsyncLoading(),
    this.flights = const AsyncLoading(),
  });

  final AsyncValue<Hub?> hub;
  final AsyncValue<List<QueueEntry>> queue;
  final AsyncValue<List<Order>> pendingLoad, incoming, flights;
  final AsyncValue<List<ScheduledEntry>> scheduled;

  bool get active => !hub.hasError && hub.value?.isActive == true;
  bool get hubFailed => hub.hasError;
  bool get hubLoading => !hub.hasValue && !hub.hasError;
  Order? get firstFlight =>
      flights.hasError ? null : flights.value?.firstOrNull;
  String get hubStatus {
    if (hubFailed) return 'Sin actualizar';
    if (hubLoading) return 'Cargando central';
    if (hub.value == null) return 'Sin central';
    if (!active) return 'Central suspendida';
    if (!hub.value!.poweredAt(simClock.now())) return 'Sin energía';
    return 'Central activa';
  }

  String get hubName =>
      hub.value?.name ??
      (hubFailed
          ? 'Tu central'
          : hub.hasValue
          ? 'Sin central asignada'
          : 'Cargando tu central…');
  List<AsyncValue<Object?>> get _tasks => [
    queue,
    pendingLoad,
    incoming,
    scheduled,
  ];
  bool get loading => _tasks.any((s) => !s.hasValue && !s.hasError);
  String? get error {
    for (final state in _tasks) {
      if (state.hasError) return ApiException.messageOf(state.error!);
    }
    return null;
  }

  List<NextUpItem> get tasks => dispatcherNextUp(
    queue: queue.value,
    pendingLoad: pendingLoad.value,
    scheduled: scheduled.value,
    incoming: incoming.value,
    now: simClock.now(),
  );

  DispatcherCounts get counts => DispatcherCounts(
    queue: queue.hasError ? null : queue.value?.length,
    pendingLoad: pendingLoad.hasError ? null : pendingLoad.value?.length,
    scheduled: scheduled.hasError ? null : scheduled.value?.length,
    inFlight: flights.hasError ? null : flights.value?.length,
    toReceive: incoming.hasError
        ? null
        : incoming.value
              ?.where((o) => o.status == OrderStatus.awaitingDelivery)
              .length,
  );
}
