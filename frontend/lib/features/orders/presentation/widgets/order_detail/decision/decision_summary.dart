import '../../../../data/order_models.dart';
import '../../../order_format.dart';

/// La línea de arriba de "¿Por qué este dron?": qué decidió el motor, en
/// una frase. Sin traza, lo dice (el motor todavía no lo evaluó o se
/// decidió antes de que se guardara).
String decisionSummary(OrderDecision decision) {
  final trace = decision.trace;
  if (trace == null) {
    return decision.offers == null
        ? 'El motor todavía no decidió este pedido, o se decidió antes de '
              'que guardáramos la traza.'
        : 'Todavía no hay dron asignado. Abajo, a qué centrales se ofreció.';
  }
  final chosen = trace.chosen;
  final summary = trace.outcome == DecisionOutcome.assigned && chosen != null
      ? 'Se asignó ${chosen.drone.identifier} de ${chosen.hub.name}.'
      : '${trace.outcome.label}.';
  final reason = trace.reason;
  return reason == null || reason.isEmpty ? summary : '$summary $reason';
}

/// "11 km · 5,4 min · batería 56 %" de una central; lo que falte no sale.
String hubTraceFacts(HubTrace hub) {
  final km = hub.corridorKm;
  final eta = hub.etaMin;
  final battery = hub.batteryNeededPercent;
  return [
    if (km != null) formatKm(km),
    if (eta != null) '${eta.toStringAsFixed(1).replaceAll('.', ',')} min',
    if (battery != null) 'pide ${battery.round()} % de batería',
    if (!hub.lot) 'sin lote',
  ].join(' · ');
}
