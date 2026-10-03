import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_form_values.dart';

InventoryItem _item() => const InventoryItem(
  id: 'e1111111-1111-4111-8111-111111111111',
  hubId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Acetaminofén 500 mg',
  quantity: 240,
  lot: 'ACT-500-26',
  expirationDate: '2027-06-30',
  requiresColdChain: false,
  saleType: SaleType.overTheCounter,
);

void main() {
  group('request (POST /inventory)', () {
    test('arma el body con el lote en mayúsculas y la cantidad entera', () {
      final values = InventoryFormValues();
      addTearDown(values.dispose);
      values
        ..name.text = '  Suero oral  '
        ..quantity.text = ' 50 '
        ..lot.text = ' suo-2026 '
        ..expirationDate.text = ' 2027-03-31 '
        ..saleType = SaleType.prescription
        ..requiresColdChain = true;

      final body = values.request();

      expect(body.toJson(), {
        'name': 'Suero oral',
        'quantity': 50,
        'lot': 'SUO-2026',
        'expirationDate': '2027-03-31',
        'requiresColdChain': true,
        'saleType': 'prescription',
      });
      expect(body.toJson(), isNot(contains('hubId')));
    });
  });

  group('diff (PATCH /inventory/:id)', () {
    test('sin cambios queda vacío: la pantalla no envía el PATCH', () {
      final values = InventoryFormValues()..load(_item());

      final request = values.diff(_item());

      expect(request.isEmpty, isTrue);
      expect(request.toJson(), isEmpty);
    });

    test('solo incluye los campos que cambiaron', () {
      final values = InventoryFormValues()..load(_item());
      values.quantity.text = '200';

      final request = values.diff(_item());

      expect(request.isEmpty, isFalse);
      expect(request.toJson(), {'quantity': 200});
    });

    test('un cambio de mayúsculas en el lote no cuenta como cambio', () {
      final values = InventoryFormValues()..load(_item());
      values.lot.text = 'act-500-26';

      expect(values.diff(_item()).isEmpty, isTrue);
    });
  });

  test('load rellena el formulario desde el ítem', () {
    final values = InventoryFormValues();
    addTearDown(values.dispose);

    values.load(_item());

    expect(values.name.text, 'Acetaminofén 500 mg');
    expect(values.quantity.text, '240');
    expect(values.lot.text, 'ACT-500-26');
    expect(values.expirationDate.text, '2027-06-30');
    expect(values.saleType, SaleType.overTheCounter);
    expect(values.requiresColdChain, isFalse);
  });
}
