import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/airdrop_app.dart';

void main() {
  testWidgets('Recuperar contraseña valida el correo antes de enviar',
      (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: AirDropApp()));
    await tester.pumpAndSettle();

    final forgot = find.text('¿Olvidaste tu contraseña?');
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.text('El código dura 15 minutos.'), findsOneWidget);

    final send = find.widgetWithText(ElevatedButton, 'Enviar código');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu correo.'), findsOneWidget);

    // Volver lleva al login sin repetir el splash.
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión'), findsWidgets);
  });
}
