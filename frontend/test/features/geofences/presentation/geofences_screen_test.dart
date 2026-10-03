import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/geofence_providers.dart';
import 'package:frontend/features/geofences/data/geofence_repository.dart';
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
}

Geofence _geofence({
  String id = 'e1111111-1111-4111-8111-111111111111',
  String name = 'Corredor Aéreo Ambulancia',
  String reason = 'Pasillo aéreo para traslados programados',
}) => Geofence(
  id: id,
  name: name,
  reason: reason,
  polygon: GeoJsonPolygon.fromVertices([
    [-73.26, 10.46],
    [-73.24, 10.46],
    [-73.25, 10.48],
  ]),
);

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
  testWidgets('lista el nombre y el motivo de cada geovalla', (tester) async {
    await _pumpScreen(
      tester,
      _FakeGeofenceRepository([
        _geofence(),
        _geofence(
          id: 'e2222222-2222-4222-8222-222222222222',
          name: 'Zona Restricción Hospital General',
          reason: 'Vertiginoso: sin vuelo a baja altura sobre el hospital',
        ),
      ]),
    );

    expect(find.text('Corredor Aéreo Ambulancia'), findsOneWidget);
    expect(
      find.text('Pasillo aéreo para traslados programados'),
      findsOneWidget,
    );
    expect(find.text('Zona Restricción Hospital General'), findsOneWidget);
    expect(
      find.text('Vertiginoso: sin vuelo a baja altura sobre el hospital'),
      findsOneWidget,
    );
  });

  testWidgets('sin geovallas muestra el estado vacío', (tester) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([]));

    expect(find.text('Aún no hay geovallas registradas.'), findsOneWidget);
  });

  testWidgets('borrar pide confirmación y quita la fila', (tester) async {
    await _pumpScreen(tester, _FakeGeofenceRepository([_geofence()]));

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar geovalla'), findsOneWidget);

    // Cancelar deja todo como estaba.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Corredor Aéreo Ambulancia'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Corredor Aéreo Ambulancia'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Geovalla eliminada.'), findsOneWidget);

    // Deja que el snack se cierre para no dejar timers pendientes.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('el FAB abre el alta y la fila abre la edición', (tester) async {
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

    await tester.tap(find.text('Nueva geovalla'));
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
