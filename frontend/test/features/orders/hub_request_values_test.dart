import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/hub_request/hub_request_values.dart';
import 'package:frontend/features/orders/presentation/widgets/plan_schedule/schedule_values.dart';

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

  test('el abastecimiento manda el calendario mensual elegido', () {
    final values = HubRequestValues()
      ..selectOrigin('hub-2')
      ..offer = _offer;
    values.schedule
      ..kind = ScheduleKind.monthly
      ..startDate = '2099-01-15';
    addTearDown(values.dispose);

    expect(
      values.schedule.validate(
        needsPrescription: false,
      )[ScheduleInput.dayOfMonth],
      'Elige el día del mes.',
    );
    values.schedule.dayOfMonth = 15;
    expect(values.validate(plan: true), isEmpty);
    expect(values.schedule.validate(needsPrescription: false), isEmpty);
    final schedule = values.plan().schedule!;
    expect(schedule.toJson(), {
      'kind': 'monthly',
      'startDate': '2099-01-15',
      'count': 4,
      'dayOfMonth': 15,
      'time': '10:00',
    });
  });
}
