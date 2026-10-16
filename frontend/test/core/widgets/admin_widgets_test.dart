import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/confirm_sheet.dart';
import 'package:frontend/core/widgets/sliding_segmented.dart';

void main() {
  testWidgets('el filtro avisa la opción tocada', (tester) async {
    String? picked = 'todas';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SlidingSegmented<String?>(
              options: const [
                SegmentOption('todas', 'Todas'),
                SegmentOption('activas', 'Activas'),
              ],
              selected: picked,
              onChanged: (value) => setState(() => picked = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Activas'));
    await tester.pumpAndSettle();

    expect(picked, 'activas');
  });

  testWidgets('la hoja devuelve true solo al confirmar', (tester) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answers.add(
              await showConfirmSheet(
                context,
                title: '¿Suspender Farmacia Centro?',
                message: 'Su inventario queda bloqueado.',
                confirmLabel: 'Suspender',
                icon: Icons.pause_circle_outline_rounded,
                subject: const Text('Farmacia Centro'),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Suspender Farmacia Centro?'), findsOneWidget);
    await tester.tap(find.text('Suspender'));
    await tester.pumpAndSettle();

    expect(answers, [false, true]);
  });
}
