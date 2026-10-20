import '../../orders/data/order_models.dart';
import 'delivery_models.dart';

/// Contrato de la entrega (`DeliveryController` en Nest). Quien recibe es el
/// solicitante (destino: persona) o el despachador de la central de destino
/// (traslado); a cualquier otro Nest le responde 404.
abstract class DeliveryRepository {
  /// `POST /orders/:id/delivery-code` — solo con el pedido en
  /// `awaiting_delivery` y antes de que venza la espera.
  Future<DeliveryCode> generate(String orderId);

  /// `POST /orders/:id/delivery-code/validate` — con el código correcto el
  /// pedido queda `delivered` y el dron se libera.
  Future<Order> validate(String orderId, String code);
}
