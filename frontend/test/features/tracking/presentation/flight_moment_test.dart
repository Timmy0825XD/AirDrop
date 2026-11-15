import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/airdrop_logo.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/features/tracking/presentation/flight_moment.dart';

TrackingState _state(OrderStatus? status, {bool loading = false}) =>
    TrackingState(loading: loading, status: status);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('despegue, entrega y retorno se reconocen por el cambio de estado', () {
    expect(
      flightMomentBetween(
        _state(OrderStatus.pendingLoad),
        _state(OrderStatus.inFlight),
      ),
      FlightMoment.takeoff,
    );
    expect(
      flightMomentBetween(
        _state(OrderStatus.awaitingDelivery),
        _state(OrderStatus.delivered),
      ),
      FlightMoment.delivered,
    );
    expect(
      flightMomentBetween(
        _state(OrderStatus.awaitingDelivery),
        _state(OrderStatus.returning),
      ),
      FlightMoment.returning,
    );
  });

  test('abrir el mapa de un pedido que ya vuela no es un despegue', () {
    expect(flightMomentBetween(null, _state(OrderStatus.inFlight)), isNull);
    expect(
      flightMomentBetween(
        _state(null, loading: true),
        _state(OrderStatus.inFlight),
      ),
      isNull,
    );
    expect(
      flightMomentBetween(
        _state(OrderStatus.inFlight),
        _state(OrderStatus.inFlight),
      ),
      isNull,
    );
  });

  test('cada momento vibra una vez: el retorno pide atención', () async {
    final calls = <Object?>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    feelFlightMoment(FlightMoment.takeoff);
    feelFlightMoment(FlightMoment.arrival);
    feelFlightMoment(FlightMoment.returning);
    await Future<void>.delayed(Duration.zero);

    expect(calls, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  testWidgets('el logo del arranque gira los rotores y se detiene', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: LiveLogo())));
    double turns() =>
        tester.widget<AirDropLogo>(find.byType(AirDropLogo)).rotorTurns;

    await tester.pump(const Duration(milliseconds: 400));
    expect(turns(), greaterThan(0));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    // Termina en vueltas enteras: la misma posición del logo quieto.
    expect(turns(), 3);
  });

  testWidgets('con reducir movimiento el logo no gira', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: LiveLogo()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<AirDropLogo>(find.byType(AirDropLogo)).rotorTurns, 0);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
