import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/hub_request/hub_request_values.dart';

const _offer = CatalogOffer(
  name: 'Suero oral',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  availableQuantity: 30,
);

void main() {
  test('sin origen pide la central; con origen y sin insumo, el insumo', () {
    final values = HubRequestValues();
    addTearDown(values.dispose);

    expect(values.validate(plan: false), {
      HubRequestInput.origin: 'Elige la central de origen.',
    });

    values.selectOrigin('hub-2');
    expect(values.validate(plan: false), {
      HubRequestInput.offer: 'Elige el medicamento.',
    });
  });

  test('la cantidad no pasa del stock de la central de origen', () {
    final values = HubRequestValues()
      ..selectOrigin('hub-2')
      ..offer = _offer;
    addTearDown(values.dispose);
    values.quantity.text = '31';

    expect(
      values.validate(plan: false)[HubRequestInput.quantity],
      'La cantidad debe ser un entero entre 1 y 30.',
    );

    values.quantity.text = '30';
    expect(values.validate(plan: false), isEmpty);
    expect(values.emergency().quantity, 30);
  });

  test('cambiar de central suelta el insumo elegido', () {
    final values = HubRequestValues()
      ..selectOrigin('hub-2')
      ..offer = _offer;
    addTearDown(values.dispose);

    values.selectOrigin('hub-3');

    expect(values.offer, isNull);
  });

  test('el abastecimiento manda la fecha elegida, no siempre hoy', () {
    final values = HubRequestValues()
      ..selectOrigin('hub-2')
      ..offer = _offer
      ..frequency = PlanFrequency.monthly
      ..startDate = '2099-01-15';
    addTearDown(values.dispose);

    expect(values.validate(plan: true), isEmpty);
    expect(values.plan().startDate, '2099-01-15');

    values.startDate = '2000-01-01';
    expect(
      values.validate(plan: true)[HubRequestInput.startDate],
      'La fecha de inicio no puede ser anterior a hoy.',
    );
  });
}
