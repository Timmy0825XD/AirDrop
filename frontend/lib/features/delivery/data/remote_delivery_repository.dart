import '../../../core/network/api_client.dart';
import '../../orders/data/order_models.dart';
import 'delivery_models.dart';
import 'delivery_repository.dart';

/// La entrega contra Nest. No captura el error: `ApiClient` ya lanza
/// `ApiException` con el mensaje del servidor.
class RemoteDeliveryRepository implements DeliveryRepository {
  RemoteDeliveryRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<DeliveryCode> code(String orderId) async {
    final data = await apiClient.getJson('/orders/$orderId/delivery-code');
    return DeliveryCode.fromJson(_asMap(data));
  }

  @override
  Future<Order> validate(String orderId, String code) async {
    final data = await apiClient.postJson(
      '/orders/$orderId/delivery-code/validate',
      body: {'code': code},
    );
    return Order.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException(
      'La respuesta de la entrega no es un objeto JSON.',
    );
  }
}
