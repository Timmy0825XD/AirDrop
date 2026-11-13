import '../../../../orders/presentation/order_format.dart' show formatKm;
import '../../../data/fleet_map_models.dart';

/// El texto del aviso de `hub-reroute` (§18.2). [drone] es la matrícula del
/// dron si el mapa ya conoce el vuelo.
String rerouteMessage(FleetReroute reroute, {String? drone}) {
  final who = drone == null ? '' : '$drone: ';
  if (reroute.blocked) {
    return _capitalize('${who}sin ruta segura, el dron sigue el protocolo');
  }
  final km = reroute.addedKm;
  // Un desvío de menos de 50 m saldría "+0,0 km": solo se dice que cambió.
  final changed = km == null || km < 0.05
      ? 'ruta cambiada'
      : 'ruta cambiada (+${formatKm(km)})';
  final battery = reroute.batteryShort
      ? '; la batería no alcanza con la reserva'
      : '';
  return _capitalize('$who$changed$battery');
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
