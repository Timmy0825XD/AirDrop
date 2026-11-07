import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/pending_load_screen.dart';

Future<void> _pumpTray(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PendingLoadScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un toque solo abre la revisión: el dron no despega', (
    tester,
  ) async {
    await _pumpTray(tester);

    expect(find.text('Insulina glargina 100 UI/ml'), findsOneWidget);
    expect(find.text('Dron D-01 · 4,2 km · 100 m'), findsOneWidget);

    await tester.tap(find.text('Revisar y cargar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Lo que se revisa con el paquete en la mano.
    expect(find.text('Revisa la carga'), findsOneWidget);
    expect(find.text('Insulina glargina 100 UI/ml · 1 unidad'), findsOneWidget);
    expect(find.text('Va en nevera, de 2 a 8 °C'), findsOneWidget);
    expect(find.text('Dron D-01 · 4,2 km'), findsOneWidget);
    expect(find.text('Desliza para despegar'), findsOneWidget);

    // Cerrar la hoja sin deslizar no confirma nada.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Revisa la carga'), findsNothing);
    expect(find.text('Insulina glargina 100 UI/ml'), findsOneWidget);
    expect(
      find.text('Carga confirmada. El vuelo arranca en segundos.'),
      findsNothing,
    );
  });

  testWidgets('deslizar para despegar confirma la carga', (tester) async {
    await _pumpTray(tester);

    await tester.tap(find.text('Revisar y cargar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(
      find.byIcon(Icons.flight_takeoff_rounded),
      const Offset(800, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No hay drones esperando carga.'), findsOneWidget);
    expect(
      find.text('Carga confirmada. El vuelo arranca en segundos.'),
      findsOneWidget,
    );
  });
}
