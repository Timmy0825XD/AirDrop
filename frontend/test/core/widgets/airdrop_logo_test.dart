import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/airdrop_logo.dart';

void main() {
  testWidgets('El logo se anuncia como logo de AirDrop', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AirDropLogo(size: 48))),
    );

    expect(find.bySemanticsLabel('Logo de AirDrop'), findsOneWidget);
    expect(tester.getSize(find.byType(AirDropLogo)), const Size.square(48));
    semantics.dispose();
  });

  testWidgets('El logo pinta la versión simple y la completa', (tester) async {
    // 32 px usa la versión simple (ficha y cruz) y 96 px la completa; las dos
    // deben pintar sin errores.
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(children: [AirDropLogo(size: 32), AirDropLogo(size: 96)]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AirDropLogo), findsNWidgets(2));
  });
}
