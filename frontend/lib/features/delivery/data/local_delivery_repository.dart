import '../../../core/api_exception.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_repository.dart';
import 'delivery_models.dart';
import 'delivery_repository.dart';

/// Entrega para `DataSource.local`: el código siempre es `246810`. Con el
/// pedido en espera de entrega vence a los 5 minutos de pedirlo. El pedido
/// sale del repositorio local de pedidos; validar devuelve el pedido
/// entregado sin guardarlo (no hay reloj).
class LocalDeliveryRepository implements DeliveryRepository {
  LocalDeliveryRepository({required this.orders});

  final OrderRepository orders;

  static const localCode = '246810';

  @override
  Future<DeliveryCode> code(String orderId) async {
    final order = await orders.findOne(orderId);
    if (!order.deliveryCodeVisible) {
      throw const ApiException(
        'El código aparece cuando el despachador confirma la carga.',
        statusCode: 400,
      );
    }
    final landed = order.status == OrderStatus.awaitingDelivery;
    return DeliveryCode(
      code: localCode,
      expiresAt: landed
          ? DateTime.now().toUtc().add(const Duration(minutes: 5))
          : null,
    );
  }

  @override
  Future<Order> validate(
    String orderId,
    String code, {
    bool? remissionMatches,
    bool? sealIntact,
  }) async {
    final order = await orders.findOne(orderId);
    final toHub = order.destinationKind == DestinationKind.hub;
    if (toHub && (remissionMatches == null || sealIntact == null)) {
      throw const ApiException(
        'Confirma si la remisión coincide y si el sello llegó intacto.',
        statusCode: 400,
      );
    }
    if (order.status != OrderStatus.awaitingDelivery) {
      throw const ApiException(
        'Solo se entrega un pedido en espera de entrega.',
        statusCode: 400,
      );
    }
    if (code != localCode) {
      throw const ApiException(
        'El código es inválido, ya se usó o venció.',
        statusCode: 400,
      );
    }
    if (toHub && sealIntact == false) {
      return order.copyWith(
        status: OrderStatus.returning,
        receiptRejectedReason:
            'El sello llegó roto. El paquete vuelve a origen.',
      );
    }
    if (toHub && remissionMatches == false) {
      return order.copyWith(
        status: OrderStatus.returning,
        receiptRejectedReason:
            'La remisión no coincide. El paquete vuelve a origen.',
      );
    }
    return order.copyWith(status: OrderStatus.delivered);
  }
}
