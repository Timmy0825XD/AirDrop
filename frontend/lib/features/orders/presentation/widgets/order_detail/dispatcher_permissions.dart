import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Qué puede hacer un despachador sobre un pedido, según su central.
///
/// La decisión final la toma Nest (responde 403 si no le toca); esto solo
/// evita mostrar botones que no aplican.
class DispatcherPermissions {
  const DispatcherPermissions({required this.order, required this.myHubId});

  final Order order;

  /// La central del despachador (tiene una sola).
  final String? myHubId;

  /// Su central solo recibe el traslado: ve el pedido, pero no lo autoriza
  /// ni confirma la carga.
  bool get onlyDestination =>
      myHubId != null &&
      order.destinationHubId == myHubId &&
      order.originHubId != myHubId;

  /// Autorizar o rechazar: solo mientras sigue en recibido.
  bool get canDecide =>
      order.status == OrderStatus.received && !onlyDestination;

  /// Confirmar la carga: autorizado, sin carga confirmada y salió de su
  /// central.
  bool get canConfirmLoad =>
      order.awaitsLoad && myHubId != null && order.originHubId == myHubId;

  /// Persona + bajo fórmula: Nest exige `prescriptionVerified: true`.
  bool get needsPrescriptionCheck =>
      order.destinationKind == DestinationKind.person &&
      order.saleType == SaleType.prescription;

  /// La imagen solo se puede bajar en una urgencia civil (no en planes).
  bool get canViewPrescription =>
      needsPrescriptionCheck && order.missionType == MissionType.emergency;

  /// Programado con fecha futura en Bogotá.
  bool get notYet => isFutureSchedule(order.scheduledFor);
}
