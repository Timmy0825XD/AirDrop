import '../../../../core/api_exception.dart';
import '../../../../core/network/api_client.dart';
import 'inventory_models.dart';
import 'inventory_repository.dart';

/// Las cuatro operaciones contra Nest (`InventoryController`, solo
/// `dispatcher`). Todos los errores se relanzan como [ApiException] para
/// que la UI muestre el mensaje que define el backend.
class RemoteInventoryRepository implements InventoryRepository {
  RemoteInventoryRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<InventoryItem>> list() async {
    final data = await apiClient.getJson('/inventory');
    return _asJsonList(data)
        .map((row) => InventoryItem.fromJson(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<InventoryItem> create(CreateInventoryItemRequest request) async {
    final data = await apiClient.postJson('/inventory', body: request.toJson());
    return InventoryItem.fromJson(_asJsonMap(data));
  }

  @override
  Future<InventoryItem> update(
    String id,
    UpdateInventoryItemRequest request,
  ) async {
    final data = await apiClient.patchJson(
      '/inventory/$id',
      body: request.toJson(),
    );
    return InventoryItem.fromJson(_asJsonMap(data));
  }

  @override
  Future<void> remove(String id) => apiClient.delete('/inventory/$id');

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta del ítem no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException(
      'La respuesta del inventario no es una lista JSON.',
    );
  }
}
