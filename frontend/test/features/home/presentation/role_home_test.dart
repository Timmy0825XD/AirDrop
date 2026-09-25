import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/home/presentation/role_home.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/hubs/data/hub_repository.dart';

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

  final HubSummary? hub;

  @override
  Future<HubSummary?> mine() async => hub;
}

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

  testWidgets('deshabilita inventario con central pendiente', (tester) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(
        HubSummary(
          id: 'hub-1',
          name: 'Central de prueba',
          status: HubStatus.pendingApproval,
        ),
      ),
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    final inventoryCard = find.ancestor(
      of: find.text('Inventario'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(inventoryCard).onTap, isNull);
    expect(find.textContaining('Pendiente de aprobación'), findsOneWidget);
  });

  testWidgets('habilita inventario con central aprobada', (tester) async {
    final container = await _authenticatedContainer(
      email: 'despacho@airdrop.local',
      password: 'Despacho123',
      hubRepository: FakeHubRepository(
        const HubSummary(
          id: 'hub-1',
          name: 'Central de prueba',
          status: HubStatus.approved,
        ),
      ),
    );
    addTearDown(container.dispose);

    await _pumpHome(tester, container);

    final inventoryCard = find.ancestor(
      of: find.text('Inventario'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(inventoryCard).onTap, isNotNull);
    expect(find.textContaining('Aprobada'), findsOneWidget);
  });
}

Future<ProviderContainer> _authenticatedContainer({
  required String email,
  required String password,
  HubRepository? hubRepository,
}) async {
  final tokenStore = FakeTokenStore();
  final authRepository = LocalAuthRepository(tokenStore: tokenStore);
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(authRepository),
      if (hubRepository != null)
        hubRepositoryProvider.overrideWithValue(hubRepository),
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
