import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/app/router.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/data/fleet_providers.dart';
import 'package:frontend/features/fleet/data/fleet_repository.dart';
import 'package:frontend/features/fleet/presentation/fleet_screen.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/geofence_providers.dart';
import 'package:frontend/features/geofences/data/geofence_repository.dart';
import 'package:frontend/features/geofences/presentation/geofences_screen.dart';
import 'package:frontend/features/home/presentation/role_home.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/hubs/data/hub_repository.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/data/inventory_providers.dart';
import 'package:frontend/features/inventory/data/inventory_repository.dart';
import 'package:frontend/features/inventory/presentation/inventory_screen.dart';

class FakeTokenStore extends TokenStore {
  FakeTokenStore() : super();

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

class FakeHubRepository implements HubRepository {
  FakeHubRepository(this.hub);

  final Hub? hub;

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

Hub _hub({required HubStatus status}) => Hub(
  id: 'hub-1',
  name: 'Central de prueba',
  type: HubType.hospital,
  address: 'Calle 15 # 12-45, Valledupar',
  latitude: 10.463140,
  longitude: -73.253220,
  contactPhone: '3001234567',
  status: status,
);

Geofence _geofence() => Geofence(
  id: 'e1111111-1111-4111-8111-111111111111',
  name: 'Corredor Aéreo Ambulancia',
  reason: 'Pasillo aéreo para traslados programados',
  polygon: GeoJsonPolygon.fromVertices([
    [-73.26, 10.46],
    [-73.24, 10.46],
    [-73.25, 10.48],
  ]),
);

class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository(this.items);

  final List<InventoryItem> items;

  @override
  Future<List<InventoryItem>> list() async => items;

  @override
  Future<InventoryItem> create(CreateInventoryItemRequest request) async =>
      throw UnimplementedError();

  @override
  Future<InventoryItem> update(
    String id,
    UpdateInventoryItemRequest request,
  ) async => throw UnimplementedError();

  @override
  Future<void> remove(String id) async => throw UnimplementedError();
}

/// Una sola geovalla, para que el listado tenga algo que mostrar sin
/// depender del origen de datos real.
class FakeGeofenceRepository implements GeofenceRepository {
  const FakeGeofenceRepository(this.rows);

  final List<Geofence> rows;

  @override
  Future<List<Geofence>> list() async => rows;

  @override
  Future<Geofence> create(CreateGeofenceRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> remove(String id) async => throw UnimplementedError();
}

/// La flota de la maqueta: un solo dron disponible, para que la pantalla
/// de flota tenga algo que listar sin depender del origen de datos real.
class FakeFleetRepository implements FleetRepository {
  const FakeFleetRepository();

  @override
  Future<List<DroneModel>> listModels() async => const [
    DroneModel(
      id: 'm1',
      code: 'wingcopter_198',
      name: 'Wingcopter 198',
      maxSpeedKmh: 150,
      maxPayloadKg: 6,
      maxRangeKm: 110,
    ),
  ];

  @override
  Future<List<Drone>> listDrones(String hubId) async => [
    const Drone(
      id: 'd1',
      identifier: 'DRON-01',
      droneModelId: 'm1',
      hubId: 'hub-1',
      status: DroneStatus.available,
    ),
  ];

