import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/auto_refresh.dart';

void main() {
  testWidgets('refresca cada intervalo y se apaga al salir', (tester) async {
    var ticks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AutoRefresh(
          every: const Duration(seconds: 10),
          onTick: () => ticks++,
          child: const Text('lista'),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 25));
    expect(ticks, 2);

    await tester.pumpWidget(const MaterialApp(home: Text('otra')));
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 2, reason: 'el reloj se cancela al salir de la pantalla');
  });
}
