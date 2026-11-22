import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/core/widgets/auth_field.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/data/inventory_providers.dart';
import 'package:frontend/features/inventory/data/inventory_repository.dart';
import 'package:frontend/features/inventory/presentation/inventory_form_screen.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_form/inventory_form_sheet.dart';
import 'package:frontend/theme/app_palette.dart';

const _existing = InventoryItem(
  id: 'a',
  hubId: 'h',
  name: 'Suero oral',
  quantity: 12,
  lot: 'SRO-026',
  expirationDate: '2027-06-30',
  requiresColdChain: false,
  saleType: SaleType.overTheCounter,
  unitWeightG: 30,
);

class _Repository implements InventoryRepository {
  CreateInventoryItemRequest? created;
  UpdateInventoryItemRequest? updated;
  @override
  Future<List<InventoryItem>> list() async => [_existing];
  @override
  Future<InventoryItem> create(CreateInventoryItemRequest request) async {
    created = request;
    return _existing;
  }

  @override
  Future<InventoryItem> update(
    String id,
    UpdateInventoryItemRequest request,
  ) async {
    expect(id, _existing.id);
    updated = request;
    return _existing;
  }

  @override
  Future<void> remove(String id) async {}
  @override
  Future<List<QuarantineRecord>> quarantine() async => [];
}

Future<void> _mount(
  WidgetTester tester,
  _Repository repository, {
  bool edit = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/inventory/form',
    routes: [
      GoRoute(
        path: '/inventory',
        builder: (_, _) => const Scaffold(body: Text('Inventario guardado')),
      ),
      GoRoute(
        path: '/inventory/form',
        builder: (_, _) => InventoryFormScreen(itemId: edit ? 'a' : null),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryHubIdProvider.overrideWithValue('h'),
        inventoryRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(extensions: const [AppPalette.light]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _input(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is AuthField && widget.label == label,
  ),
  matching: find.byType(TextField),
);

Future<void> _bring(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 21, 15), speed: 1, paused: true),
    ),
  );
  tearDown(simClock.reset);

  testWidgets(
    'añadir conserva los datos, tipo de venta y condiciones del insumo',
    (tester) async {
      final repository = _Repository();
      await _mount(tester, repository);
      for (final field in {
        'Nombre del medicamento': '  Insulina glargina  ',
        'Lote': ' ins-026 ',
        'Cantidad': '12',
        'Peso por unidad (g)': '30',
      }.entries) {
        await _bring(tester, _input(field.key));
        await tester.enterText(_input(field.key), field.value);
      }
      final sheet = tester.widget<InventoryFormSheet>(
        find.byType(InventoryFormSheet),
      );
      sheet.values.expirationDate.text = '2027-06-30';
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Bajo fórmula'));
      await tester.tap(find.text('Bajo fórmula'));
      await tester.pumpAndSettle();
      for (final toggle in [
        find.byType(Switch).first,
        find.byType(Switch).last,
      ]) {
        await _bring(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      await _bring(tester, find.text('Agregar al inventario'));
      await tester.tap(find.text('Agregar al inventario'));
      await tester.pumpAndSettle();
      expect(repository.created?.toJson(), {
        'name': 'Insulina glargina',
        'lot': 'INS-026',
        'quantity': 12,
        'unitWeightG': 30,
        'expirationDate': '2027-06-30',
        'saleType': 'prescription',
        'requiresColdChain': true,
        'dangerousGoods': true,
      });
      expect(find.text('Inventario guardado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editar a texto x2 evita un PATCH vacío y guarda solo la cantidad cambiada',
    (tester) async {
      final repository = _Repository();
      await _mount(tester, repository, edit: true, scale: 2);
      expect(
        tester
            .widget<TextField>(_input('Nombre del medicamento'))
            .controller!
            .text,
        'Suero oral',
      );
      await _bring(tester, find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(repository.updated, isNull);
      expect(find.text('No hay cambios para guardar.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await _bring(tester, _input('Cantidad'));
      await tester.enterText(_input('Cantidad'), '0');
      await _bring(tester, find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(repository.updated?.toJson(), {'quantity': 0});
      expect(find.text('Inventario guardado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
