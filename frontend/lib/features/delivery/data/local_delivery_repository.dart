import '../../../core/api_exception.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_repository.dart';
import 'delivery_models.dart';
import 'delivery_repository.dart';

/// Entrega para `DataSource.local`: el código siempre es `246810` y vence a
/// los 5 minutos de pedirlo. El pedido sale del repositorio local de pedidos;
/// validar devuelve el pedido entregado sin guardarlo (no hay reloj).
class LocalDeliveryRepository implements DeliveryRepository {
  LocalDeliveryRepository({required this.orders});

  final OrderRepository orders;

  static const localCode = '246810';

  @override
  Future<DeliveryCode> generate(String orderId) async {
    await _awaiting(orderId);
    return DeliveryCode(
      code: localCode,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<Order> validate(String orderId, String code) async {
    final order = await _awaiting(orderId);
    if (code != localCode) {
      throw const ApiException(
        'El código es inválido, ya se usó o venció.',
        statusCode: 400,
      );
    }
    return order.copyWith(status: OrderStatus.delivered);
  }

  Future<Order> _awaiting(String orderId) async {
    final order = await orders.findOne(orderId);
    if (order.status != OrderStatus.awaitingDelivery) {
      throw const ApiException(
        'Solo se entrega un pedido en espera de entrega.',
        statusCode: 400,
      );
    }
    return order;
  }
}
