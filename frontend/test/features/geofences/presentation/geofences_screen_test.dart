import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/geofence_providers.dart';
import 'package:frontend/features/geofences/data/geofence_repository.dart';
import 'package:frontend/features/geofences/data/local_geofence_repository.dart';
import 'package:frontend/features/geofences/presentation/geofences_screen.dart';
import 'package:go_router/go_router.dart';

/// Lista en memoria que sí se borra, para recorrer el flujo completo de
/// la pantalla sin depender del origen de datos real.
class _FakeGeofenceRepository implements GeofenceRepository {
  _FakeGeofenceRepository(this.rows);

  final List<Geofence> rows;

  @override
  Future<List<Geofence>> list() async => List<Geofence>.unmodifiable(rows);

  @override
  Future<Geofence> create(CreateGeofenceRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Geofence> update(String id, UpdateGeofenceRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> remove(String id) async {
    rows.removeWhere((row) => row.id == id);
  }

  @override
  Future<List<GeofenceChange>> changes(String id) async => const [];

  @override
  Future<Geofence> createLegal(CreateLegalZoneRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Geofence> updateLegal(
    String id,
    UpdateLegalZoneRequest request,
  ) async => throw UnimplementedError();

  @override
  Future<Geofence> setLegalActive(
    String id, {
    required bool active,
    required String reason,
  }) async => throw UnimplementedError();
}

Geofence _geofence({
  String id = 'e1111111-1111-4111-8111-111111111111',
  String name = 'Corredor Aéreo Ambulancia',
  String reason = 'Pasillo aéreo para traslados programados',
}) => Geofence(
  id: id,
  geofenceClass: GeofenceClass.operational,
  shape: GeofenceShape.polygon,
  name: name,
  reason: reason,
  category: OperationalCategory.other,
  polygon: const GeoJsonPolygon([
    [
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.25, 10.48],
      [-73.26, 10.46],
    ],
  ]),
);

/// La zona legal de la maqueta: CAI Gobernación.
Geofence get _legal => localGeofenceFixtures.last;

Future<void> _pumpScreen(
  WidgetTester tester,
  GeofenceRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [geofenceRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GeofencesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista cada geovalla con su clase y su forma', (tester) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([_geofence(), _legal]));

    expect(find.text('Corredor Aéreo Ambulancia'), findsOneWidget);
    expect(find.text('Operativa · Polígono de 3 vértices'), findsOneWidget);
    expect(find.text('Prohibida · Círculo de 100 m'), findsOneWidget);
    expect(find.text('Zona legal · Activa'), findsOneWidget);
  });

  testWidgets('el filtro deja solo las legales', (tester) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([_geofence(), _legal]));

    await tester.tap(find.text('Legales'));
    await tester.pumpAndSettle();
    expect(find.text('Corredor Aéreo Ambulancia'), findsNothing);
    expect(find.text('CAI Gobernación'), findsOneWidget);
  });

  testWidgets('el operador abre la ficha de una zona legal sin acciones', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([_legal]));

    await tester.tap(find.text('CAI Gobernación'));
    await tester.pumpAndSettle();
    expect(find.textContaining('RAC 100.315(a)'), findsWidgets);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Desactivar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('borrar pide confirmación y quita la fila', (tester) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([_geofence()]));

    // "Eliminar" vive en el menú ⋮ de la fila.
    await tester.tap(find.byTooltip('Más acciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar geovalla'), findsOneWidget);

    // Cancelar deja todo como estaba.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Corredor Aéreo Ambulancia'), findsOneWidget);

    // "Eliminar" vive en el menú ⋮ de la fila.
    await tester.tap(find.byTooltip('Más acciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Corredor Aéreo Ambulancia'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Geovalla eliminada.'), findsOneWidget);

    // Deja que el snack se cierre para no dejar timers pendientes.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('el + del encabezado abre el alta y la fila abre la edición', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        geofenceRepositoryProvider.overrideWithValue(
          _FakeGeofenceRepository([_geofence()]),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Rutas mínimas con los mismos caminos que `router.dart`, para ver
    // a dónde navega la pantalla sin levantar la app completa.
    final router = GoRouter(
      initialLocation: '/geofences',
      routes: [
        GoRoute(path: '/geofences', builder: (_, _) => const GeofencesScreen()),
        GoRoute(path: '/geofences/new', builder: (_, _) => const Text('alta')),
        GoRoute(
          path: '/geofences/:id',
          builder: (_, state) => Text('edición ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nueva geovalla'));
    await tester.pumpAndSettle();
    expect(find.text('alta'), findsOneWidget);

    router.go('/geofences');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corredor Aéreo Ambulancia'));
    await tester.pumpAndSettle();
    expect(
      find.text('edición e1111111-1111-4111-8111-111111111111'),
      findsOneWidget,
    );
  });
}
