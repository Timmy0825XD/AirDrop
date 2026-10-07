import 'dart:typed_data';

import '../../../core/api_exception.dart';
import '../../inventory/data/inventory_models.dart' show SaleType;
import 'order_models.dart';
import 'order_repository.dart';

/// Fixture mínimo para `DataSource.local`: una oferta, una urgencia en
/// `received` con `unattended: true` y un plan semanal con dos
/// ocurrencias. Al rechazar, la fila pasa a `rejected` con el motivo.
/// No simula autorización ni dron.
class LocalOrderRepository implements OrderRepository {
  final List<Order> _orders = [
    Order(
      id: 'a1111111-1111-4111-8111-111111111111',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.person,
      status: OrderStatus.received,
      priority: OrderPriority.high,
      medicationName: 'Acetaminofén 500 mg',
      saleType: SaleType.overTheCounter,
      requiresColdChain: false,
      quantity: 1,
      address: 'Calle 16 # 12-30, Valledupar',
      hasPrescription: false,
      createdByUserId: 'local-requester',
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 6)),
    ),
  ];

  final List<DeliveryPlan> _plans = [
    DeliveryPlan(
      id: 'b1111111-1111-4111-8111-111111111111',
      frequency: PlanFrequency.weekly,
      status: PlanStatus.active,
      medicationName: 'Acetaminofén 500 mg',
      saleType: SaleType.overTheCounter,
      requiresColdChain: false,
      quantity: 2,
      startDate: '2026-10-04',
      windowEndsOn: '2026-11-29',
      destinationKind: DestinationKind.person,
      address: 'Calle 16 # 12-30, Valledupar',
      hasPrescription: false,
      renewalDue: false,
      createdAt: DateTime.utc(2026, 10, 4, 16, 40),
    ),
  ];

  @override
  Future<List<CatalogOffer>> catalog({String? hubId}) async {
    return const [
      CatalogOffer(
        name: 'Acetaminofén 500 mg',
        saleType: SaleType.overTheCounter,
        requiresColdChain: false,
        availableQuantity: 8,
      ),
    ];
  }

  @override
  Future<List<OriginHub>> originHubs() async {
    return const [
      OriginHub(
        id: 'c1111111-1111-4111-8111-111111111111',
        name: 'Hospital Rosario Pumarejo',
        address: 'Calle 16',
      ),
    ];
  }

  @override
  Future<Order> createEmergency(CreateEmergencyRequest request) async {
    final order = Order(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.person,
      status: OrderStatus.received,
      priority: OrderPriority.high,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: 1,
      description: request.description,
      address: request.address,
      latitude: request.latitude,
      longitude: request.longitude,
      hasPrescription: request.saleType == SaleType.prescription,
      createdByUserId: 'local-requester',
      createdAt: DateTime.now().toUtc(),
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<Order> createHubEmergency(CreateHubEmergencyRequest request) async {
    final order = Order(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.hub,
      status: OrderStatus.received,
      priority: OrderPriority.high,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: request.quantity,
      address: 'Calle 16',
      hasPrescription: false,
      originHubId: request.originHubId,
      destinationHubId: 'local-hub',
      createdByUserId: 'local-dispatcher',
      createdAt: DateTime.now().toUtc(),
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<DeliveryPlan> createPlan(CreatePlanRequest request) async {
    final plan = DeliveryPlan(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      frequency: request.frequency,
      status: PlanStatus.active,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: request.quantity,
      startDate: request.startDate,
      windowEndsOn: '2026-11-29',
      destinationKind: DestinationKind.person,
      address: request.address,
      hasPrescription: request.saleType == SaleType.prescription,
      renewalDue: false,
      createdAt: DateTime.now().toUtc(),
    );
    _plans.insert(0, plan);
    return plan;
  }

  @override
  Future<DeliveryPlan> createHubPlan(CreateHubPlanRequest request) async {
    final plan = DeliveryPlan(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      frequency: request.frequency,
      status: PlanStatus.active,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: request.quantity,
      startDate: request.startDate,
      windowEndsOn: '2026-11-29',
      destinationKind: DestinationKind.hub,
      address: 'Calle 16',
      hasPrescription: false,
      renewalDue: false,
      originHubId: request.originHubId,
      destinationHubId: 'local-hub',
      createdAt: DateTime.now().toUtc(),
    );
    _plans.insert(0, plan);
    return plan;
  }

  @override
  Future<List<Order>> listMine() async => List.unmodifiable(_orders);

  @override
  Future<List<DeliveryPlan>> listPlans() async => List.unmodifiable(_plans);

  @override
  Future<PlanDetail> planDetail(String id) async {
    final plan = _plans.firstWhere(
      (e) => e.id == id,
      orElse: () => throw const ApiException(
        'El plan no existe.',
        statusCode: 404,
      ),
    );
    return PlanDetail(
      plan: plan,
      occurrences: const [
        PlanOccurrence(
          id: 'o1',
          status: OrderStatus.received,
          scheduledFor: '2026-10-04',
        ),
        PlanOccurrence(
          id: 'o2',
          status: OrderStatus.received,
          scheduledFor: '2026-10-11',
        ),
      ],
    );
  }

  @override
  Future<DeliveryPlan> extendPlan(String id) async {
    final index = _plans.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw const ApiException('El plan no existe.', statusCode: 404);
    }
    return _plans[index];
  }

  @override
  Future<DeliveryPlan> cancelPlan(String id) async {
    final index = _plans.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw const ApiException('El plan no existe.', statusCode: 404);
    }
    const cancelled = PlanStatus.cancelled;
    final current = _plans[index];
    _plans[index] = DeliveryPlan(
      id: current.id,
      frequency: current.frequency,
      status: cancelled,
      medicationName: current.medicationName,
      saleType: current.saleType,
      requiresColdChain: current.requiresColdChain,
      quantity: current.quantity,
      startDate: current.startDate,
      windowEndsOn: current.windowEndsOn,
      destinationKind: current.destinationKind,
      address: current.address,
      hasPrescription: current.hasPrescription,
      renewalDue: false,
      createdAt: current.createdAt,
    );
    return _plans[index];
  }

  @override
  Future<List<QueueEntry>> queue() async {
    return _orders
        .where((e) => e.status == OrderStatus.received)
        .map(
          (e) => QueueEntry(
            order: e,
            availableQuantity: 8,
            unattended: true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ScheduledEntry>> scheduled() async {
    return _orders
        .where((e) => e.status == OrderStatus.received)
        .map((e) => ScheduledEntry(order: e, availableQuantity: 8))
        .toList(growable: false);
  }

  @override
  Future<Order> findOne(String id) async {
    return _orders.firstWhere(
      (e) => e.id == id,
      orElse: () => throw const ApiException(
        'El pedido no existe.',
        statusCode: 404,
      ),
    );
  }

  @override
  Future<PrescriptionFile> prescription(String orderId) async {
    await findOne(orderId);
    return PrescriptionFile(bytes: Uint8List(0), mime: 'image/jpeg');
  }

  @override
  Future<Order> reject(String id, String reason) async {
    final index = _orders.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw const ApiException('El pedido no existe.', statusCode: 404);
    }
    final current = _orders[index];
    _orders[index] = Order(
      id: current.id,
      missionType: current.missionType,
      destinationKind: current.destinationKind,
      status: OrderStatus.rejected,
      priority: current.priority,
      medicationName: current.medicationName,
      saleType: current.saleType,
      requiresColdChain: current.requiresColdChain,
      quantity: current.quantity,
      description: current.description,
      address: current.address,
      hasPrescription: current.hasPrescription,
      requesterId: current.requesterId,
      createdByUserId: current.createdByUserId,
      statusReason: reason,
      createdAt: current.createdAt,
    );
    return _orders[index];
  }
}
