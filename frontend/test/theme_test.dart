import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/theme/app_palette.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  testWidgets(
    'El tema aplica marca, paleta, foco y tipografía en claro y oscuro',
    (WidgetTester tester) async {
      // En oscuro el turquesa se aclara para contrastar sobre el grafito.
      final brandByMode = {
        AppTheme.light: (AppTheme.primary, AppPalette.light),
        AppTheme.dark: (AppTheme.primaryOnDark, AppPalette.dark),
      };
      for (final MapEntry(key: theme, value: (brand, palette))
          in brandByMode.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: Text('AirDrop')),
          ),
        );

        final context = tester.element(find.text('AirDrop'));

        // Marca y semáforo salen de la paleta del modo.
        expect(theme.colorScheme.primary, brand);
        expect(theme.colorScheme.secondary, palette.warning);
        expect(theme.colorScheme.tertiary, palette.success);
        expect(theme.colorScheme.error, palette.danger);
        expect(theme.extension<AppPalette>(), palette);

        // Una sola familia en titulares y cuerpo.
        expect(theme.textTheme.titleLarge?.fontFamily, isNotNull);
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          theme.textTheme.titleLarge?.fontFamily,
        );

        // Foco visible en el color de marca.
        final focused = theme.inputDecorationTheme.focusedBorder;
        expect(focused, isA<OutlineInputBorder>());
        expect((focused as OutlineInputBorder).borderSide.color, brand);

        // El scaffold es transparente: el fondo lo pinta AppBackdrop.
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(Theme.of(context).colorScheme.surface, isNotNull);
      }
    },
  );
}
