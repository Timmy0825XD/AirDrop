import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/plan_form_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/form_steps.dart';
import 'package:frontend/features/orders/presentation/widgets/hub_request/hub_request_values.dart';

const _medication = CatalogOffer(
  name: 'Suero oral',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
);

const _hubOffer = CatalogOffer(
  name: 'Suero oral',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  availableQuantity: 30,
);

void main() {
  group('urgencia a otra central, medicamento primero', () {
    test('pide el medicamento y después la central', () {
      final values = HubRequestValues();
      addTearDown(values.dispose);

      expect(values.validate(plan: false, medicationFirst: true), {
        HubRequestInput.offer: 'Elige el medicamento.',
      });

      values.pickMedication(_medication);
      expect(values.validate(plan: false, medicationFirst: true), {
        HubRequestInput.origin: 'Elige de qué central sale.',
      });

      values.pickSource('hub-2', _hubOffer);
      expect(values.validate(plan: false, medicationFirst: true), isEmpty);
      expect(values.emergency().originHubId, 'hub-2');
    });

    test('cambiar de medicamento suelta la central elegida', () {
      final values = HubRequestValues()
        ..pickMedication(_medication)
        ..pickSource('hub-2', _hubOffer);
      addTearDown(values.dispose);

      values.pickMedication(
        const CatalogOffer(
          name: 'Insulina',
          saleType: SaleType.prescription,
          requiresColdChain: true,
        ),
      );
      expect(values.originHubId, isNull);
      expect(values.offer, isNull);
    });
  });

  testWidgets('el avance dice el paso y su nombre', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormSteps(labels: ['Qué', 'Cuándo', 'Dónde'], current: 1),
        ),
      ),
    );
    expect(find.text('Paso 2 de 3 · Cuándo'), findsOneWidget);
  });

  testWidgets('la entrega periódica no pasa del paso 1 sin medicamento', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => [_medication]),
        ],
        child: const MaterialApp(home: PlanFormScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Paso 1 de 3 · Qué'), findsOneWidget);
    // Los campos de "Dónde" todavía no están.
    expect(find.text('Dirección'), findsNothing);

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Paso 1 de 3 · Qué'), findsOneWidget);
    expect(find.text('Elige un medicamento del catálogo.'), findsOneWidget);
  });
}
