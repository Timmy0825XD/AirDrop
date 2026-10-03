import '../../../../core/api_exception.dart';
import '../../auth/data/local/local_fixtures.dart';
import '../../hubs/data/hub_repository.dart';
import 'inventory_models.dart';
import 'inventory_repository.dart';

/// Inventario simulado en memoria, para trabajar sin NestJS. Cada operación
/// pasa primero por la central del despachador, igual que
/// `InventoryService.requireDispatcherHub` en Nest, y replica sus mensajes
/// y el 400/404 del servicio para que el comportamiento sea el mismo en los
/// dos orígenes de datos.
class LocalInventoryRepository implements InventoryRepository {
  LocalInventoryRepository({required this.hubRepository});

  final HubRepository hubRepository;

  /// Copia por instancia: editar o borrar un ítem no se filtra entre
  /// sesiones de la maqueta. Las [InventoryItem] son inmutables.
  final List<InventoryItem> _items = List.of(_fixtures);

  /// Ítems de partida de la maqueta.
  static final List<InventoryItem> _fixtures = [
    InventoryItem(
      id: 'e1111111-1111-4111-8111-111111111111',
      hubId: localFixtureHubId,
      name: 'Acetaminofén 500 mg',
      quantity: 240,
      lot: 'ACT-500-26',
      expirationDate: '2027-06-30',
      requiresColdChain: false,
      saleType: SaleType.overTheCounter,
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
    InventoryItem(
      id: 'e2222222-2222-4222-8222-222222222222',
      hubId: localFixtureHubId,
      name: 'Insulina glargina 100 UI/mL',
      quantity: 36,
      lot: 'INS-24A',
      expirationDate: '2026-12-31',
      requiresColdChain: true,
      saleType: SaleType.prescription,
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
    InventoryItem(
      id: 'e3333333-3333-4333-8333-333333333333',
      hubId: localFixtureHubId,
      name: 'Solución salina 0.9 %',
      quantity: 120,
      lot: 'SAL-2026-01',
      expirationDate: '2027-01-15',
      requiresColdChain: false,
      saleType: SaleType.prescription,
      createdAt: DateTime.utc(2026, 9, 1, 12),
    ),
  ];

  @override
  Future<List<InventoryItem>> list() async {
    await _requireHub();
    return List<InventoryItem>.unmodifiable(_items);
  }

  @override
  Future<InventoryItem> create(CreateInventoryItemRequest request) async {
    final hub = await _requireHub();
    final item = InventoryItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      hubId: hub.id,
      name: request.name.trim(),
      quantity: request.quantity,
      lot: request.lot.trim().toUpperCase(),
      expirationDate: request.expirationDate,
      requiresColdChain: request.requiresColdChain,
      saleType: request.saleType,
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<InventoryItem> update(
    String id,
    UpdateInventoryItemRequest request,
  ) async {
    if (request.isEmpty) {
      throw const ApiException(
        'Debes enviar al menos un campo para actualizar.',
        statusCode: 400,
      );
    }
    final index = await _ownItemIndex(id);
    final current = _items[index];
    _items[index] = InventoryItem(
      id: current.id,
      hubId: current.hubId,
      name: request.name ?? current.name,
      quantity: request.quantity ?? current.quantity,
      lot: request.lot ?? current.lot,
      expirationDate: request.expirationDate ?? current.expirationDate,
      requiresColdChain: request.requiresColdChain ?? current.requiresColdChain,
      saleType: request.saleType ?? current.saleType,
      createdAt: current.createdAt,
    );
    return _items[index];
  }

  @override
  Future<void> remove(String id) async {
    final index = await _ownItemIndex(id);
    _items.removeAt(index);
  }

  /// Réplica de `requireDispatcherHub`: central asignada y activa antes de
  /// tocar el inventario.
  Future<({String id})> _requireHub() async {
    final hub = await hubRepository.mine();
    if (hub == null) {
      throw const ApiException(
        'Debes tener una central asignada para gestionar inventario.',
        statusCode: 403,
      );
    }
    if (!hub.isActive) {
      throw const ApiException('La central está suspendida.', statusCode: 403);
    }
    return (id: hub.id);
  }

  /// Réplica de `requireOwnItem`: el ítem debe existir y pertenecer a la
  /// central del despachador.
  Future<int> _ownItemIndex(String id) async {
    final hub = await _requireHub();
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].hubId != hub.id) {
      throw const ApiException(
        'El ítem de inventario no existe.',
        statusCode: 404,
      );
    }
    return index;
  }
}
