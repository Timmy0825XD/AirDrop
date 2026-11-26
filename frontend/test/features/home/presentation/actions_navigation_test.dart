import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/presentation/widgets/geofence_tile.dart';
import 'package:frontend/features/home/presentation/widgets/home_header.dart';

Geofence _fence({DateTime? expiresAt}) => Geofence(
  id: 'e1111111-1111-4111-8111-111111111111',
  geofenceClass: GeofenceClass.operational,
  shape: GeofenceShape.polygon,
  name: 'Incendio en el norte',
  reason: 'Humo sobre la ruta',
  category: OperationalCategory.groundRisk,
  polygon: const GeoJsonPolygon([
    [
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.25, 10.48],
      [-73.26, 10.46],
    ],
  ]),
  expiresAt: expiresAt,
);

void main() {
  testWidgets('las iniciales abren el perfil y no hay "Cerrar sesión"', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            roleLabel: 'Solicitante',
            fullName: 'Ana María Pérez',
            tagline: 'Medicamentos por dron',
            onProfile: () => opened++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byTooltip('Cerrar sesión'), findsNothing);
    expect(find.bySemanticsLabel('Mi perfil'), findsOneWidget);
    await tester.tap(find.text('AM'));
    expect(opened, 1);
  });

  testWidgets('una operativa con vigencia dice cuándo vence', (tester) async {
    Future<void> pump(Geofence fence, {VoidCallback? onDelete}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GeofenceTile(
                geofence: fence,
                onTap: () {},
                onDelete: onDelete,
              ),
            ),
          ),
        );

    // 20:30 UTC son las 3:30 p. m. en Colombia.
    await pump(_fence(expiresAt: DateTime.utc(2026, 11, 8, 20, 30)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('· 3:30 p. m.'), findsOneWidget);
    expect(find.byTooltip('Más acciones'), findsNothing);

    await pump(_fence(), onDelete: () {});
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Operativa · Activa'), findsOneWidget);
    expect(find.text('Operativa · Polígono de 3 vértices'), findsOneWidget);
    expect(find.byTooltip('Más acciones'), findsOneWidget);
  });

  test('la clase dice si es temporal, no el vencimiento', () {
    final fence = Geofence.fromJson({
      'id': 'e1111111-1111-4111-8111-111111111111',
      'class': 'temporary',
      'shape': 'polygon',
      'name': 'Incendio',
      'reason': 'Humo',
      'polygon': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.26, 10.46],
            [-73.24, 10.46],
            [-73.25, 10.48],
            [-73.26, 10.46],
          ],
        ],
      },
      'expiresAt': '2026-11-08T20:30:00.000Z',
    });
    expect(fence.isTemporary, isTrue);
  });
}
