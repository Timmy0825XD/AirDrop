import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/theme/app_palette.dart';
import 'package:frontend/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('El contraste cumple WCAG: texto 4,5:1 y bordes de control 3:1', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final c = theme.colorScheme;
      final backdrop = theme.extension<AppPalette>()!.backdrop.first;
      final fieldFill = theme.brightness == Brightness.dark
          ? c.surfaceContainerHighest
          : c.surface;
      for (final ground in [c.surface, backdrop]) {
        expect(_contrast(c.onSurface, ground), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(c.onSurfaceVariant, ground),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(c.primary, ground), greaterThanOrEqualTo(4.5));
        expect(_contrast(c.outline, ground), greaterThanOrEqualTo(3));
      }
      expect(_contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.outline, fieldFill), greaterThanOrEqualTo(3));
    }
  });

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
