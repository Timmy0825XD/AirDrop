import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/corridor_art.dart';
import 'package:frontend/core/widgets/drone_mark.dart';
import 'package:frontend/core/widgets/route_line.dart';
import 'package:frontend/features/home/presentation/widgets/requester/first_order_card.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/emergency_facts.dart';
import 'package:frontend/features/tracking/presentation/tracking_screen.dart';
import 'package:frontend/theme/app_theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool still = false,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  );
  // La ruta se dibuja al aparecer: se espera a que termine.
  if (settle) await tester.pump(const Duration(seconds: 1));
}

double _droneLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byType(DroneMark)).dx -
    tester.getTopLeft(find.byType(RouteLine)).dx;

void main() {
  testWidgets('la ruta pone el dron donde dice el avance', (tester) async {
    await _pump(tester, const RouteLine(endLabel: 'Guacoche', progress: 0));
    expect(_droneLeft(tester), closeTo(0, 0.5));

    await _pump(tester, const RouteLine(endLabel: 'Guacoche', progress: 1));
    expect(_droneLeft(tester), closeTo(320 - 30, 0.5));

    expect(find.text('Central'), findsOneWidget);
    expect(find.text('Guacoche'), findsOneWidget);
  });

  testWidgets('al aparecer la ruta se dibuja y el dron sale de la central', (
    tester,
  ) async {
    await _pump(
      tester,
      const RouteLine(endLabel: 'Guacoche', progress: 1),
      settle: false,
    );
    expect(_droneLeft(tester), closeTo(0, 0.5));

    await tester.pump(const Duration(seconds: 1));
    expect(_droneLeft(tester), closeTo(320 - 30, 0.5));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con reducir movimiento la ruta aparece ya dibujada', (
    tester,
  ) async {
    await _pump(
      tester,
      const RouteLine(endLabel: 'Guacoche', progress: 1),
      still: true,
      settle: false,
    );
    expect(_droneLeft(tester), closeTo(320 - 30, 0.5));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('sin avance y sin flotar, el dron espera en la central', (
    tester,
  ) async {
    await _pump(
      tester,
      const RouteLine(endLabel: 'Tu ubicación', hover: false),
    );
    expect(_droneLeft(tester), closeTo(0, 0.5));
    // No queda ninguna animación corriendo.
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('un nombre largo de destino se corta sin desbordar', (
    tester,
  ) async {
    await _pump(
      tester,
      const RouteLine(
        endLabel: 'Punto de entrega con un nombre bastante largo para caber',
        progress: 0.5,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quien no ha pedido ve la invitación y puede pedir', (
    tester,
  ) async {
    var asked = 0;
    await _pump(tester, FirstOrderCard(onOrder: () => asked++));

    final art = tester.widget<CorridorArt>(find.byType(CorridorArt));
    expect(art.scene, CorridorScene.route);
    expect(find.text('Pide tu primera urgencia'), findsOneWidget);
    await tester.tap(find.text('Pedir urgencia'));
    expect(asked, 1);
  });

  testWidgets('el resumen de la urgencia no promete dron ni fabricante', (
    tester,
  ) async {
    await _pump(tester, const EmergencyFacts());

    expect(find.byType(RouteLine), findsOneWidget);
    expect(find.textContaining('Un despachador revisa'), findsOneWidget);
    expect(find.textContaining('Wingcopter'), findsNothing);
  });

  test('el mapa se resume en una frase para el lector de pantalla', () {
    expect(
      flightMapSummary(
        status: OrderStatus.inFlight,
        forRequester: false,
        etaMinutes: 6,
        destination: 'Guacoche, cancha principal',
      ),
      'Mapa del vuelo. ${OrderStatus.inFlight.label}. Destino: Guacoche. '
      'Llega en 6 minutos.',
    );
    expect(
      flightMapSummary(status: null, forRequester: true, etaMinutes: 1),
      'Mapa del vuelo. Llega en 1 minuto.',
    );
  });
}
