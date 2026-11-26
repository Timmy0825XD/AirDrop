import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/widgets/emergency/emergency_layout.dart';
import 'package:frontend/features/orders/presentation/widgets/emergency/emergency_situation.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/triage_fields.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/requester_order_values.dart';

const _catalog = AsyncData([
  CatalogOffer(
    name: 'Insumo de prueba',
    saleType: SaleType.overTheCounter,
    requiresColdChain: false,
  ),
]);

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('el formulario se dibuja y se desplaza con texto a x$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final values = RequesterOrderValues();
      addTearDown(values.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: EmergencyLayout(
              step: 0,
              source: _catalog,
              onBack: () {},
              content: EmergencySituation(
                form: TriageForm(
                  draft: values.triage,
                  errors: const {},
                  onChanged: () {},
                ),
                note: values.description,
              ),
              button: FilledButton(
                onPressed: () {},
                child: const Text('Continuar'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Vamos contigo.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Continuar'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Continuar').hitTestable(), findsOneWidget);
    });
  }

  testWidgets(
    'los controles que usan LayoutBuilder no requieren medidas intrínsecas',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyLayout(
            step: 1,
            source: _catalog,
            onBack: () {},
            content: LayoutBuilder(
              builder: (_, box) => Text('Ancho ${box.maxWidth}'),
            ),
            button: const Text('Elegir entrega'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Ancho'), findsOneWidget);
    },
  );
}
