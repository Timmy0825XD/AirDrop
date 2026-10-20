import '../../orders/data/order_models.dart';
import 'delivery_models.dart';

/// Contrato de la entrega (`DeliveryController` en Nest). Quien recibe es el
/// solicitante (destino: persona) o el despachador de la central de destino
/// (traslado); a cualquier otro Nest le responde 404.
abstract class DeliveryRepository {
  /// `GET /orders/:id/delivery-code` — desde que se confirma la carga hasta
  /// que vence la espera en destino. Siempre devuelve el mismo código.
  Future<DeliveryCode> code(String orderId);

  /// `POST /orders/:id/delivery-code/validate` — con el código correcto el
  /// pedido queda `delivered` y el dron vuelve a su central. A los 5 códigos
  /// equivocados el pedido se bloquea.
  Future<Order> validate(String orderId, String code);
}
