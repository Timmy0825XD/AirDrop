import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/order_format.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/manifest_card.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/theme/app_theme.dart';

/// El manifiesto como lo manda `GET /orders/:id/manifest`.
Map<String, dynamic> _manifestJson() => {
  'id': 'm1',
  'number': 'MAN-2026-000002',
  'orderId': 'o1',
  'issuedAt': '2026-11-15T15:00:00.000Z',
  'drone': {'id': 'd1', 'identifier': 'AD-NOR-01', 'kind': 'rapid'},
  'origin': {'hubId': 'h1', 'name': 'Nodo Norte (Río Seco)'},
  'destination': 'Puesto de salud de Badillo',
  'items': [
    {
      'medicationName': 'Acetaminofén 500 mg',
      'lot': 'ACE-N-2601',
      'expiresOn': '2028-01-08',
      'quantity': 1,
    },
  ],
  'payloadKg': 0.03,
  'coldCompartmentKg': null,
  'coldRange': null,
  'authorizedBy': {'userId': null, 'name': 'Despachador automático'},
  'voidedAt': null,
  'voidReason': null,
  'previous': [
    {
      'number': 'MAN-2026-000001',
      'drone': {'identifier': 'AD-NOR-02'},
      'origin': {'name': 'Nodo Norte (Río Seco)'},
      'destination': 'Puesto de salud de Badillo',
      'items': <Object>[],
      'authorizedBy': {'name': 'María Orozco'},
      'voidedAt': '2026-11-15T14:50:00.000Z',
      'voidReason': 'Carga nueva del pedido',
    },
  ],
};

Map<String, dynamic> _tick() => {
  'orderId': 'o1',
  'droneId': 'd1',
  'identifier': 'AD-NOR-01',
  'latitude': 10.6,
  'longitude': -73.2,
  'altitudeM': 80,
  'altitudeMslM': 325,
  'speedKmh': 120,
  'phase': 'cruise',
  'status': 'in_flight',
  'remoteId': {
    'registration': 'AD-NOR-01',
    'operator': 'AirDrop',
    'type': 'Colibrí',
    'manifestNumber': 'MAN-2026-000002',
    'status': 'link_lost',
  },
};

Order _order(String? manifestNumber) => Order(
  id: 'o1',
  missionType: MissionType.emergency,
  destinationKind: DestinationKind.person,
  status: OrderStatus.pendingLoad,
  priority: OrderPriority.high,
  medicationName: 'Acetaminofén 500 mg',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  address: 'Puesto de salud de Badillo, Valledupar',
  hasPrescription: false,
  createdByUserId: 'u1',
  manifestNumber: manifestNumber,
);

void main() {
  test('lee el manifiesto con sus ítems y los anulados', () {
    final manifest = CargoManifest.fromJson(_manifestJson());

    expect(manifest.number, 'MAN-2026-000002');
    expect(manifest.droneIdentifier, 'AD-NOR-01');
    expect(manifest.originName, 'Nodo Norte (Río Seco)');
    expect(manifest.items.single.lot, 'ACE-N-2601');
    expect(manifest.payloadKg, 0.03);
    expect(manifest.authorizedBy, 'Despachador automático');
    expect(manifest.previous.single.voidReason, 'Carga nueva del pedido');
    expect(manifestWeight(0.03), '0,03 kg');
    expect(manifestWeight(1.25), '1,3 kg');
  });

  test('confirmar la carga avisa el número del manifiesto', () {
    expect(
      loadConfirmedMessage(_order('MAN-2026-000002')),
      'Carga confirmada. Manifiesto MAN-2026-000002.',
    );
    expect(
      loadConfirmedMessage(_order(null)),
      'Carga confirmada. El vuelo arranca en segundos.',
    );
  });

  test('la telemetría trae la identificación remota y la altura s. n. m.', () {
    final t = Telemetry.fromJson(_tick());

    expect(t.altitudeMslM, 325);
    expect(t.remoteId!.status, RemoteIdStatus.linkLost);
    // Sin enlace aunque `linkLost` no venga: lo dice la identificación.
    expect(t.offLink, isTrue);
    expect(t.remoteId!.label(withManifest: true), contains('MAN-2026-000002'));
    // Quien pidió ve la matrícula y el tipo, no el manifiesto.
    expect(t.remoteId!.label(withManifest: false), 'AD-NOR-01 · Colibrí');

    // Una lectura vieja de Redis no trae nada de esto.
    final old = Telemetry.fromJson(
      {..._tick()}
        ..remove('remoteId')
        ..remove('altitudeMslM'),
    );
    expect(old.remoteId, isNull);
    expect(old.altitudeMslM, isNull);
    expect(old.offLink, isFalse);
  });

  testWidgets('la tarjeta del manifiesto dice qué va y a quién reemplaza', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManifestCard(
              manifest: CargoManifest.fromJson(_manifestJson()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manifiesto MAN-2026-000002'), findsOneWidget);
    expect(find.text('Nodo Norte (Río Seco)'), findsOneWidget);
    expect(find.textContaining('lote ACE-N-2601'), findsOneWidget);
    expect(find.text('0,03 kg'), findsOneWidget);
    expect(find.text('Despachador automático'), findsOneWidget);
    expect(
      find.text(
        'Reemplaza a MAN-2026-000001 (anulado: Carga nueva del pedido)',
      ),
      findsOneWidget,
    );
  });
}
