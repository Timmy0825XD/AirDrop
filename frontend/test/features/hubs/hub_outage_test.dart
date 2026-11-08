import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/presentation/widgets/hub_outage.dart';
import 'package:frontend/features/notifications/data/notice_models.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/confirm_load_section.dart';
import 'package:frontend/theme/app_theme.dart';

Hub _hub(String? outageUntil) => Hub.fromJson({
  'id': 'h1',
  'name': 'Hospital Rosario Pumarejo',
  'type': 'hospital',
  'address': 'Calle 16',
  'latitude': 10.46,
  'longitude': -73.25,
  'contactPhone': '6055700000',
  'status': 'active',
  'powerOutageUntil': outageUntil,
});

void main() {
  // La hora de la consola: 15:00 en Valledupar (20:00 UTC).
  setUp(() {
    simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 7, 20), speed: 1, paused: true),
    );
  });
  tearDown(simClock.reset);

  test('sin energía hasta una hora futura bloquea; una pasada, no', () {
    final dark = _hub('2026-11-07T20:40:00.000Z');
    expect(dark.poweredAt(simClock.now()), isFalse);
    expect(
      hubOutageNote(dark),
      'Central sin energía hasta las 3:40 p. m. '
      'No puedes autorizar ni confirmar cargas.',
    );

    // Nest puede mandar la fecha vieja hasta que barre el apagón.
    expect(hubOutageNote(_hub('2026-11-07T19:00:00.000Z')), isNull);
    expect(hubOutageNote(_hub(null)), isNull);
  });

  test('los avisos de energía llevan a la central', () {
    expect(NoticeKind.fromJson('hub_outage'), NoticeKind.hubOutage);
    expect(NoticeKind.hubPowerRestored.isHubPower, isTrue);
    expect(NoticeKind.departed.isHubPower, isFalse);
  });

  testWidgets('sin energía, "Revisar y cargar" queda apagado con el motivo', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ConfirmLoadSection(
            busy: false,
            loading: false,
            onConfirm: () => tapped = true,
            blockedNote: hubOutageNote(_hub('2026-11-07T20:40:00.000Z')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Central sin energía'), findsOneWidget);
    await tester.tap(find.text('Revisar y cargar'), warnIfMissed: false);
    expect(tapped, isFalse);
  });
}
