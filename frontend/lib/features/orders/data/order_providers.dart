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
final hubCatalogProvider =
    FutureProvider.family<List<CatalogOffer>, String>((ref, hubId) {
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

final planDetailProvider = FutureProvider.family<PlanDetail, String>((
  ref,
  id,
) {
  return ref.watch(orderRepositoryProvider).planDetail(id);
});

class CreateEmergencyNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> create(CreateEmergencyRequest request) async {
    final order = await ref.read(orderRepositoryProvider).createEmergency(request);
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

class RejectOrderNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order> reject(String id, String reason) async {
    final order = await ref.read(orderRepositoryProvider).reject(id, reason);
    ref.invalidate(queueProvider);
    ref.invalidate(scheduledProvider);
    ref.invalidate(orderDetailProvider(id));
    state = AsyncData(order);
    return order;
  }
}

final rejectOrderProvider =
    AsyncNotifierProvider<RejectOrderNotifier, Order?>(
      RejectOrderNotifier.new,
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
