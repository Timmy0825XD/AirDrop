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

  /// Autorizar o rechazar: mientras sigue en recibido, o si otra central
  /// se lo pasó a la suya (fallback `hub`, CU-31).
  bool get canDecide =>
      (order.status == OrderStatus.received || order.reassignedToHub) &&
      !onlyDestination;

  /// Confirmar la carga: autorizado, sin carga confirmada y salió de su
  /// central.
  bool get canConfirmLoad =>
      order.awaitsLoad && myHubId != null && order.originHubId == myHubId;

  /// Ver el vuelo: la central de origen y la que recibe el traslado (esta
  /// solo ve el mapa). Entregado también: el dron vuelve a su central.
  bool get canWatchFlight =>
      (order.hasFlight || order.status == OrderStatus.delivered) &&
      myHubId != null &&
      (order.originHubId == myHubId || onlyDestination);

  /// El código de un traslado: lo ve la central de destino desde que se
  /// confirma la carga, y lo escribe cuando el dron aterriza allí.
  bool get canReceive =>
      order.deliveryCodeVisible &&
      order.destinationKind == DestinationKind.hub &&
      myHubId != null &&
      order.destinationHubId == myHubId;

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

/// Un programado se autoriza y se carga entre 2 horas antes de su franja
/// y el cierre. Es una pista: la autoridad es el mensaje de Nest.
String? dispatchWindowNote(Order order, DateTime now) {
  if (isFutureSchedule(order.scheduledFor)) {
    return 'Este pedido programado todavía no llega a su fecha.';
  }
  final opensAt = order.scheduledAt?.subtract(const Duration(hours: 2));
  if (opensAt != null && now.isBefore(opensAt)) {
    return 'Disponible desde las ${formatClock(opensAt)} (2 horas antes '
        'de la franja).';
  }
  final closesAt = order.windowEndsAt;
  if (closesAt != null && now.isAfter(closesAt)) {
    return 'La franja de esta entrega ya cerró.';
  }
  return null;
}

/// Llegó de otra central que no tenía dron (fallback `hub`).
bool cameFromOtherHub(DispatcherPermissions can) =>
    can.order.reassignedFromHubId != null &&
    can.order.originHubId == can.myHubId;

/// Revisar el empaque de un pedido devuelto: la central de origen, una
/// sola vez (HU-34).
bool canReturnCheck(DispatcherPermissions can) =>
    can.order.awaitsReturnCheck &&
    can.myHubId != null &&
    can.order.originHubId == can.myHubId;
