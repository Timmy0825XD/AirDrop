import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/status_pill.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/presentation/inventory_form_screen.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_form_values.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_tile.dart';

InventoryItem _item(String expiration) => InventoryItem(
  id: 'e1111111-1111-4111-8111-111111111111',
  hubId: 'hub-1',
  name: 'Acetaminofén 500 mg',
  quantity: 240,
  lot: 'ACT-500-26',
  expirationDate: expiration,
  requiresColdChain: false,
  saleType: SaleType.overTheCounter,
);

void main() {
  testWidgets('el interruptor de cadena de frío se mueve al tocarlo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: InventoryFormScreen())),
    );
    await tester.pumpAndSettle();

    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    expect(tester.widget<Switch>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(toggle).value, isTrue);
  });

  test('sin fecha de vencimiento pide elegirla en el calendario', () {
    final values = InventoryFormValues();
    addTearDown(values.dispose);
    values
      ..name.text = 'Suero oral'
      ..lot.text = 'suo-2026'
      ..quantity.text = '5';

    expect(values.validate(), {
      InventoryInput.expirationDate: 'Elige la fecha de vencimiento.',
    });

    values.expirationDate.text = '2027-03-31';
    expect(values.validate(), isEmpty);
  });

  test('marca vencido, por vencer o vigente según la fecha', () {
    final today = DateTime(2026, 10, 16);

    expect(InventoryTile.expiryOf(_item('2026-10-15'), today: today), (
      'Vencido',
      PillTone.negative,
    ));
    expect(InventoryTile.expiryOf(_item('2026-11-10'), today: today), (
      'Por vencer',
      PillTone.attention,
    ));
    expect(InventoryTile.expiryOf(_item('2027-06-30'), today: today), (
      'Vigente',
      PillTone.positive,
    ));
  });
}
