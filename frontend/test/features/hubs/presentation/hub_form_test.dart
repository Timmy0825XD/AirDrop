import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/presentation/widgets/hub_form_values.dart';
import 'package:frontend/features/hubs/presentation/widgets/hub_tile.dart';
import 'package:latlong2/latlong.dart';

Hub _hub(HubStatus status) => Hub(
  id: 'h1',
  name: 'Farmacia Centro',
  type: HubType.pharmacy,
  address: 'Calle 15 # 4-20',
  latitude: 10.47,
  longitude: -73.25,
  contactPhone: '3156009921',
  status: status,
);

void main() {
  group('HubFormValues', () {
    test('sin tocar el mapa pide la ubicación', () {
      final values = HubFormValues()
        ..name.text = 'Hospital de Valencia de Jesús'
        ..address.text = 'Calle 5 # 3-12'
        ..phone.text = '300 412 7788';
      addTearDown(values.dispose);

      expect(values.validate(), {
        HubInput.location: 'Toca el mapa para ubicar la central.',
      });
    });

    test('arma el body con el punto del mapa y sin correo vacío', () {
      final values = HubFormValues()
        ..name.text = '  Hospital de Valencia de Jesús '
        ..address.text = 'Calle 5 # 3-12'
        ..phone.text = '+57 300 412 7788'
        ..type = HubType.clinic
        ..location = const LatLng(10.330123456, -73.380987654);
      addTearDown(values.dispose);

      expect(values.validate(), isEmpty);
      expect(values.request().toJson(), {
        'name': 'Hospital de Valencia de Jesús',
        'type': 'clinic',
        'address': 'Calle 5 # 3-12',
        'latitude': 10.330123,
        'longitude': -73.380988,
        'contactPhone': '3004127788',
      });
    });
  });

  testWidgets('la tarjeta ofrece la acción contraria al estado', (
    tester,
  ) async {
    Future<void> pump(HubStatus status) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubTile(hub: _hub(status), onToggle: () {}),
        ),
      ),
    );

    await pump(HubStatus.active);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Suspender'), findsOneWidget);

    await pump(HubStatus.suspended);
    await tester.pumpAndSettle();
    expect(find.text('Suspendida'), findsOneWidget);
    expect(find.text('Reactivar'), findsOneWidget);
  });
}
