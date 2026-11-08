import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/order_format.dart';
import 'package:frontend/features/orders/presentation/widgets/order_status_chip.dart';

void main() {
  test('el solicitante ve el estado en sus palabras', () {
    String plain(OrderStatus s) => OrderStatusChip.requesterLabel(s);
    expect(plain(OrderStatus.received), 'Esperando central');
    expect(plain(OrderStatus.pendingLoad), 'Preparando el envío');
    expect(plain(OrderStatus.inFlight), 'En camino');
    expect(plain(OrderStatus.delivered), 'Entregado');
    expect(plain(OrderStatus.returned), 'No se entregó');
    expect(plain(OrderStatus.reassigned), 'Lo atiende otra central');
    // El regreso del dron no se le muestra: también "No se entregó".
    expect(plain(OrderStatus.returning), 'No se entregó');
  });

  test('el despachador conserva el estado técnico', () {
    expect(
      OrderStatusChip.labelOf(OrderStatus.pendingLoad, forRequester: false),
      'Pendiente de carga',
    );
  });

  testWidgets('la pastilla cambia según quién mira', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            OrderStatusChip(status: OrderStatus.inFlight, forRequester: true),
            OrderStatusChip(status: OrderStatus.inFlight),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('En camino'), findsOneWidget);
    expect(find.text('En vuelo'), findsOneWidget);
  });

  test('las cantidades largas van en palabras', () {
    expect(unitsLabel(1), '1 unidad');
    expect(unitsLabel(3), '3 unidades');
  });
}
