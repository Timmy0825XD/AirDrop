import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/airdrop_app.dart';

void main() {
  testWidgets('El registro pide el consentimiento y valida antes de enviar',
      (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: AirDropApp()));
    await tester.pumpAndSettle();

    final toRegister = find.widgetWithText(TextButton, 'Regístrate');
    await tester.ensureVisible(toRegister);
    await tester.tap(toRegister);
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('NÚMERO DE DOCUMENTO'), findsOneWidget);
    expect(find.text('6 a 10 dígitos'), findsOneWidget);

    // Sin consentimiento el botón está apagado.
    final create = find.widgetWithText(ElevatedButton, 'Crear cuenta');
    expect(tester.widget<ElevatedButton>(create).onPressed, isNull);

    // El PPT cambia la nota del número.
    await tester.tap(find.text('PPT'));
    await tester.pumpAndSettle();
    expect(find.text('6 a 15 letras o números'), findsOneWidget);

    final consent = find.textContaining('Acepto el tratamiento');
    await tester.ensureVisible(consent);
    await tester.tap(consent);
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(create).onPressed, isNotNull);

    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(find.text('Escribe tu celular.'), findsOneWidget);
  });
}
