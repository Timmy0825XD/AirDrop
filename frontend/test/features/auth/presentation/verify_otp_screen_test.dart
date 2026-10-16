import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/verify_otp_screen.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  testWidgets('Verificar se enciende solo con los 6 dígitos del código',
      (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: VerifyOtpScreen(
            contact: AuthContact.email('valentina.morales@correo.com'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verifica tu cuenta'), findsOneWidget);
    expect(find.text('Paso 2 de 2'), findsOneWidget);
    expect(find.textContaining('valentina.morales@correo.com'), findsOneWidget);
    expect(find.text('Puedes reenviarlo en'), findsOneWidget);

    final verify = find.widgetWithText(ElevatedButton, 'Verificar');
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '12a3');
    await tester.pump();
    expect(find.text('3'), findsOneWidget, reason: 'solo entran dígitos');
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNotNull);

    // El temporizador del reenvío es periódico: se desmonta para cerrarlo.
    await tester.pumpWidget(const SizedBox());
  });
}
