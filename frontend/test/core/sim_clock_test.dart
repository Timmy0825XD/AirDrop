import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/core/widgets/sim_clock_badge.dart';

void main() {
  group('SimClock', () {
    late DateTime real;
    late SimClock clock;
    final simNow = DateTime.utc(2026, 11, 6, 15, 4, 10);

    setUp(() {
      real = DateTime(2026, 11, 7, 9);
      clock = SimClock(realNow: () => real);
    });

    test('sin evento clock es la hora real', () {
      expect(clock.now(), real);
    });

    test('a x8, cinco minutos del código pasan en 37,5 s reales', () {
      clock.apply(ClockView(now: simNow, speed: 8, paused: false));
      real = real.add(const Duration(milliseconds: 37500));

      expect(clock.now(), simNow.add(const Duration(minutes: 5)).toLocal());
    });

    test('en pausa no avanza', () {
      clock.apply(ClockView(now: simNow, speed: 4, paused: true));
      real = real.add(const Duration(minutes: 3));

      expect(clock.now(), simNow.toLocal());
    });

    test('al cerrar la sesión vuelve a la hora real', () {
      clock.apply(ClockView(now: simNow, speed: 2, paused: false));
      clock.reset();

      expect(clock.now(), real);
      expect(clock.view.value, isNull);
    });

    test('lee el evento de Nest', () {
      final view = ClockView.fromJson({
        'now': '2026-11-06T15:04:10.000Z',
        'speed': 4,
        'paused': false,
      });

      expect(view.now, simNow);
      expect(view.speed, 4);
      expect(view.isAltered, isTrue);
      expect(
        ClockView.fromJson({
          'now': '2026-11-06T15:04:10.000Z',
          'speed': 1,
          'paused': false,
        }).isAltered,
        isFalse,
      );
    });
  });

  testWidgets('el aviso sale solo cuando la consola cambia el ritmo', (
    tester,
  ) async {
    addTearDown(simClock.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SimClockBadge())),
    );
    expect(find.textContaining('Simulación'), findsNothing);

    final now = DateTime.utc(2026, 11, 6, 15);
    simClock.apply(ClockView(now: now, speed: 4, paused: false));
    await tester.pumpAndSettle();
    expect(find.text('Simulación ×4'), findsOneWidget);

    simClock.apply(ClockView(now: now, speed: 4, paused: true));
    await tester.pumpAndSettle();
    expect(find.text('Simulación en pausa'), findsOneWidget);

    simClock.apply(ClockView(now: now, speed: 1, paused: false));
    await tester.pumpAndSettle();
    expect(find.textContaining('Simulación'), findsNothing);
  });
}
