import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/in_flight_screen.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InFlightScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin vuelos lo dice', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text('Ningún dron de tu central está volando ahora.'),
      findsOneWidget,
    );
  });

  testWidgets('al confirmar la carga el pedido pasa a vuelos en curso', (
    tester,
  ) async {
    final repo = container.read(orderRepositoryProvider);
    final pending = (await repo.listPendingLoad()).first;
    await container
        .read(orderDispatchProvider.notifier)
        .confirmLoad(pending.id);

    await pumpScreen(tester);

    expect(find.text('Vuelos en curso'), findsOneWidget);
    expect(find.text('1 dron en el aire'), findsOneWidget);
    expect(find.text(pending.medicationName), findsOneWidget);
    expect(find.text('Dron D-01 · 4,2 km · 100 m'), findsOneWidget);
    expect(find.text('En vuelo'), findsOneWidget);
    expect(find.text('Ver vuelo'), findsOneWidget);
  });
}