  @override
  Future<Drone> create(CreateDroneRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Drone> updateStatus(
    String id,
    UpdateDroneStatusRequest request,
  ) async => throw UnimplementedError();

  @override
  Future<Drone> registerMaintenance(
    String id,
    RegisterMaintenanceRequest request,
  ) async => throw UnimplementedError();
}

const InventoryItem _inventoryItem = InventoryItem(
  id: 'e1111111-1111-4111-8111-111111111111',
  hubId: 'hub-1',
  name: 'Acetaminofén 500 mg',
  quantity: 240,
  lot: 'ACT-500-26',
  expirationDate: '2027-06-30',
  requiresColdChain: true,
  saleType: SaleType.overTheCounter,
);

void main() {
  testWidgets('muestra el home del solicitante sin inventar pedidos', (
    tester,
  ) async {
    final container = await _authenticatedContainer(
      email: 'demo@airdrop.local',
      password: 'Demo1234',
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Pedidos aún no disponibles'), findsOneWidget);
    expect(find.text('Crear pedido'), findsNothing);
  });

  testWidgets('muestra los accesos de operador de flota', (tester) async {
    final container = await _authenticatedContainer(
      email: 'operador@airdrop.local',
      password: 'Operador123',
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    expect(find.text('Flota'), findsOneWidget);
    expect(find.text('Geovallas'), findsOneWidget);
  });

  testWidgets('muestra los accesos de administrador', (tester) async {
    final container = await _authenticatedContainer(
      email: 'admin@airdrop.local',
      password: 'Admin1234',
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    expect(find.text('Centrales'), findsOneWidget);
    expect(find.text('Cuentas institucionales'), findsOneWidget);
  });

  testWidgets('deshabilita inventario con central suspendida', (tester) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(_hub(status: HubStatus.suspended)),
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    final inventoryCard = find.ancestor(
      of: find.text('Inventario'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(inventoryCard).onTap, isNull);
    expect(find.textContaining('La central está suspendida.'), findsOneWidget);
    expect(find.textContaining('Suspendida'), findsOneWidget);
  });

  testWidgets('habilita inventario con central activa', (tester) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(_hub(status: HubStatus.active)),
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    final inventoryCard = find.ancestor(
      of: find.text('Inventario'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(inventoryCard).onTap, isNotNull);
    expect(find.textContaining('Activa'), findsOneWidget);
  });

  testWidgets('sin central asignada muestra el mensaje de Nest', (
    tester,
  ) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(null),
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    expect(
      find.textContaining('No tienes una central asignada.'),
      findsOneWidget,
    );
  });

  testWidgets('la tarjeta de flota navega al listado de drones', (
    tester,
  ) async {
    final container = await _authenticatedContainer(
      email: 'operador@airdrop.local',
      password: 'Operador123',
      hubRepository: FakeHubRepository(_hub(status: HubStatus.active)),
      fleetRepository: FakeFleetRepository(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FleetScreen), findsNothing);

    await tester.tap(find.text('Flota'));
    await tester.pumpAndSettle();

    expect(find.byType(FleetScreen), findsOneWidget);
    expect(find.text('DRON-01'), findsOneWidget);
    expect(find.text('Central de prueba'), findsOneWidget);
    expect(find.text('Wingcopter 198'), findsWidgets);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('la tarjeta de inventario navega al listado', (tester) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(_hub(status: HubStatus.active)),
      inventoryRepository: FakeInventoryRepository([_inventoryItem]),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InventoryScreen), findsNothing);

    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryScreen), findsOneWidget);
    expect(find.text('Acetaminofén 500 mg'), findsOneWidget);
    expect(find.textContaining('Lote ACT-500-26 · 240 und.'), findsOneWidget);
    expect(find.textContaining('Cadena de frío'), findsOneWidget);
  });

  testWidgets('la tarjeta de geovallas navega al listado', (tester) async {
    final container = await _authenticatedContainer(
      email: 'operador@airdrop.local',
      password: 'Operador123',
      hubRepository: FakeHubRepository(_hub(status: HubStatus.active)),
      geofenceRepository: FakeGeofenceRepository([_geofence()]),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GeofencesScreen), findsNothing);

    await tester.tap(find.text('Geovallas'));
    await tester.pumpAndSettle();

    expect(find.byType(GeofencesScreen), findsOneWidget);
    expect(find.text('Corredor Aéreo Ambulancia'), findsOneWidget);
    expect(
      find.text('Pasillo aéreo para traslados programados'),
      findsOneWidget,
    );
  });
}

Future<ProviderContainer> _authenticatedContainer({
  required String email,
  required String password,
  HubRepository? hubRepository,
  InventoryRepository? inventoryRepository,
  FleetRepository? fleetRepository,
  GeofenceRepository? geofenceRepository,
}) async {
  final tokenStore = FakeTokenStore();
  final authRepository = LocalAuthRepository(tokenStore: tokenStore);
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(authRepository),
      if (hubRepository != null)
        hubRepositoryProvider.overrideWithValue(hubRepository),
      if (inventoryRepository != null)
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
      if (fleetRepository != null)
        fleetRepositoryProvider.overrideWithValue(fleetRepository),
      if (geofenceRepository != null)
        geofenceRepositoryProvider.overrideWithValue(geofenceRepository),
    ],
  );

  await container.read(authControllerProvider.future);
  await container
      .read(authControllerProvider.notifier)
      .login(
        LoginRequest(contact: AuthContact.email(email), password: password),
      );
  return container;
}

Future<void> _pumpHome(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RoleHomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
