import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/plan_detail/plan_sections.dart';
import 'package:frontend/features/orders/presentation/widgets/watch_flight_button.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('"Ver vuelo" deja el mapa encima y se puede volver', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/orders/in-flight',
      routes: [
        GoRoute(
          path: '/orders/in-flight',
          builder: (_, _) => const Scaffold(
            body: Center(child: WatchFlightButton(orderId: 'o-1')),
          ),
        ),
        GoRoute(
          path: '/tracking/:orderId',
          builder: (_, state) =>
              Scaffold(body: Text('Mapa ${state.pathParameters['orderId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Ver vuelo'));
    await tester.pumpAndSettle();
    expect(find.text('Mapa o-1'), findsOneWidget);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Ver vuelo'), findsOneWidget);
  });

  testWidgets('las entregas del plan no muestran el id del dron', (
    tester,
  ) async {
    const droneId = 'd7a1c3e0-1111-4111-8111-111111111111';
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanOccurrences(
            occurrences: const [
              PlanOccurrence(
                id: 'o-9',
                status: OrderStatus.pendingLoad,
                scheduledFor: '2026-10-20',
                droneId: droneId,
              ),
            ],
            onOpen: (id) => opened = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-10-20'), findsOneWidget);
    expect(find.text('Pendiente de carga'), findsOneWidget);
    expect(find.textContaining(droneId), findsNothing);

    await tester.tap(find.text('2026-10-20'));
    expect(opened, 'o-9');
  });

  test('un error que no es de Nest no se muestra crudo', () {
    expect(
      ApiException.messageOf(const ApiException('El pedido no existe.')),
      'El pedido no existe.',
    );
    expect(
      ApiException.messageOf(const FormatException('Estado desconocido: x')),
      'No se pudo cargar la información. Intenta de nuevo.',
    );
  });
}
