import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/theme/app_theme.dart';

void main() {
  testWidgets('El tema aplica marca, foco y tipografía en claro y oscuro',
      (WidgetTester tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('AirDrop')),
      ));

      final context = tester.element(find.text('AirDrop'));

      // Colores de marca en el colorScheme.
      expect(theme.colorScheme.primary, AppTheme.primary);
      expect(theme.colorScheme.tertiary, AppTheme.tertiary);

      // Ajuste 1: el título del AppBar (titleLarge) usa la tipografía
      // de titulares, no la fuente por defecto de Material.
      expect(theme.textTheme.titleLarge?.fontFamily, isNotNull);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        isNot(theme.textTheme.titleLarge?.fontFamily),
        reason: 'Cuerpo (Inter) y titulares (Jakarta) deben diferir',
      );

      // Ajuste 2: foco visible en el color primario.
      final focused = theme.inputDecorationTheme.focusedBorder;
      expect(focused, isA<OutlineInputBorder>());
      expect((focused as OutlineInputBorder).borderSide.color,
          AppTheme.primary);

      // El fondo del scaffold sale de la paleta del modo.
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(Theme.of(context).colorScheme.surface, isNotNull);
    }
  });
}
