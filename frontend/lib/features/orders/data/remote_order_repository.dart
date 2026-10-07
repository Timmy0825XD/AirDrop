import '../../../core/network/api_client.dart';
import 'order_models.dart';
import 'order_repository.dart';

/// Operaciones contra Nest (`OrdersController`). Arma la ruta y parsea;
/// no captura el error: `ApiClient` ya lanza `ApiException`.
class RemoteOrderRepository implements OrderRepository {
  RemoteOrderRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<CatalogOffer>> catalog({String? hubId}) async {
    final data = await apiClient.getJson(
      '/orders/catalog',
      query: hubId == null ? null : {'hubId': hubId},
    );
    return _asJsonList(data).map((row) => CatalogOffer.fromJson(_asMap(row))).toList();
  }

  @override
  Future<List<OriginHub>> originHubs() async {
    final data = await apiClient.getJson('/orders/origin-hubs');
    return _asJsonList(data).map((row) => OriginHub.fromJson(_asMap(row))).toList();
  }

  @override
  Future<Order> createEmergency(CreateEmergencyRequest request) async {
    final data = await apiClient.postJson(
      '/orders/emergencies',
      body: request.toJson(),
    );
    return Order.fromJson(_asMap(data));
  }

  @override
  Future<Order> createHubEmergency(CreateHubEmergencyRequest request) async {
    final data = await apiClient.postJson(
      '/orders/hub-emergencies',
      body: request.toJson(),
    );
    return Order.fromJson(_asMap(data));
  }

  @override
  Future<DeliveryPlan> createPlan(CreatePlanRequest request) async {
    final data = await apiClient.postJson(
      '/orders/plans',
      body: request.toJson(),
    );
    return DeliveryPlan.fromJson(_asMap(data));
  }

  @override
  Future<DeliveryPlan> createHubPlan(CreateHubPlanRequest request) async {
    final data = await apiClient.postJson(
      '/orders/hub-plans',
      body: request.toJson(),
    );
    return DeliveryPlan.fromJson(_asMap(data));
  }

  @override
  Future<List<Order>> listMine() async {
    final data = await apiClient.getJson('/orders/mine');
    return _asJsonList(data).map((row) => Order.fromJson(_asMap(row))).toList();
  }

  @override
  Future<List<DeliveryPlan>> listPlans() async {
    final data = await apiClient.getJson('/orders/plans');
    return _asJsonList(data).map((row) => DeliveryPlan.fromJson(_asMap(row))).toList();
  }

  @override
  Future<PlanDetail> planDetail(String id) async {
    final data = await apiClient.getJson('/orders/plans/$id');
    return PlanDetail.fromJson(_asMap(data));
  }

  @override
  Future<DeliveryPlan> extendPlan(String id) async {
    final data = await apiClient.postJson('/orders/plans/$id/extend');
    return DeliveryPlan.fromJson(_asMap(data));
  }

  @override
  Future<DeliveryPlan> cancelPlan(String id) async {
    final data = await apiClient.postJson('/orders/plans/$id/cancel');
    return DeliveryPlan.fromJson(_asMap(data));
  }

  @override
  Future<List<QueueEntry>> queue() async {
    final data = await apiClient.getJson('/orders/queue');
    return _asJsonList(data).map((row) => QueueEntry.fromJson(_asMap(row))).toList();
  }

  @override
  Future<List<ScheduledEntry>> scheduled() async {
    final data = await apiClient.getJson('/orders/scheduled');
    return _asJsonList(data).map((row) => ScheduledEntry.fromJson(_asMap(row))).toList();
  }

  @override
  Future<Order> findOne(String id) async {
    final data = await apiClient.getJson('/orders/$id');
    return Order.fromJson(_asMap(data));
  }

  @override
  Future<PrescriptionFile> prescription(String orderId) async {
    final file = await apiClient.getBytes('/orders/$orderId/prescription');
    return PrescriptionFile(bytes: file.bytes, mime: file.mime);
  }

  @override
  Future<Order> reject(String id, String reason) async {
    final data = await apiClient.postJson(
      '/orders/$id/reject',
      body: {'reason': reason},
    );
    return Order.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map<Object?, Object?>) return Map<String, dynamic>.from(data);
    throw const FormatException('La respuesta del pedido no es un objeto JSON.');
  }

  List<Object?> _asJsonList(Object? data) {
    if (data is List<Object?>) return data;
    throw const FormatException('La respuesta de pedidos no es una lista JSON.');
  }
}
