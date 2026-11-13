import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/form_sheet_card.dart';
import 'package:frontend/core/widgets/auth_field.dart';
import 'package:frontend/core/widgets/auth_picker_field.dart';
import 'package:frontend/core/widgets/search_picker_sheet.dart';

void main() {
  testWidgets('el lector de pantalla lee la etiqueta en el campo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthField(
            label: 'Correo electrónico',
            hint: 'Ej.: nombre@correo.com',
            controller: controller,
            errorText: 'Escribe tu correo.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El campo de texto lleva la etiqueta, no solo el placeholder.
    final field = tester.getSemantics(find.byType(TextField));
    expect(field.label, contains('Correo electrónico'));
    expect(field.flagsCollection.isTextField, isTrue);
    // La etiqueta visible no se lee dos veces: solo el campo la lleva.
    expect(
      find.bySemanticsLabel(RegExp('^Correo electrónico')),
      findsOneWidget,
    );
    // El error se anuncia solo (región viva).
    expect(
      tester
          .getSemantics(find.text('Escribe tu correo.'))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('en una tarjeta de formulario cada campo es un nodo propio', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final quantity = TextEditingController();
    final note = TextEditingController();
    addTearDown(quantity.dispose);
    addTearDown(note.dispose);
    // Lo mismo que "Urgencia a otra central": central, cantidad y nota.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormSheetCard(
            children: [
              AuthPickerField<String>(
                label: 'Central de origen',
                hint: 'Elige la central',
                options: const [PickerOption(value: 'h1', title: 'Rosario')],
                isSelected: (_) => false,
                onSelected: (_) {},
              ),
              AuthField(
                label: 'Cantidad',
                hint: 'Ej.: 1',
                controller: quantity,
              ),
              AuthField(label: 'Nota', hint: 'Opcional', controller: note),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('^Central de origen: Elige la central')),
      findsOneWidget,
    );
    final fields = find.byType(TextField);
    expect(tester.getSemantics(fields.first).label, contains('Cantidad'));
    expect(tester.getSemantics(fields.last).label, contains('Nota'));
    expect(tester.getSemantics(fields.first).label, isNot(contains('Nota')));
    handle.dispose();
  });

  testWidgets('al fallar, el formulario baja hasta el campo con error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Widget form({String? error, int shake = 0}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 1500),
              AuthField(
                label: 'Motivo',
                hint: 'Ej.: Cambio de hélices',
                controller: controller,
                errorText: error,
                shakeCount: shake,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(form());
    expect(tester.getTopLeft(find.byType(TextField)).dy, greaterThan(640));

    await tester.pumpWidget(form(error: 'Escribe el motivo.', shake: 1));
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(TextField)).dy;
    expect(top, inInclusiveRange(0, 640));
  });
}
