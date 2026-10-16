import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/dispatcher_permissions.dart';

Order _order({
  OrderStatus status = OrderStatus.received,
  DestinationKind destination = DestinationKind.person,
  SaleType sale = SaleType.overTheCounter,
  String? originHubId,
  String? destinationHubId,
  String? scheduledFor,
  DateTime? loadConfirmedAt,
}) {
  return Order(
    id: 'o1',
    missionType: MissionType.emergency,
    destinationKind: destination,
    status: status,
    priority: OrderPriority.high,
    medicationName: 'Insulina',
    saleType: sale,
    requiresColdChain: false,
    quantity: 1,
    address: 'Calle 16',
    hasPrescription: sale == SaleType.prescription,
    createdByUserId: 'u1',
    originHubId: originHubId,
    destinationHubId: destinationHubId,
    scheduledFor: scheduledFor,
    loadConfirmedAt: loadConfirmedAt,
  );
}

void main() {
  test('en recibido decide; si su central es solo el destino, no', () {
    expect(DispatcherPermissions(order: _order(), myHubId: 'h1').canDecide,
        isTrue);
    final transfer = _order(
      destination: DestinationKind.hub,
      destinationHubId: 'h1',
    );
    expect(
      DispatcherPermissions(order: transfer, myHubId: 'h1').canDecide,
      isFalse,
    );
  });

  test('persona + fórmula exige verificar la fórmula', () {
    final order = _order(sale: SaleType.prescription);
    final can = DispatcherPermissions(order: order, myHubId: 'h1');
    expect(can.needsPrescriptionCheck, isTrue);
    expect(can.canViewPrescription, isTrue);
  });

  test('confirma la carga solo la central de origen y una vez', () {
    final pending = _order(status: OrderStatus.pendingLoad, originHubId: 'h1');
    expect(
      DispatcherPermissions(order: pending, myHubId: 'h1').canConfirmLoad,
      isTrue,
    );
    expect(
      DispatcherPermissions(order: pending, myHubId: 'h2').canConfirmLoad,
      isFalse,
    );
    final loaded = _order(
      status: OrderStatus.pendingLoad,
      originHubId: 'h1',
      loadConfirmedAt: DateTime.utc(2026),
    );
    expect(
      DispatcherPermissions(order: loaded, myHubId: 'h1').canConfirmLoad,
      isFalse,
    );
  });

  test('un programado con fecha futura todavía no se autoriza', () {
    final later = _order(scheduledFor: '2999-01-01');
    expect(DispatcherPermissions(order: later, myHubId: 'h1').notYet, isTrue);
    final past = _order(scheduledFor: '2000-01-01');
    expect(DispatcherPermissions(order: past, myHubId: 'h1').notYet, isFalse);
  });

  test('hay vuelo desde que se confirma la carga hasta el destino', () {
    expect(_order(status: OrderStatus.pendingLoad).hasFlight, isFalse);
    final loaded = _order(
      status: OrderStatus.pendingLoad,
      loadConfirmedAt: DateTime.utc(2026),
    );
    expect(loaded.hasFlight, isTrue);
    expect(_order(status: OrderStatus.inFlight).hasFlight, isTrue);
    expect(_order(status: OrderStatus.awaitingDelivery).hasFlight, isTrue);
  });

  test('solo la central de origen ve el vuelo', () {
    final flying = _order(status: OrderStatus.inFlight, originHubId: 'h1');
    expect(
      DispatcherPermissions(order: flying, myHubId: 'h1').canWatchFlight,
      isTrue,
    );
    expect(
      DispatcherPermissions(order: flying, myHubId: 'h2').canWatchFlight,
      isFalse,
    );
  });
}
