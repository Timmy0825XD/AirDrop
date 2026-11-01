import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/slide_to_launch.dart';
import 'package:frontend/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, Future<void> Function() onLaunch) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SlideToLaunch(
            label: 'Desliza para despegar',
            loadingLabel: 'Enviando la urgencia',
            onLaunch: onLaunch,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('soltar a mitad de camino no lanza y el botón vuelve', (
    tester,
  ) async {
    var launched = 0;
    await _pump(tester, () async => launched++);

    final knob = find.byIcon(Icons.flight_takeoff_rounded);
    await tester.drag(knob, const Offset(80, 0));
    await tester.pump(const Duration(seconds: 2));

    expect(launched, 0);
    expect(find.text('Desliza para despegar'), findsOneWidget);
  });

  testWidgets('deslizar hasta el final lanza una vez y, si sigue la pantalla, '
      'vuelve al inicio', (tester) async {
    var launched = 0;
    await _pump(tester, () async => launched++);

    await tester.drag(
      find.byIcon(Icons.flight_takeoff_rounded),
      const Offset(600, 0),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(launched, 1);
    // El envío terminó sin cerrar la pantalla: vuelve a estar listo.
    expect(find.text('Desliza para despegar'), findsOneWidget);
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
  });
}
