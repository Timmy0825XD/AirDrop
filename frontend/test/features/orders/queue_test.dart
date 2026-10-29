import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/queue_screen.dart';

void main() {
  testWidgets('la cola pinta Sin atender cuando unattended es true', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QueueScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acetaminofén 500 mg'), findsOneWidget);
    expect(find.text('Sin atender'), findsOneWidget);
    expect(find.textContaining('Disponible: 8'), findsNWidgets(2));
  });

  testWidgets('un pedido que pasó de otra central se marca en la cola', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
        ],
        child: const MaterialApp(home: QueueScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofeno 400 mg'), findsOneWidget);
    expect(find.text('Viene de otra central'), findsOneWidget);
  });
}
