import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/location/device_location.dart';
import 'package:frontend/core/widgets/warning_banner.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
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

Future<void> _pump(WidgetTester tester, _FakeLocation gps) async {
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
      ],
      child: MaterialApp(theme: AppTheme.light, home: const EmergencyScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapGps(WidgetTester tester) async {
  final button = find.text('Usar mi ubicación');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el punto es el destino: no hay campo de dirección obligatorio', (
    tester,
  ) async {
    await _pump(tester, _FakeLocation(() async => throw UnimplementedError()));

    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Referencia para encontrarte'), findsOneWidget);
    expect(find.text('Opcional'), findsOneWidget);
    expect(find.textContaining('lugar despejado'), findsOneWidget);
  });

  testWidgets('"Usar mi ubicación" pone el pin y dice la precisión', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLocation(
        () async =>
            const LocationFix(point: LatLng(10.4702, -73.2551), accuracyM: 12),
      ),
    );

    await _tapGps(tester);

    expect(find.text('10.4702, -73.2551'), findsOneWidget);
    expect(find.text('Punto tomado del GPS (±12 m)'), findsOneWidget);
    expect(find.byType(WarningBanner), findsNothing);
  });

  testWidgets('con un GPS impreciso pide afinar el pin en el mapa', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLocation(
        () async =>
            const LocationFix(point: LatLng(10.4702, -73.2551), accuracyM: 120),
      ),
    );

    await _tapGps(tester);

    expect(
      find.text(
        'El GPS tiene un error de ±120 m. Toca el mapa y deja el pin en el '
        'lugar exacto.',
      ),
      findsOneWidget,
    );
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
    expect(find.text('10.4702, -73.2551'), findsNothing);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(gps.opened, PhoneSetting.app);
  });
}
