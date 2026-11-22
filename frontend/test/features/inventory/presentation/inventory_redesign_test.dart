import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/choice_pill.dart';
import 'package:frontend/features/notifications/data/notice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/inventory/data/inventory_providers.dart';
import 'package:frontend/features/inventory/presentation/inventory_screen.dart';
import 'package:frontend/features/inventory/presentation/inventory_form_screen.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_list_content.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_list_page.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_list_values.dart';
import 'package:frontend/features/inventory/presentation/widgets/inventory_tile.dart';
import 'package:frontend/theme/app_palette.dart';

const _rows = [
  InventoryItem(
    id: 'a',
    hubId: 'h',
    name: 'Acetaminofén 500 mg',
    quantity: 0,
    lot: 'ACT-026',
    expirationDate: '2026-11-20',
    requiresColdChain: false,
    saleType: SaleType.overTheCounter,
  ),
  InventoryItem(
    id: 'b',
    hubId: 'h',
    name: 'Insulina glargina',
    quantity: 12,
    lot: 'INS-026',
    expirationDate: '2026-12-01',
    requiresColdChain: true,
    saleType: SaleType.prescription,
  ),
  InventoryItem(
    id: 'c',
    hubId: 'h',
    name: 'Suero oral',
    quantity: 24,
    lot: 'SRO-026',
    expirationDate: '2027-06-30',
    requiresColdChain: false,
    saleType: SaleType.overTheCounter,
  ),
];

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.light]),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 720),
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _bring(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Widget _state({
  List<InventoryItem>? rows,
  bool loading = false,
  String? error,
  VoidCallback? onAdd,
  VoidCallback? onRetry,
}) => InventoryListPage(
  header: const SizedBox.shrink(),
  onRefresh: () async {},
  onQuarantine: () {},
  content: InventoryListContent(
    rows: rows,
    loading: loading,
    error: error,
    query: '',
    filter: InventoryFilter.all,
    onAdd: onAdd ?? () {},
    onRetry: onRetry ?? () {},
    onClear: () {},
    onEdit: (_) {},
    onDelete: (_) {},
  ),
);

void main() {
  setUp(
    () => simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 21, 15), speed: 1, paused: true),
    ),
  );
  tearDown(simClock.reset);

  test('la caché de otra central nunca sirve al cambiar de despachador', () {
    expect(inventoryRowsForHub(_rows, 'h'), same(_rows));
    expect(inventoryRowsForHub(_rows, 'otra-central'), isNull);
    expect(inventoryRowsForHub(_rows, null), isNull);
    expect(inventoryRowsForHub(_rows, 'h', reloading: true), isNull);
  });

  testWidgets(
    'otra central no puede ver ni abrir el formulario de un lote retenido',
    (tester) async {
      Widget scoped(Widget page) => ProviderScope(
        overrides: [
          inventoryHubIdProvider.overrideWithValue('otra-central'),
          inventoryProvider.overrideWith((ref) async => _rows),
          unreadCountProvider.overrideWith((ref) async => 0),
        ],
        child: page,
      );
      await _mount(tester, scoped(const InventoryScreen()));
      expect(find.text('Acetaminofén 500 mg'), findsNothing);
      expect(
        find.textContaining('No pudimos verificar los lotes'),
        findsOneWidget,
      );
      await _mount(tester, scoped(const InventoryFormScreen(itemId: 'a')));
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('El ítem de inventario no pertenece a tu central.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('un fallo de recarga conserva los lotes conocidos con aviso', (
    tester,
  ) async {
    await _mount(tester, _state(rows: _rows, error: 'Sin conexión'));
    expect(find.textContaining('Últimos datos disponibles'), findsOneWidget);
    await _bring(tester, find.text('Insulina glargina'));
    expect(find.text('Insulina glargina'), findsOneWidget);
    expect(find.text('Empieza tu inventario'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'combina búsqueda por nombre o lote y filtros sin alterar las existencias',
    () {
      expect(
        inventoryResults(_rows, 'acetaminofen', InventoryFilter.all).single.id,
        'a',
      );
      expect(
        inventoryResults(_rows, 'ins-026', InventoryFilter.expiring).single.id,
        'b',
      );
      expect(
        inventoryResults(_rows, '', InventoryFilter.expired).single.id,
        'a',
      );
      expect(
        inventoryResults(_rows, 'Suero', InventoryFilter.expiring),
        isEmpty,
      );
      expect(_rows.first.quantity, 0);
    },
  );

  testWidgets(
    'distingue carga, vacío y error y ofrece las acciones correctas',
    (tester) async {
      await _mount(tester, _state(loading: true));
      expect(find.bySemanticsLabel('Cargando inventario'), findsOneWidget);
      expect(find.text('Empieza tu inventario'), findsNothing);
      var added = 0;
      await _mount(tester, _state(rows: [], onAdd: () => added++));
      await _bring(tester, find.text('Añadir el primer insumo'));
      await tester.tap(find.text('Añadir el primer insumo'));
      expect(added, 1);
      var retried = 0;
      await _mount(
        tester,
        _state(error: 'Sin conexión', onRetry: () => retried++),
      );
      expect(find.text('Empieza tu inventario'), findsNothing);
      await _bring(tester, find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('búsqueda y filtros reales permiten recuperar los resultados', (
    tester,
  ) async {
    await _mount(
      tester,
      ProviderScope(
        overrides: [
          unreadCountProvider.overrideWith((ref) async => 0),
          inventoryHubIdProvider.overrideWithValue('h'),
          inventoryProvider.overrideWith((ref) async => _rows),
        ],
        child: const InventoryScreen(),
      ),
    );
    await tester.tap(find.text('Por vencer'));
    await tester.pumpAndSettle();
    expect(find.text('Insulina glargina'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'INS-026');
    await tester.pumpAndSettle();
    expect(find.text('1 lote en inventario'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no existe');
    await tester.pumpAndSettle();
    await _bring(tester, find.text('Limpiar búsqueda y filtros'));
    await tester.tap(find.text('Limpiar búsqueda y filtros'));
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(
      tester
          .widget<ChoicePill>(find.widgetWithText(ChoicePill, 'Todos'))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('lote largo, frío y acciones caben a 320 px, texto x$scale', (
      tester,
    ) async {
      var edited = 0;
      var deleted = 0;
      const item = InventoryItem(
        id: 'long',
        hubId: 'h',
        name:
            'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica',
        quantity: 999999,
        lot: 'LOTE-EXTENSO-2026-021-COLOMBIA',
        expirationDate: '2026-12-01',
        requiresColdChain: true,
        dangerousGoods: true,
        saleType: SaleType.prescription,
      );
      await _mount(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: InventoryTile(
              item: item,
              onTap: () => edited++,
              onDelete: () => deleted++,
            ),
          ),
        ),
        scale: scale,
      );
      expect(find.text('Cadena de frío'), findsOneWidget);
      expect(find.text('Mercancía peligrosa · No vuela'), findsOneWidget);
      await _bring(tester, find.text(item.name));
      await tester.tap(find.text(item.name));
      expect(edited, 1);
      await _bring(tester, find.byTooltip('Opciones del lote ${item.lot}'));
      await tester.tap(find.byTooltip('Opciones del lote ${item.lot}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
