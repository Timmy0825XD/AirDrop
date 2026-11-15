import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/location/device_location.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/emergency_screen.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

/// Un GPS de mentira: responde lo que diga la prueba y anota qué ajuste
/// se pidió abrir.
class _FakeLocation extends DeviceLocation {
  _FakeLocation(this.answer);

  final Future<LocationFix> Function() answer;
  PhoneSetting? opened;

  @override
  Future<LocationFix> current() => answer();

  @override
  Future<void> openSettings(PhoneSetting which) async => opened = which;
}

Future<void> _pump(
  WidgetTester tester,
  _FakeLocation gps, {
  bool toWhere = true,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogProvider.overrideWith(
          (ref) async => const [
            CatalogOffer(
              name: 'Acetaminofén 500 mg',
              saleType: SaleType.overTheCounter,
              requiresColdChain: false,
            ),
          ],
        ),
        deviceLocationProvider.overrideWithValue(gps),
        // Los puntos de entrega salen del repositorio local.
        orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const EmergencyScreen()),
    ),
  );
  await tester.pumpAndSettle();
  if (toWhere) await _toWhere(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Llena "Qué pasa" y "Qué necesitas" (RF-41) para llegar a "Dónde".
Future<void> _toWhere(WidgetTester tester) async {
  await _tap(tester, find.text('Ninguno'));
  await _tap(tester, find.text('Adulto mayor'));
  await _tap(tester, find.text('Fiebre'));
  await _tap(tester, find.text('Desde hoy'));
  await _tap(tester, find.text('Leve'));
  await _tap(tester, find.text('Siguiente'));
  await _tap(tester, find.text('Elige el medicamento'));
  await _tap(tester, find.text('Acetaminofén 500 mg').last);
  await _tap(tester, find.text('No'));
  await _tap(tester, find.text('Siguiente'));
  expect(find.text('Paso 3 de 3 · Dónde'), findsOneWidget);
}

Future<void> _tapGps(WidgetTester tester) async {
  final button = find.text('Usar mi ubicación');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Dónde" lista los puntos de entrega y no pide dirección', (
    tester,
  ) async {
    await _pump(tester, _FakeLocation(() async => throw UnimplementedError()));

    expect(find.text('Punto de entrega'), findsOneWidget);
    expect(find.text('Puesto de salud de Badillo'), findsOneWidget);
    expect(find.text('Puesto de salud de Media Luna'), findsOneWidget);
    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Referencia para encontrarte'), findsNothing);
    // Sin GPS no se propone ninguno.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.textContaining('baja en el punto de entrega'), findsOneWidget);
  });

  testWidgets('"Usar mi ubicación" propone el punto más cercano', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLocation(
        () async =>
            const LocationFix(point: LatLng(10.63, -73.13), accuracyM: 12),
      ),
    );

    await _tapGps(tester);

    expect(find.textContaining('El más cercano'), findsOneWidget);
    expect(find.text('Valledupar · 0,3 km · El más cercano'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('se puede elegir otro punto de la lista', (tester) async {
    await _pump(
      tester,
      _FakeLocation(
        () async =>
            const LocationFix(point: LatLng(10.63, -73.13), accuracyM: 12),
      ),
    );
    await _tapGps(tester);

    await _tap(tester, find.text('Puesto de salud de Media Luna'));

    final chosen = tester.widget<Semantics>(
      find.ancestor(
        of: find.text('Puesto de salud de Media Luna'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == true,
        ),
      ),
    );
    expect(chosen.properties.label, contains('Media Luna'));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('en la ciudad dice por qué no hay dron y no deja pedir', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLocation(
        () async =>
            const LocationFix(point: LatLng(10.4766, -73.2434), accuracyM: 8),
      ),
    );
    expect(find.text('Desliza para pedir'), findsOneWidget);

    await _tapGps(tester);

    expect(
      find.textContaining('En la ciudad de Valledupar no se entrega con dron'),
      findsOneWidget,
    );
    expect(find.text('Puesto de salud de Badillo'), findsNothing);
    expect(find.text('Desliza para pedir'), findsNothing);
  });

  testWidgets('sin permiso lo explica y abre los ajustes de la app', (
    tester,
  ) async {
    final gps = _FakeLocation(
      () async => throw const LocationProblem(
        'Le quitaste a AirDrop el permiso de ubicación.',
        fix: PhoneSetting.app,
      ),
    );
    await _pump(tester, gps);

    await _tapGps(tester);

    expect(
      find.text('Le quitaste a AirDrop el permiso de ubicación.'),
      findsOneWidget,
    );
    // Sin GPS se sigue pudiendo elegir en la lista.
    expect(find.text('Puesto de salud de Badillo'), findsOneWidget);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(gps.opened, PhoneSetting.app);
  });
}
