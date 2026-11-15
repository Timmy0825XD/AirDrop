import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/medications_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/medications/medication_rules.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

const _acetaminophen = CatalogOffer(
  name: 'Acetaminofén 500 mg',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  availableQuantity: 8,
);
const _insulin = CatalogOffer(
  name: 'Insulina glargina 100 UI/ml',
  saleType: SaleType.prescription,
  requiresColdChain: true,
  availableQuantity: 3,
);
const _tramadol = CatalogOffer(
  name: 'Tramadol 50 mg',
  saleType: SaleType.specialControl,
  requiresColdChain: false,
  availableQuantity: 12,
);
const _offers = [_insulin, _tramadol, _acetaminophen];

/// La lista dentro de un router mínimo; anota con qué se abrió la urgencia.
Future<List<Object?>> _pump(
  WidgetTester tester, {
  List<CatalogOffer> offers = _offers,
  Object? error,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final opened = <Object?>[];
  final router = GoRouter(
    initialLocation: '/medications',
    routes: [
      GoRoute(
        path: '/medications',
        builder: (_, _) => const MedicationsScreen(),
      ),
      GoRoute(
        path: '/orders/emergency',
        builder: (_, state) {
          opened.add(state.extra);
          return const Scaffold(body: Text('Pedir urgencia'));
        },
      ),
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        catalogProvider.overrideWith(
          (ref) async => error == null ? offers : throw error,
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  test('la disponibilidad se dice en palabras, nunca con la cantidad', () {
    CatalogOffer offer(
      int? quantity, [
      SaleType type = SaleType.prescription,
    ]) => CatalogOffer(
      name: 'X',
      saleType: type,
      requiresColdChain: false,
      availableQuantity: quantity,
    );

    expect(availabilityOf(offer(40)), Availability.available);
    expect(availabilityOf(offer(6)), Availability.available);
    expect(availabilityOf(offer(5)), Availability.few);
    expect(availabilityOf(offer(1)), Availability.few);
    expect(availabilityOf(offer(0)), Availability.none);
    // Sin cantidad en el catálogo: si llegó, se puede pedir.
    expect(availabilityOf(offer(null)), Availability.available);
    // Control especial no viaja por dron, haya o no existencias.
    expect(
      availabilityOf(offer(12, SaleType.specialControl)),
      Availability.notHere,
    );
    expect(Availability.few.canOrder, isTrue);
    expect(Availability.none.canOrder, isFalse);
    expect(Availability.notHere.canOrder, isFalse);
  });

  test('el filtro busca sin tildes ni mayúsculas y ordena por nombre', () {
    List<String> names(MedicationFilter filter) => [
      for (final offer in filter.apply(_offers)) offer.name,
    ];

    expect(names(const MedicationFilter()), [
      _acetaminophen.name,
      _insulin.name,
      _tramadol.name,
    ]);
    expect(names(const MedicationFilter(query: 'ACETAMINOFEN')), [
      _acetaminophen.name,
    ]);
    expect(names(const MedicationFilter(coldOnly: true)), [_insulin.name]);
    expect(names(const MedicationFilter(prescriptionOnly: true)), [
      _insulin.name,
    ]);
    expect(names(const MedicationFilter(query: 'zzz')), isEmpty);
  });

  testWidgets('la lista muestra lo que exige cada uno y no la cantidad', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Acetaminofén 500 mg'), findsOneWidget);
    expect(find.text('Venta libre'), findsOneWidget);
    expect(find.text('Bajo fórmula · Viaja en frío'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Pocas unidades'), findsOneWidget);
    expect(find.text('No se pide por aquí'), findsOneWidget);
    // Ni cantidades ni unidades en ninguna parte.
    expect(find.textContaining('und'), findsNothing);
    expect(find.textContaining(RegExp(r'\b(3|8|12)\b')), findsNothing);
  });

  testWidgets('buscar sin resultados lo dice y deja quitar los filtros', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nada coincide'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Acetaminofén 500 mg'), findsOneWidget);
  });

  testWidgets('pedir desde el detalle abre la urgencia con ese medicamento', (
    tester,
  ) async {
    final opened = await _pump(tester);

    await tester.tap(find.text('Insulina glargina 100 UI/ml'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fórmula médica a nombre'), findsOneWidget);

    await tester.tap(find.text('Pedir este medicamento'));
    await tester.pumpAndSettle();
    expect(find.text('Pedir urgencia'), findsOneWidget);
    expect(opened.single, _insulin);
  });

  testWidgets('un control especial explica por qué y no deja pedir', (
    tester,
  ) async {
    final opened = await _pump(tester);

    await tester.tap(find.text('Tramadol 50 mg'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no viajan por dron'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Pedir este medicamento'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(opened, isEmpty);
  });

  testWidgets('sin conexión queda la última lista y deja reintentar', (
    tester,
  ) async {
    var online = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        catalogProvider.overrideWith(
          (ref) async => online ? _offers : throw Exception('sin red'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MedicationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión'), findsNothing);

    online = false;
    container.invalidate(catalogProvider);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión. Esta es la última'), findsOne);
    expect(find.text('Acetaminofén 500 mg'), findsOneWidget);

    online = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión'), findsNothing);
  });

  testWidgets('sin medicamentos lo dice', (tester) async {
    await _pump(tester, offers: const []);
    expect(find.text('No hay medicamentos por ahora'), findsOneWidget);
  });

  testWidgets('si el catálogo falla lo dice y deja reintentar', (tester) async {
    await _pump(tester, error: Exception('sin red'));
    expect(find.text('No pudimos cargar esto'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
