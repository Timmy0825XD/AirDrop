import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../orders/data/order_providers.dart';

/// Cuántos pedidos hay en cada bandeja del despachador. `null` en un
/// conteo mientras carga o si Nest no respondió (se pinta un guion).
class DispatcherCounts {
  const DispatcherCounts({
    required this.queue,
    required this.scheduled,
    required this.pendingLoad,
    required this.inFlight,
  });

  final int? queue;
  final int? scheduled;
  final int? pendingLoad;
  final int? inFlight;

  /// Lee las cuatro bandejas. Solo se llama con la central activa: con la
  /// central suspendida Nest las rechaza todas.
  static DispatcherCounts watch(WidgetRef ref) => DispatcherCounts(
    queue: ref.watch(queueProvider).value?.length,
    scheduled: ref.watch(scheduledProvider).value?.length,
    pendingLoad: ref.watch(pendingLoadProvider).value?.length,
    inFlight: ref.watch(inFlightProvider).value?.length,
  );

  static void refresh(WidgetRef ref) => ref
    ..invalidate(queueProvider)
    ..invalidate(scheduledProvider)
    ..invalidate(pendingLoadProvider)
    ..invalidate(inFlightProvider);
}
