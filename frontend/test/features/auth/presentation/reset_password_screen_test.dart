import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/reset_password_screen.dart';
import 'package:frontend/features/auth/presentation/widgets/reset/reset_password_strength.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  test('El medidor sube con largo, mayúsculas, números y símbolos', () {
    expect(PasswordScore.of(''), 0);
    expect(PasswordScore.of('abc'), 0);
    expect(PasswordScore.of('Abc1'), 1, reason: 'menos de 8: débil');
    expect(PasswordScore.of('abcdefgh'), 1);
    expect(PasswordScore.of('abcdefg1'), 2);
    expect(PasswordScore.of('Abcdefg1'), 3);
    expect(PasswordScore.of('Abcdefg1!'), 4);
  });

  testWidgets('Nueva contraseña valida código, clave y confirmación',
      (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: ResetPasswordScreen(
            contact: AuthContact.email('valentina.morales@correo.com'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('CÓDIGO DE VERIFICACIÓN'), findsOneWidget);

    final update = find.widgetWithText(ElevatedButton, 'Actualizar contraseña');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(find.text('Escribe los 6 dígitos del código.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(find.text('Confirma tu nueva contraseña.'), findsOneWidget);

    // La confirmación avisa en vivo cuando ya no puede coincidir.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Abcdefg1');
    await tester.enterText(fields.at(2), 'Abcdefg2');
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(find.text('Segura'), findsOneWidget);

    await tester.enterText(fields.at(2), 'Abcdefg1');
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsNothing);
    expect(find.bySemanticsLabel('Las contraseñas coinciden'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
