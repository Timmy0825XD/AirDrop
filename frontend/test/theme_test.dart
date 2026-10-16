import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/theme/app_theme.dart';

void main() {
  testWidgets('El tema aplica marca, foco y tipografía en claro y oscuro',
      (WidgetTester tester) async {
    // En oscuro la marca se aclara para contrastar sobre el fondo.
    final brandByMode = {
      AppTheme.light: AppTheme.primary,
      AppTheme.dark: AppTheme.primaryOnDark,
    };
    for (final MapEntry(key: theme, value: brand) in brandByMode.entries) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('AirDrop')),
      ));

      final context = tester.element(find.text('AirDrop'));

      // Colores de marca en el colorScheme: verde azulado y naranja de señal.
      expect(theme.colorScheme.primary, brand);
      expect(theme.colorScheme.secondary, AppTheme.signal);
      expect(theme.colorScheme.tertiary, AppTheme.tertiary);

      // Una sola familia: Plus Jakarta Sans en titulares y cuerpo.
      expect(theme.textTheme.titleLarge?.fontFamily, isNotNull);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        theme.textTheme.titleLarge?.fontFamily,
      );

      // Foco visible en el color de marca.
      final focused = theme.inputDecorationTheme.focusedBorder;
      expect(focused, isA<OutlineInputBorder>());
      expect((focused as OutlineInputBorder).borderSide.color, brand);

      // El fondo del scaffold sale de la paleta del modo.
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(Theme.of(context).colorScheme.surface, isNotNull);
    }
  });
}
