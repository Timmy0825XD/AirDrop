import '../../../core/app_haptics.dart';
import '../../orders/data/order_models.dart' show OrderStatus;
import '../data/tracking_providers.dart';

/// Los momentos del vuelo que la persona tiene que sentir aunque no esté
/// mirando la pantalla.
enum FlightMoment {
  /// El dron despegó con el pedido.
  takeoff,

  /// El dron llegó al punto: corren los 5 minutos del código.
  arrival,

  /// El pedido se entregó con el código.
  delivered,

  /// No se entregó: el dron vuelve con el paquete.
  returning,
}

/// El momento que acaba de pasar entre dos estados del vuelo, si pasó
/// alguno. La primera lectura no cuenta: abrir el mapa de un pedido que ya
/// va en el aire no es un despegue.
FlightMoment? flightMomentBetween(TrackingState? before, TrackingState now) {
  if (before == null || before.loading) return null;
  if (before.status != now.status) {
    switch (now.status) {
      case OrderStatus.inFlight:
        return FlightMoment.takeoff;
      case OrderStatus.delivered:
        return FlightMoment.delivered;
      case OrderStatus.returning:
        return FlightMoment.returning;
      default:
        break;
    }
  }
  final arrived = now.telemetry?.arrived ?? false;
  final wasThere = before.telemetry?.arrived ?? false;
  if (arrived && !wasThere && before.telemetry != null) {
    return FlightMoment.arrival;
  }
  return null;
}

/// La vibración de cada momento. El retorno pide atención; los demás son
/// buenas noticias.
void feelFlightMoment(FlightMoment moment) => switch (moment) {
  FlightMoment.returning => AppHaptics.warning(),
  FlightMoment.takeoff => AppHaptics.confirm(),
  FlightMoment.arrival || FlightMoment.delivered => AppHaptics.success(),
};
