import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/choice_pill.dart';
import 'package:frontend/theme/app_palette.dart';

void main() {
  testWidgets(
    'los filtros se activan por teclado y conservan un objetivo táctil de 48 dp',
    (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: Scaffold(
            body: Center(
              child: ChoicePill(
                label: 'Entregados',
                selected: false,
                onTap: () => presses++,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ChoiceChip)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(presses, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(presses, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
