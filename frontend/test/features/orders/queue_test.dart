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
    expect(find.textContaining('Disponible: 8'), findsOneWidget);
  });
}
