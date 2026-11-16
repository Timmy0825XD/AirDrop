import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/tracking/presentation/widgets/flight_map.dart';

void main() {
  testWidgets('sin ruta todavía, el mapa abre sin la línea', (tester) async {
    // flutter_map revienta con una línea vacía; el pedido aún sin
    // assignment llega con la ruta vacía.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FlightMap(route: []))),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOne);
    expect(find.byType(PolylineLayer), findsNothing);
  });

  testWidgets('con ruta pinta el corredor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlightMap(
            route: [
              [-73.25, 10.46],
              [-73.24, 10.47],
            ],
          ),
        ),
      ),
    );

    expect(find.byType(PolylineLayer), findsOne);
  });
}
