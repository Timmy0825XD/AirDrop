import 'dart:typed_data';

import '../../../core/api_exception.dart';
import '../../inventory/data/inventory_models.dart' show SaleType;
import 'agenda_models.dart';
import 'local_plan_calendar.dart';
import 'order_models.dart';
import 'order_repository.dart';

/// Fixture mínimo para `DataSource.local`: una oferta, una urgencia en
/// `received` con `unattended: true`, otra ya autorizada esperando carga,
/// una devuelta sin revisar, una reasignada desde otra central, una entrega
/// de plan por confirmar y un plan semanal. Rechazar, autorizar, confirmar
/// la carga, revisar el retorno y confirmar/omitir/mover una entrega
/// cambian el estado como en Nest; no hay telemetría.
class LocalOrderRepository implements OrderRepository {
  final List<Order> _orders = [
    Order(
      id: 'a2222222-2222-4222-8222-222222222222',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.person,
      status: OrderStatus.pendingLoad,
      priority: OrderPriority.high,
      medicationName: 'Insulina glargina 100 UI/ml',
      saleType: SaleType.overTheCounter,
      requiresColdChain: true,
      quantity: 1,
      address: 'Carrera 9 # 15-20, Valledupar',
      hasPrescription: false,
      createdByUserId: 'local-requester',
      originHubId: _localHubId,
      droneId: _localAssignment.droneId,
      assignment: _localAssignment,
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
    ),
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
    Order(
      id: 'a3333333-3333-4333-8333-333333333333',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.person,
      status: OrderStatus.returned,
      priority: OrderPriority.high,
      medicationName: 'Insulina glargina 100 UI/ml',
      saleType: SaleType.overTheCounter,
      requiresColdChain: true,
      coldChainAlert: true,
      quantity: 1,
      address: 'Calle 12 # 8-40, Valledupar',
      hasPrescription: false,
      createdByUserId: 'local-requester',
      originHubId: _localHubId,
      dispatchedLot: 'L-2026-10',
      dispatchedLotExpiresOn: '2027-01-31',
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    ),
    Order(
      id: 'a4444444-4444-4444-8444-444444444444',
      missionType: MissionType.emergency,
      destinationKind: DestinationKind.person,
      status: OrderStatus.reassigned,
      priority: OrderPriority.high,
      medicationName: 'Ibuprofeno 400 mg',
      saleType: SaleType.overTheCounter,
      requiresColdChain: false,
      quantity: 1,
      address: 'Calle 20 # 8-15, Valledupar',
      hasPrescription: false,
      createdByUserId: 'local-requester',
      originHubId: _localHubId,
      reassignedFromHubId: 'local-other-hub',
      fallback: const OrderFallback(
        kind: FallbackKind.hub,
        reason: 'Ningún dron de la central podía salir.',
        options: [
          FallbackOption(
            hubId: _localHubId,
            name: 'Hospital Rosario Pumarejo',
            address: 'Calle 16',
            contactPhone: '6055700000',
            distanceKm: 3.1,
          ),
        ],
      ),
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 9)),
    ),
    Order(
      id: 'a5555555-5555-4555-8555-555555555555',
      missionType: MissionType.scheduled,
      destinationKind: DestinationKind.person,
      status: OrderStatus.awaitingConfirmation,
      priority: OrderPriority.normal,
      medicationName: 'Acetaminofén 500 mg',
      saleType: SaleType.overTheCounter,
      requiresColdChain: false,
      quantity: 2,
      address: 'Calle 16 # 12-30, Valledupar',
      hasPrescription: false,
      createdByUserId: 'local-requester',
      planId: 'b1111111-1111-4111-8111-111111111111',
      scheduledFor: _tomorrowIso(),
      scheduledAt: _tomorrowAt(10),
      windowEndsAt: _tomorrowAt(11),
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
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
    final dates = request.schedule == null
        ? const <String>[]
        : localOccurrenceDates(request.schedule!);
    final plan = DeliveryPlan(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      frequency: request.frequency,
      schedule: request.schedule,
      windowMinutes: request.schedule == null ? null : 60,
      prescriptionValidUntil: request.prescriptionValidUntil,
      status: PlanStatus.active,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: request.quantity,
      startDate: dates.firstOrNull ?? request.startDate ?? todayLocalIso(),
      windowEndsOn: dates.lastOrNull ?? '2026-11-29',
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
    final dates = request.schedule == null
        ? const <String>[]
        : localOccurrenceDates(request.schedule!);
    final plan = DeliveryPlan(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      frequency: request.frequency,
      schedule: request.schedule,
      windowMinutes: request.schedule == null ? null : 60,
      status: PlanStatus.active,
      medicationName: request.medicationName,
      saleType: request.saleType,
      requiresColdChain: false,
      quantity: request.quantity,
      startDate: dates.firstOrNull ?? request.startDate ?? todayLocalIso(),
      windowEndsOn: dates.lastOrNull ?? '2026-11-29',
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
      orElse: () =>
          throw const ApiException('El plan no existe.', statusCode: 404),
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
    _plans[index] = _plans[index].copyWith(status: PlanStatus.cancelled);
    return _plans[index];
  }

  @override
  Future<List<QueueEntry>> queue() async {
    return _orders
        .where((e) => e.status == OrderStatus.received || e.reassignedToHub)
        .map(
          (e) => QueueEntry(
            order: e,
            availableQuantity: 8,
            unattended: e.status == OrderStatus.received,
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
      orElse: () =>
          throw const ApiException('El pedido no existe.', statusCode: 404),
    );
  }

  @override
  Future<PrescriptionFile> prescription(String orderId) async {
    await findOne(orderId);
    return PrescriptionFile(bytes: Uint8List(0), mime: 'image/jpeg');
  }

  @override
  Future<Order> reject(String id, String reason) async {
    final current = await findOne(id);
    if (current.status != OrderStatus.received && !current.reassignedToHub) {
      throw const ApiException(
        'Solo se rechaza un pedido que sigue en recibido.',
        statusCode: 400,
      );
    }
    return _replace(
      current.copyWith(status: OrderStatus.rejected, statusReason: reason),
    );
  }

  /// Simula al motor de decisión: siempre elige el mismo dron y un
  /// corredor recto de dos puntos.
  @override
  Future<Order> authorize(String id, {bool? prescriptionVerified}) async {
    final current = await findOne(id);
    if (current.status != OrderStatus.received && !current.reassignedToHub) {
      throw const ApiException(
        'Solo se autoriza un pedido que sigue en recibido.',
        statusCode: 400,
      );
    }
    return _replace(
      current.copyWith(
        status: OrderStatus.pendingLoad,
        droneId: _localAssignment.droneId,
        originHubId: _localHubId,
        assignment: _localAssignment,
        clearFallback: true,
      ),
    );
  }

  @override
  Future<Order> confirmLoad(String id) async {
    final current = await findOne(id);
    if (!current.awaitsLoad) {
      throw const ApiException(
        'Solo se confirma la carga de un pedido pendiente de carga.',
        statusCode: 400,
      );
    }
    final confirmed = current.copyWith(loadConfirmedAt: DateTime.now().toUtc());
    // Como Nest, responde todavía en `pending_load`; pero aquí no hay reloj,
    // así que se guarda como si el primer tick ya lo hubiera puesto en vuelo.
    _replace(confirmed.copyWith(status: OrderStatus.inFlight));
    return confirmed;
  }

  @override
  Future<List<Order>> listPendingLoad() async {
    return _orders
        .where((e) => e.status == OrderStatus.pendingLoad)
        .toList(growable: false);
  }

  @override
  Future<List<Order>> listInFlight() async {
    return _orders
        .where(
          (e) =>
              e.status == OrderStatus.inFlight ||
              e.status == OrderStatus.awaitingDelivery ||
              e.status == OrderStatus.returning,
        )
        .toList(growable: false);
  }

  @override
  Future<List<Order>> listIncoming() async {
    return _orders
        .where(
          (e) =>
              e.destinationKind == DestinationKind.hub &&
              e.destinationHubId == _localHubId,
        )
        .toList(growable: false);
  }

  /// Como Nest: con alerta de frío o empaque dañado va a cuarentena.
  @override
  Future<Order> returnCheck(String id, {required bool packagingIntact}) async {
    final current = await findOne(id);
    if (current.status != OrderStatus.returned) {
      throw const ApiException(
        'Solo se revisa un pedido devuelto.',
        statusCode: 400,
      );
    }
    if (current.returnCheckedAt != null) {
      throw const ApiException('Este retorno ya se revisó.', statusCode: 400);
    }
    final quarantined = current.coldChainAlert || !packagingIntact;
    return _replace(
      current.copyWith(
        returnCheckedAt: DateTime.now().toUtc(),
        returnOutcome: quarantined
            ? ReturnOutcome.quarantined
            : ReturnOutcome.restocked,
      ),
    );
  }

  @override
  Future<Order> confirmOccurrence(String id) async {
    final current = await _changeableOccurrence(id);
    if (current.status != OrderStatus.awaitingConfirmation &&
        current.status != OrderStatus.scheduled) {
      throw const ApiException(
        'Esta entrega no espera confirmación.',
        statusCode: 400,
      );
    }
    return _replace(
      current.copyWith(
        status: OrderStatus.received,
        confirmedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<Order> skipOccurrence(String id) async {
    final current = await _changeableOccurrence(id);
    return _replace(
      current.copyWith(
        status: OrderStatus.skipped,
        statusReason: 'Omitida por quien la recibe.',
      ),
    );
  }

  @override
  Future<Order> rescheduleOccurrence(
    String id, {
    required String date,
    required String time,
  }) async {
    final current = await _changeableOccurrence(id);
    final start = colombiaSlotStart(date, time);
    return _replace(
      current.copyWith(
        status: OrderStatus.received,
        scheduledFor: date,
        scheduledAt: start,
        windowEndsAt: start.add(const Duration(hours: 1)),
        confirmedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<Order> _changeableOccurrence(String id) async {
    final current = await findOne(id);
    if (current.planId == null) {
      throw const ApiException(
        'Solo las entregas de un plan se confirman.',
        statusCode: 400,
      );
    }
    final start = current.scheduledAt;
    final late =
        start != null &&
        start.difference(DateTime.now().toUtc()) < const Duration(hours: 2);
    if (current.droneId != null || late) {
      throw const ApiException(
        'Esta entrega ya no se puede cambiar: faltan menos de 2 horas o ya '
        'tiene dron.',
        statusCode: 400,
      );
    }
    return current;
  }

  @override
  Future<DeliveryPlan> setPlanPaused(String id, {required bool paused}) async {
    final index = _plans.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw const ApiException('El plan no existe.', statusCode: 404);
    }
    if (_plans[index].paused == paused) {
      throw ApiException(
        paused ? 'El plan ya está en pausa.' : 'El plan no está en pausa.',
        statusCode: 400,
      );
    }
    _plans[index] = _plans[index].copyWith(paused: paused);
    return _plans[index];
  }

  @override
  Future<PlanPreview> previewPlan(
    PlanSchedule schedule, {
    String? prescriptionValidUntil,
  }) async {
    final dates = localOccurrenceDates(schedule);
    if (dates.isEmpty) {
      throw const ApiException(
        'El plan no tiene entregas a más de 2 horas. Revisa las fechas y la '
        'hora.',
        statusCode: 400,
      );
    }
    final time = schedule.time ?? '07:00';
    return PlanPreview(
      lastDate: dates.last,
      occurrences: [
        for (final date in dates)
          PreviewOccurrence(
            date: date,
            scheduledAt: colombiaSlotStart(date, time),
            windowEndsAt: colombiaSlotStart(
              date,
              time,
            ).add(const Duration(hours: 1)),
          ),
      ],
    );
  }

  @override
  Future<DeliveryPlan> updatePlanSchedule(
    String id,
    PlanSchedule schedule,
  ) async {
    final index = _plans.indexWhere((e) => e.id == id);
    if (index < 0) {
      throw const ApiException('El plan no existe.', statusCode: 404);
    }
    final current = _plans[index];
    final dates = localOccurrenceDates(schedule);
    _plans[index] = DeliveryPlan(
      id: current.id,
      schedule: schedule,
      windowMinutes: 60,
      status: current.status,
      medicationName: current.medicationName,
      saleType: current.saleType,
      requiresColdChain: current.requiresColdChain,
      quantity: current.quantity,
      startDate: dates.firstOrNull ?? current.startDate,
      windowEndsOn: dates.lastOrNull ?? current.windowEndsOn,
      destinationKind: current.destinationKind,
      address: current.address,
      hasPrescription: current.hasPrescription,
      renewalDue: false,
      paused: current.paused,
      prescriptionValidUntil: current.prescriptionValidUntil,
      createdAt: current.createdAt,
    );
    return _plans[index];
  }

  @override
  Future<AgendaDay> agenda(String date) async {
    final rows = _orders.where(
      (e) => e.scheduledFor == date && e.scheduledAt != null,
    );
    final byTime = <String, List<AgendaOrder>>{};
    for (final order in rows) {
      final time = localClock(order.scheduledAt!);
      (byTime[time] ??= []).add(
        AgendaOrder(
          order: order,
          time: time,
          confirmed: order.confirmedAt != null,
          stockOk: true,
          availableQuantity: 8,
          departBefore: order.windowEndsAt?.subtract(
            const Duration(minutes: 12),
          ),
        ),
      );
    }
    return AgendaDay(
      date: date,
      drones: 1,
      slots: [
        for (final entry in byTime.entries)
          AgendaSlot(
            time: entry.key,
            deliveries: entry.value.length,
            overCapacity: entry.value.length > 1,
            orders: entry.value,
          ),
      ],
    );
  }

  @override
  Future<HistoryPage> history(HistoryQuery query) async {
    const closed = {
      OrderStatus.delivered,
      OrderStatus.returned,
      OrderStatus.rejected,
      OrderStatus.reassigned,
      OrderStatus.cancelled,
      OrderStatus.skipped,
      OrderStatus.expired,
    };
    final rows = _orders
        .where((e) => closed.contains(e.status))
        .where((e) => query.status == null || e.status == query.status)
        .toList(growable: false);
    final start = (query.page - 1) * query.pageSize;
    return HistoryPage(
      items: rows.skip(start).take(query.pageSize).toList(growable: false),
      total: rows.length,
      page: query.page,
      pageSize: query.pageSize,
    );
  }

  Order _replace(Order updated) {
    final index = _orders.indexWhere((e) => e.id == updated.id);
    _orders[index] = updated;
    return updated;
  }
}

const _localHubId = 'local-hub';

String _tomorrowIso() => isoOfDay(colombiaToday().add(const Duration(days: 1)));

DateTime _tomorrowAt(int hour) =>
    colombiaSlotStart(_tomorrowIso(), '${hour.toString().padLeft(2, '0')}:00');

const _localAssignment = OrderAssignment(
  droneId: 'local-drone',
  identifier: 'D-01',
  modelName: 'Wingcopter 198',
  altitudeM: 100,
  distanceKm: 4.2,
  coordinates: [
    [-73.2532, 10.4631],
    [-73.2410, 10.4790],
  ],
);
