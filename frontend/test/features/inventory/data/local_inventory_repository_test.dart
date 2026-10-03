import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_repository.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/data/local_inventory_repository.dart';

class _FakeHubRepository implements HubRepository {
  _FakeHubRepository(this.hub);

  Hub? hub;

  @override
  Future<Hub?> mine() async => hub;

  @override
  Future<List<Hub>> list({HubStatus? status}) async =>
      hub == null ? const [] : [hub!];

  @override
  Future<Hub> create(CreateHubRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Hub> setSuspension(String id, {required bool suspended}) async =>
      throw UnimplementedError();
}

Hub _hub({HubStatus status = HubStatus.active}) => Hub(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Central Demo',
  type: HubType.hospital,
  address: 'Calle 15 # 12-45, Valledupar',
  latitude: 10.463140,
  longitude: -73.253220,
  contactPhone: '3001234567',
  status: status,
);

/// Los mensajes y códigos son los de `InventoryService` y
/// `HubsService.requireActive` en Nest.
void main() {
  test('sin central asignada responde 403 con el mensaje de Nest', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(null),
    );

    await expectLater(
      repo.list(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having(
              (e) => e.message,
              'message',
              'Debes tener una central asignada para gestionar inventario.',
            ),
      ),
    );
  });

  test('central suspendida bloquea el inventario con 403', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(_hub(status: HubStatus.suspended)),
    );

    await expectLater(
      repo.list(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.message, 'message', 'La central está suspendida.'),
      ),
    );
  });

  test('lista los ítems de la maqueta con tipo de venta y frío', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(_hub()),
    );

    final rows = await repo.list();

    expect(rows, hasLength(3));
    expect(
      rows.map((item) => item.name),
      contains('Insulina glargina 100 UI/mL'),
    );
    final insulin = rows.firstWhere((item) => item.requiresColdChain);
    expect(insulin.saleType, SaleType.prescription);
    expect(insulin.hubId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
  });

  test('PATCH sin cambios responde 400 y no toca el ítem', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(_hub()),
    );

    await expectLater(
      repo.update(
        'e1111111-1111-4111-8111-111111111111',
        const UpdateInventoryItemRequest(),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              'Debes enviar al menos un campo para actualizar.',
            ),
      ),
    );
  });

  test('editar o borrar un ítem ajeno responde 404', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(_hub()),
    );

    await expectLater(
      repo.update(
        'e9999999-9999-4999-8999-999999999999',
        const UpdateInventoryItemRequest(quantity: 5),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having(
              (e) => e.message,
              'message',
              'El ítem de inventario no existe.',
            ),
      ),
    );
    await expectLater(
      repo.remove('e9999999-9999-4999-8999-999999999999'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('crear, editar y borrar un ítem', () async {
    final repo = LocalInventoryRepository(
      hubRepository: _FakeHubRepository(_hub()),
    );

    final created = await repo.create(
      const CreateInventoryItemRequest(
        name: 'Suero oral',
        quantity: 50,
        lot: 'suo-2026',
        expirationDate: '2027-03-31',
        requiresColdChain: false,
        saleType: SaleType.overTheCounter,
      ),
    );
    expect(
      created.lot,
      'SUO-2026',
      reason: 'el lote sube en mayúsculas, como el DTO',
    );
    expect(created.hubId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    expect(await repo.list(), hasLength(4));

    final updated = await repo.update(
      created.id,
      const UpdateInventoryItemRequest(quantity: 48),
    );
    expect(updated.quantity, 48);
    expect(
      updated.name,
      'Suero oral',
      reason: 'los campos no tocados se conservan',
    );

    await repo.remove(created.id);
    expect(await repo.list(), hasLength(3));
  });
}
