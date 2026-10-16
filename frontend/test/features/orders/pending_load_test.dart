import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/pending_load_screen.dart';

void main() {
  testWidgets('confirmar la carga saca el pedido de la bandeja', (
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
        child: const MaterialApp(home: PendingLoadScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insulina glargina 100 UI/ml'), findsOneWidget);
    expect(find.text('Dron D-01 · 4,2 km · 100 m'), findsOneWidget);

    await tester.tap(find.text('Confirmar carga'));
    await tester.pumpAndSettle();

    expect(find.text('No hay drones esperando carga.'), findsOneWidget);
    expect(
      find.text('Carga confirmada. El vuelo arranca en segundos.'),
      findsOneWidget,
    );
  });
}
