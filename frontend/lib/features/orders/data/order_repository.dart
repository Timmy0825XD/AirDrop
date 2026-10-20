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
}
