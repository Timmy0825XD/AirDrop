import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import 'delivery_models.dart';
import 'delivery_repository.dart';
import 'local_delivery_repository.dart';
import 'remote_delivery_repository.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  // Otra cuenta, otro repositorio: lo cargado por la anterior se descarta.
  ref.watch(sessionUserIdProvider);
  return switch (appDataSource) {
    DataSource.local => LocalDeliveryRepository(
      orders: ref.watch(orderRepositoryProvider),
    ),
    DataSource.remote => RemoteDeliveryRepository(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

/// Recibir un pedido: pedir el código y validarlo. Al entregar refresca las
/// listas donde aparecía el pedido y su detalle.
class ReceiveOrderNotifier extends AsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<DeliveryCode> generate(String orderId) =>
      ref.read(deliveryRepositoryProvider).generate(orderId);

  Future<Order> validate(String orderId, String code) async {
    final order = await ref
        .read(deliveryRepositoryProvider)
        .validate(orderId, code);
    ref
      ..invalidate(mineProvider)
      ..invalidate(incomingProvider)
      ..invalidate(inFlightProvider)
      ..invalidate(orderDetailProvider(orderId));
    state = AsyncData(order);
    return order;
  }
}

final receiveOrderProvider =
    AsyncNotifierProvider<ReceiveOrderNotifier, Order?>(
      ReceiveOrderNotifier.new,
    );
