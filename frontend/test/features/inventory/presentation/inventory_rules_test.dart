import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_form_values.dart';

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

InventoryFormValues _filled({required String quantity, required String date}) {
  return InventoryFormValues()
    ..name.text = 'Suero oral'
    ..lot.text = 'SUO-2026'
    ..quantity.text = quantity
    ..expirationDate.text = date;
}

void main() {
  final today = DateTime.now();
  final tomorrow = _iso(today.add(const Duration(days: 1)));

  test('al crear, la cantidad mínima es 1', () {
    final values = _filled(quantity: '0', date: tomorrow);
    addTearDown(values.dispose);
    expect(values.validate(), {
      InventoryInput.quantity: 'La cantidad debe ser mayor que cero.',
    });
  });

  test('al editar se puede dejar en 0 para agotar el ítem', () {
    final values = _filled(quantity: '0', date: '2020-01-01');
    addTearDown(values.dispose);
    final original = InventoryItem.fromJson({
      'id': 'i1',
      'hubId': 'h1',
      'name': 'Suero oral',
      'quantity': 5,
      'lot': 'SUO-2026',
      'expirationDate': '2020-01-01',
      'requiresColdChain': false,
      'saleType': 'over_the_counter',
    });
    // La fecha vieja no cambió: no se exige que sea futura.
    expect(values.validate(original: original), isEmpty);
  });

  test('el vencimiento de hoy o anterior no pasa', () {
    for (final date in [_iso(today), '2020-01-01']) {
      final values = _filled(quantity: '3', date: date);
      addTearDown(values.dispose);
      expect(values.validate(), {
        InventoryInput.expirationDate:
            'La fecha de vencimiento debe ser posterior a hoy.',
      });
    }
    final ok = _filled(quantity: '3', date: tomorrow);
    addTearDown(ok.dispose);
    expect(ok.validate(), isEmpty);
  });
}
