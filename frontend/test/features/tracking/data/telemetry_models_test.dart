import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';

Map<String, dynamic> mapView({
  String phase = 'cruise',
  String status = 'in_flight',
  int? eta = 125,
}) => {
  'orderId': 'o1',
  'droneId': 'd1',
  'identifier': 'D-01',
  'latitude': 10.46,
  'longitude': -73.25,
  'altitudeM': 100,
  'speedKmh': 90,
  'phase': phase,
  'leg': 'outbound',
  'status': status,
  'etaSeconds': eta,
};

void main() {
  test('la vista map no trae batería ni termómetro', () {
    final t = Telemetry.fromJson(mapView());
    expect(t.identifier, 'D-01');
    expect(t.phase, FlightPhase.cruise);
    expect(t.phase.label, 'Crucero');
    expect(t.status, OrderStatus.inFlight);
    expect(t.vitals, isNull);
    expect(t.etaMinutes, 3, reason: '125 s se redondea hacia arriba');
  });

  test('la vista full trae batería; temperatura null sin frío', () {
    final full = {
      ...mapView(),
      'batteryPercent': 80,
      'payloadKg': 0.5,
      'temperatureC': null,
      'latencyMs': 40,
    };
    final v = Telemetry.fromJson(full).vitals!;
    expect(v.batteryPercent, 80);
    expect(v.payloadKg, 0.5);
    expect(v.temperatureC, isNull);

    final cold = Telemetry.fromJson({...full, 'temperatureC': 5});
    expect(cold.vitals!.temperatureC, 5);
  });

  test('en tierra esperando la entrega: llegó y sin ETA', () {
    final t = Telemetry.fromJson(
      mapView(phase: 'landed', status: 'awaiting_delivery', eta: null),
    );
    expect(t.arrived, isTrue);
    expect(t.etaMinutes, isNull);
  });
}
