import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/hub_request/transfer_map.dart';

void main() {
  test('la central de origen trae sus coordenadas (o ninguna)', () {
    final hub = OriginHub.fromJson({
      'id': 'c1',
      'name': 'Hospital Rosario Pumarejo',
      'address': 'Calle 16',
      'latitude': 10.4742,
      'longitude': '-73.2436',
    });
    expect(hub.latitude, 10.4742);
    expect(hub.longitude, -73.2436);

    final old = OriginHub.fromJson({
      'id': 'c1',
      'name': 'Hospital Rosario Pumarejo',
      'address': 'Calle 16',
    });
    expect(old.latitude, isNull);
  });

  test('el mapa del traslado sale solo con origen elegido y coordenadas', () {
    const origin = OriginHub(
      id: 'c1',
      name: 'Hospital Rosario Pumarejo',
      address: 'Calle 16',
      latitude: 10.4742,
      longitude: -73.2436,
    );
    final mine = Hub.fromJson({
      'id': 'h1',
      'name': 'Central Demo',
      'type': 'hospital',
      'status': 'active',
      'address': 'Calle 15',
      'latitude': 10.46314,
      'longitude': -73.25322,
      'contactPhone': '6055700000',
    });

    expect(
      transferMapOf(origins: [origin], originHubId: null, mine: mine),
      isNull,
    );
    expect(
      transferMapOf(
        origins: const [OriginHub(id: 'c1', name: 'X', address: 'Y')],
        originHubId: 'c1',
        mine: mine,
      ),
      isNull,
    );
    expect(
      transferMapOf(origins: [origin], originHubId: 'c1', mine: mine),
      isNotNull,
    );
  });

  testWidgets('el mapa del traslado dice de dónde sale y la distancia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TransferMap(
            from: LatLng(10.4742, -73.2436),
            fromName: 'Hospital Rosario Pumarejo',
            to: LatLng(10.46314, -73.25322),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('De Hospital Rosario Pumarejo a tu central · '),
      findsOneWidget,
    );
    expect(find.textContaining('km en línea recta'), findsOneWidget);
  });
}
