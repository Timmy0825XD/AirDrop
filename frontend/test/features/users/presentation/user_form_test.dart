import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/users/presentation/widgets/user_form/hub_picker.dart';
import 'package:frontend/features/users/presentation/widgets/user_form_values.dart';

void main() {
  group('UserFormValues', () {
    test('el despachador cambia de central; el operador suma y quita', () {
      final values = UserFormValues();
      addTearDown(values.dispose);

      values
        ..toggleHub('h1')
        ..toggleHub('h2');
      expect(values.hubIds, ['h2']);

      values
        ..selectRole(UserRole.fleetOperator)
        ..toggleHub('h1');
      expect(values.hubIds, ['h2', 'h1']);
      values.toggleHub('h2');
      expect(values.hubIds, ['h1']);
    });

    test('volver a despachador deja una sola central', () {
      final values = UserFormValues()
        ..selectRole(UserRole.fleetOperator)
        ..toggleHub('h1')
        ..toggleHub('h2');
      addTearDown(values.dispose);

      values.selectRole(UserRole.dispatcher);

      expect(values.hubIds, ['h1']);
    });

    test('valida los campos, el celular es opcional', () {
      final values = UserFormValues();
      addTearDown(values.dispose);

      expect(
        values.validate().keys,
        containsAll([
          UserInput.name,
          UserInput.email,
          UserInput.password,
          UserInput.hubs,
        ]),
      );

      values
        ..name.text = 'Camila Gutiérrez'
        ..email.text = 'CGutierrez@Central.co'
        ..password.text = 'Valledupar2026'
        ..toggleHub('h1');
      expect(values.validate(), isEmpty);
      expect(values.request().email, 'cgutierrez@central.co');
      expect(values.request().phone, isNull);
    });
  });

  testWidgets('sin centrales activas lo dice y ofrece crear una', (
    tester,
  ) async {
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HubPicker(
            role: UserRole.dispatcher,
            hubs: const [],
            selectedIds: const [],
            onToggle: (_) {},
            onCreateHub: () => created = true,
          ),
        ),
      ),
    );

    expect(
      find.text('No hay centrales activas. Crea una antes de crear cuentas.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Crear central'));
    expect(created, isTrue);
  });
}
