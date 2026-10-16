import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/airdrop_app.dart';

void main() {
  testWidgets('La app arranca en la ruta de login', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const ProviderScope(child: AirDropApp()));
    await tester.pump();

    // El nombre entra letra por letra; se lee entero por accesibilidad.
    expect(find.bySemanticsLabel(RegExp('AirDrop')), findsOneWidget);
    semantics.dispose();
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget);
    expect(find.text('¿No tienes cuenta?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('El login salta el splash con reducir movimiento y valida '
      'antes de llamar a la API', (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: AirDropApp()));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'nombre@correo');
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu correo.'), findsNothing);
  });
}
