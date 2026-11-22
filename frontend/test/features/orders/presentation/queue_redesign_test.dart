import 'package:flutter/material.dart';
import 'package:frontend/features/notifications/data/notice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/core/widgets/status_pill.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/queue_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/queue/queue_content.dart';
import 'package:frontend/features/orders/presentation/widgets/queue/queue_indicators.dart';
import 'package:frontend/features/orders/presentation/widgets/queue/queue_page.dart';
import 'package:frontend/theme/app_palette.dart';

final _now = DateTime.utc(2026, 11, 21, 15);

QueueEntry _entry(
  String id, {
  int wait = 4,
  bool alarm = false,
  bool reassigned = false,
  bool enough = true,
  bool dated = true,
}) => QueueEntry(
  order: Order(
    id: id,
    missionType: MissionType.emergency,
    destinationKind: DestinationKind.person,
    status: reassigned ? OrderStatus.reassigned : OrderStatus.received,
    priority: OrderPriority.high,
    medicationName:
        'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica $id',
    saleType: SaleType.prescription,
    requiresColdChain: true,
    quantity: 4,
    address: 'Patio amplio de la casa esquinera',
    hasPrescription: true,
    createdByUserId: 'u1',
    createdAt: dated ? _now.subtract(Duration(minutes: wait)) : null,
    triage: alarm
        ? const OrderTriage(
            redFlags: [RedFlag.breathingDifficulty],
            patientGroup: PatientGroup.adult,
            symptoms: [Symptom.breathing],
            onset: SymptomOnset.today,
            severity: SymptomSeverity.severe,
          )
        : null,
    fallback: reassigned ? const OrderFallback(kind: FallbackKind.hub) : null,
  ),
  availableQuantity: enough ? 12 : 2,
  unattended: wait >= 5,
);

Widget _page({
  List<QueueEntry>? entries,
  String? error,
  bool loading = false,
  ValueChanged<String>? onOpen,
  VoidCallback? onRetry,
  VoidCallback? onPendingLoad,
}) => QueuePage(
  onRefresh: () async {},
  onPendingLoad: onPendingLoad ?? () {},
  content: QueueContent(
    entries: entries,
    error: error,
    loading: loading,
    onOpen: onOpen ?? (_) {},
    onRetry: onRetry ?? () {},
  ),
);

Future<void> _pump(
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
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => simClock.apply(ClockView(now: _now, speed: 1, paused: true)));
  tearDown(simClock.reset);

  testWidgets('la carga no se confunde con una cola vacía', (tester) async {
    await _pump(tester, _page(loading: true));
    expect(find.bySemanticsLabel('Cargando urgencias'), findsOneWidget);
    expect(find.text('Todo al día'), findsNothing);
    expect(find.textContaining('solicitudes por atender'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cola vacía con Actualizar y acceso a los pedidos ya autorizados',
    (tester) async {
      var reloaded = 0;
      var loadsOpened = 0;
      await _pump(
        tester,
        _page(
          entries: [],
          onRetry: () => reloaded++,
          onPendingLoad: () => loadsOpened++,
        ),
      );
      expect(find.text('Todo al día'), findsOneWidget);
      await _bring(tester, find.text('Actualizar'));
      await tester.tap(find.text('Actualizar'));
      await _bring(tester, find.text('Pedidos pendientes de carga'));
      await tester.tap(find.text('Pedidos pendientes de carga'));
      expect(reloaded, 1);
      expect(loadsOpened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('un fallo inicial muestra el mensaje y permite reintentar', (
    tester,
  ) async {
    var retried = 0;
    await _pump(
      tester,
      _page(
        error: 'No se pudo conectar con el servidor.',
        onRetry: () => retried++,
      ),
    );
    expect(find.text('Todo al día'), findsNothing);
    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
    await _bring(tester, find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    expect(retried, 1);
  });

  testWidgets('si falla una recarga conserva las urgencias conocidas y avisa', (
    tester,
  ) async {
    final opened = <String>[];
    await _pump(
      tester,
      _page(entries: [_entry('a')], error: 'Sin conexión', onOpen: opened.add),
    );
    expect(find.textContaining('Últimos datos disponibles'), findsOneWidget);
    await _bring(tester, find.text('Revisar solicitud'));
    await tester.tap(find.text('Revisar solicitud'));
    expect(opened, ['a']);
    expect(find.text('Todo al día'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'alarma y reasignación visibles, prioridad conservada y texto x$scale a 320 px',
      (tester) async {
        final opened = <String>[];
        await _pump(
          tester,
          _page(
            entries: [
              _entry(
                'alarm',
                wait: 1,
                alarm: true,
                reassigned: true,
                enough: false,
              ),
              _entry('older', wait: 10),
            ],
            onOpen: opened.add,
          ),
          scale: scale,
        );
        await _bring(tester, find.text('Signo de alarma'));
        expect(find.text('Viene de otra central'), findsOneWidget);
        expect(find.text('Stock insuficiente: 2 de 4'), findsOneWidget);
        expect(find.text('Requiere cadena de frío'), findsOneWidget);
        expect(find.text('Fórmula adjunta'), findsOneWidget);
        final alarmIndicators = find.byType(QueueIndicators).first;
        expect(
          tester
              .widget<StatusPill>(
                find
                    .descendant(
                      of: alarmIndicators,
                      matching: find.byType(StatusPill),
                    )
                    .last,
              )
              .tone,
          PillTone.negative,
        );
        for (final id in ['alarm', 'older']) {
          final button = find.descendant(
            of: find.byKey(ValueKey(id)),
            matching: find.text('Revisar solicitud'),
          );
          await _bring(tester, button);
          await tester.tap(button);
        }
        expect(opened, ['alarm', 'older']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('una hora desconocida no se anuncia como recién llegada', (
    tester,
  ) async {
    await _pump(tester, _page(entries: [_entry('a', dated: false)]));
    expect(find.text('Hora no disponible'), findsOneWidget);
    expect(find.text('Recién llegada'), findsNothing);
  });

  testWidgets(
    'el refresco conserva la cola y calcula la espera con el reloj simulado',
    (tester) async {
      var requests = 0;
      final rows = [_entry('a')];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadCountProvider.overrideWith((ref) async => 0),
            queueProvider.overrideWith((ref) async {
              requests++;
              return rows;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const QueueScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Espera 4 min'), findsOneWidget);
      simClock.apply(
        ClockView(
          now: _now.add(const Duration(minutes: 2)),
          speed: 8,
          paused: true,
        ),
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(find.text('Espera 6 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Revisar solicitud y Pendientes de carga abren sus rutas existentes',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/orders/queue',
        routes: [
          GoRoute(
            path: '/orders/queue',
            builder: (_, _) => const QueueScreen(),
          ),
          GoRoute(
            path: '/orders/pending-load',
            builder: (_, _) => const Scaffold(body: Text('Revisión de carga')),
          ),
          GoRoute(
            path: '/orders/a',
            builder: (_, _) =>
                const Scaffold(body: Text('Revisión del pedido')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadCountProvider.overrideWith((ref) async => 0),
            queueProvider.overrideWith((ref) async => [_entry('a')]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Revisar solicitud'));
      await tester.tap(find.text('Revisar solicitud'));
      await tester.pumpAndSettle();
      expect(find.text('Revisión del pedido'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Pedidos pendientes de carga'));
      await tester.tap(find.text('Pedidos pendientes de carga'));
      await tester.pumpAndSettle();
      expect(find.text('Revisión de carga'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
