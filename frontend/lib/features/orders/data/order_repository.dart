import 'agenda_models.dart';
import 'order_models.dart';

/// Contrato del módulo de pedidos. Un método por endpoint de la sección 2.
///
/// Ningún método convierte el error en `null`: `ApiClient` ya lanza
/// `ApiException` y la UI muestra ese texto.
abstract class OrderRepository {
  /// `GET /orders/catalog` — sin `hubId` para el solicitante.
  Future<List<CatalogOffer>> catalog({String? hubId});

  /// `GET /orders/origin-hubs` — despachador.
  Future<List<OriginHub>> originHubs();

  /// `POST /orders/emergencies` — solicitante, 201.
  Future<Order> createEmergency(CreateEmergencyRequest request);

  /// `POST /orders/hub-emergencies` — despachador, 201.
  Future<Order> createHubEmergency(CreateHubEmergencyRequest request);

  /// `POST /orders/plans` — solicitante, 201.
  Future<DeliveryPlan> createPlan(CreatePlanRequest request);

  /// `POST /orders/hub-plans` — despachador, 201.
  Future<DeliveryPlan> createHubPlan(CreateHubPlanRequest request);

  /// `GET /orders/mine` — solicitante.
  Future<List<Order>> listMine();

  /// `GET /orders/plans` — dueño (solicitante o despachador creador).
  Future<List<DeliveryPlan>> listPlans();

  /// `GET /orders/plans/:id` — plan más ocurrencias.
  Future<PlanDetail> planDetail(String id);

  /// `POST /orders/plans/:id/extend` — sin body, 201.
  Future<DeliveryPlan> extendPlan(String id);

  /// `POST /orders/plans/:id/cancel` — sin body, 201.
  Future<DeliveryPlan> cancelPlan(String id);

  /// `GET /orders/queue` — despachador.
  Future<List<QueueEntry>> queue();

  /// `GET /orders/scheduled` — despachador.
  Future<List<ScheduledEntry>> scheduled();

  /// `GET /orders/:id` — quien puede leerlo.
  Future<Order> findOne(String id);

  /// `GET /orders/:id/prescription` — bytes, solo despachador en cola.
  Future<PrescriptionFile> prescription(String orderId);

  /// `POST /orders/:id/reject` — despachador, 201.
  Future<Order> reject(String id, String reason);

  /// `POST /orders/:id/authorize` — despachador, 201. El motor de decisión
  /// reserva dron y corredor; el pedido pasa a `pending_load` y **no**
  /// despega. [prescriptionVerified] solo va en persona + fórmula.
  Future<Order> authorize(String id, {bool? prescriptionVerified});

  /// `POST /orders/:id/confirm-load` — despachador de origen, sin body.
  /// Arranca el reloj de la simulación.
  Future<Order> confirmLoad(String id);

  /// `GET /orders/pending-load` — despachador: la bandeja de su central.
  Future<List<Order>> listPendingLoad();

  /// `GET /orders/in-flight` — despachador: lo que salió de su central y
  /// está en vuelo o esperando la entrega.
  Future<List<Order>> listInFlight();

  /// `GET /orders/incoming` — despachador: los traslados que otras
  /// centrales despachan hacia la suya, lo más nuevo primero.
  Future<List<Order>> listIncoming();

  /// `POST /orders/:id/return-check` — despachador de origen, una vez por
  /// pedido devuelto: `restocked` o `quarantined`.
  Future<Order> returnCheck(String id, {required bool packagingIntact});

  /// `POST /orders/:id/confirm` — quien recibe una entrega de plan.
  Future<Order> confirmOccurrence(String id);

  /// `POST /orders/:id/skip` — quien recibe omite la entrega.
  Future<Order> skipOccurrence(String id);

  /// `POST /orders/:id/reschedule` — al mismo día o al siguiente; cuenta
  /// como confirmar.
  Future<Order> rescheduleOccurrence(
    String id, {
    required String date,
    required String time,
  });

  /// `POST /orders/plans/:id/pause` y `/resume` — dueño del plan.
  Future<DeliveryPlan> setPlanPaused(String id, {required bool paused});

  /// `POST /orders/plans/preview` — las fechas que dejaría un calendario,
  /// sin guardar nada.
  Future<PlanPreview> previewPlan(
    PlanSchedule schedule, {
    String? prescriptionValidUntil,
  });

  /// `PATCH /orders/plans/:id/schedule` — rehace las entregas sin dron y a
  /// más de 2 horas; las demás no cambian.
  Future<DeliveryPlan> updatePlanSchedule(String id, PlanSchedule schedule);

  /// `GET /orders/agenda?date=` — despachador con una central.
  Future<AgendaDay> agenda(String date);

  /// `GET /orders/history` — lo cerrado que despachó su central.
  Future<HistoryPage> history(HistoryQuery query);
}
