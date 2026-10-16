import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import 'local_order_repository.dart';
import 'order_models.dart';
import 'order_repository.dart';
import 'remote_order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return switch (appDataSource) {
    DataSource.local => LocalOrderRepository(),
    DataSource.remote => RemoteOrderRepository(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

/// Catálogo sin `hubId` para el solicitante.
final catalogProvider = FutureProvider<List<CatalogOffer>>((ref) {
  return ref.watch(orderRepositoryProvider).catalog();
});

/// Catálogo con stock de una central, para el despachador.
final hubCatalogProvider = FutureProvider.family<List<CatalogOffer>, String>((
  ref,
  hubId,
) {
  return ref.watch(orderRepositoryProvider).catalog(hubId: hubId);
});

final mineProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).listMine();
});

final plansProvider = FutureProvider<List<DeliveryPlan>>((ref) {
  return ref.watch(orderRepositoryProvider).listPlans();
});

final queueProvider = FutureProvider<List<QueueEntry>>((ref) {
  return ref.watch(orderRepositoryProvider).queue();
});

final scheduledProvider = FutureProvider<List<ScheduledEntry>>((ref) {
  return ref.watch(orderRepositoryProvider).scheduled();
});

final originHubsProvider = FutureProvider<List<OriginHub>>((ref) {
  return ref.watch(orderRepositoryProvider).originHubs();
});

final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).findOne(id);
});

final planDetailProvider = FutureProvider.family<PlanDetail, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).planDetail(id);
});

class CreateEmergencyNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> create(CreateEmergencyRequest request) async {
    final order = await ref
        .read(orderRepositoryProvider)
        .createEmergency(request);
    ref.invalidate(mineProvider);
    state = AsyncData(order);
    return order;
  }
}

final createEmergencyProvider =
    AsyncNotifierProvider<CreateEmergencyNotifier, Order?>(
      CreateEmergencyNotifier.new,
    );

class CreatePlanNotifier extends AsyncNotifier<DeliveryPlan?> {
  @override
  Future<DeliveryPlan?> build() async => null;

  Future<DeliveryPlan> create(CreatePlanRequest request) async {
    final plan = await ref.read(orderRepositoryProvider).createPlan(request);
    ref.invalidate(plansProvider);
    state = AsyncData(plan);
    return plan;
  }
}

final createPlanProvider =
    AsyncNotifierProvider<CreatePlanNotifier, DeliveryPlan?>(
      CreatePlanNotifier.new,
    );

class CreateHubEmergencyNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> create(CreateHubEmergencyRequest request) async {
    final order = await ref
        .read(orderRepositoryProvider)
        .createHubEmergency(request);
    ref.invalidate(queueProvider);
    state = AsyncData(order);
    return order;
  }
}

final createHubEmergencyProvider =
    AsyncNotifierProvider<CreateHubEmergencyNotifier, Order?>(
      CreateHubEmergencyNotifier.new,
    );

class CreateHubPlanNotifier extends AsyncNotifier<DeliveryPlan?> {
  @override
  Future<DeliveryPlan?> build() async => null;

  Future<DeliveryPlan> create(CreateHubPlanRequest request) async {
    final plan = await ref.read(orderRepositoryProvider).createHubPlan(request);
    ref.invalidate(plansProvider);
    ref.invalidate(scheduledProvider);
    state = AsyncData(plan);
    return plan;
  }
}

final createHubPlanProvider =
    AsyncNotifierProvider<CreateHubPlanNotifier, DeliveryPlan?>(
      CreateHubPlanNotifier.new,
    );

/// Bandeja "Pendiente de carga" del despachador: pedidos autorizados de su
/// central que esperan que alguien confirme la carga.
final pendingLoadProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).listPendingLoad();
});

/// Lo que el despachador hace sobre un pedido: rechazar, autorizar y
/// confirmar la carga. Cada acción mueve el pedido entre listas, así que
/// al terminar refresca la cola, los programados, la bandeja y el detalle.
class OrderDispatchNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> reject(String id, String reason) =>
      _run(id, (repo) => repo.reject(id, reason));

  Future<Order> authorize(String id, {bool? prescriptionVerified}) => _run(
    id,
    (repo) => repo.authorize(id, prescriptionVerified: prescriptionVerified),
  );

  Future<Order> confirmLoad(String id) =>
      _run(id, (repo) => repo.confirmLoad(id));

  Future<Order> _run(
    String id,
    Future<Order> Function(OrderRepository repo) action,
  ) async {
    final order = await action(ref.read(orderRepositoryProvider));
    ref
      ..invalidate(queueProvider)
      ..invalidate(scheduledProvider)
      ..invalidate(pendingLoadProvider)
      ..invalidate(orderDetailProvider(id));
    state = AsyncData(order);
    return order;
  }
}

final orderDispatchProvider =
    AsyncNotifierProvider<OrderDispatchNotifier, Order?>(
      OrderDispatchNotifier.new,
    );

class ExtendPlanNotifier extends AsyncNotifier<DeliveryPlan?> {
  @override
  Future<DeliveryPlan?> build() async => null;

  Future<DeliveryPlan> extend(String id) async {
    final plan = await ref.read(orderRepositoryProvider).extendPlan(id);
    ref.invalidate(plansProvider);
    ref.invalidate(planDetailProvider(id));
    state = AsyncData(plan);
    return plan;
  }
}

final extendPlanProvider =
    AsyncNotifierProvider<ExtendPlanNotifier, DeliveryPlan?>(
      ExtendPlanNotifier.new,
    );

class CancelPlanNotifier extends AsyncNotifier<DeliveryPlan?> {
  @override
  Future<DeliveryPlan?> build() async => null;

  Future<DeliveryPlan> cancel(String id) async {
    final plan = await ref.read(orderRepositoryProvider).cancelPlan(id);
    ref.invalidate(plansProvider);
    ref.invalidate(planDetailProvider(id));
    ref.invalidate(mineProvider);
    ref.invalidate(scheduledProvider);
    state = AsyncData(plan);
    return plan;
  }
}

final cancelPlanProvider =
    AsyncNotifierProvider<CancelPlanNotifier, DeliveryPlan?>(
      CancelPlanNotifier.new,
    );
