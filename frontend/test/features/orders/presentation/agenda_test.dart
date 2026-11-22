import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/agenda_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/agenda_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/agenda/agenda_content.dart';
import 'package:frontend/features/orders/presentation/widgets/agenda/agenda_day_bar.dart';
import 'package:frontend/features/orders/presentation/widgets/agenda/agenda_page.dart';
import 'package:frontend/features/orders/presentation/order_format.dart';
import 'package:frontend/theme/app_palette.dart';

AgendaOrder _entry(
  String id, {
  bool confirmed = true,
  bool stockOk = true,
  bool? prescriptionValid,
  DestinationKind destination = DestinationKind.person,
}) => AgendaOrder(
  order: Order(
    id: id,
    missionType: MissionType.scheduled,
    destinationKind: destination,
    status: OrderStatus.received,
    priority: OrderPriority.normal,
    medicationName:
        'Solución de rehidratación oral de baja osmolaridad, presentación pediátrica $id',
    saleType: SaleType.overTheCounter,
    requiresColdChain: false,
    quantity: 4,
    address: 'Central de atención rural de San Diego y sus corregimientos',
    hasPrescription: false,
    createdByUserId: 'u1',
  ),
  time: '09:00',
  confirmed: confirmed,
  stockOk: stockOk,
  availableQuantity: stockOk ? 12 : 2,
  prescriptionValid: prescriptionValid,
  departBefore: id == 'a' ? DateTime.utc(2026, 11, 21, 14, 40) : null,
);

AgendaDay _day(List<AgendaOrder> entries) => AgendaDay(
  date: '2026-11-21',
  drones: 1,
  slots: [
    if (entries.isNotEmpty)
      AgendaSlot(
        time: '09:00',
        deliveries: entries.length,
        overCapacity: entries.length > 1,
        orders: entries,
      ),
  ],
);

Widget _content({
  AgendaDay? day,
  bool loading = false,
  String? error,
  ValueChanged<String>? onOpen,
  VoidCallback? onPick,
  VoidCallback? onRetry,
}) => AgendaContent(
  day: day,
  loading: loading,
  error: error,
  onOpen: onOpen ?? (_) {},
  onPick: onPick ?? () {},
  onRetry: onRetry ?? () {},
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
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 22, 2), speed: 1, paused: true),
    ),
  );
  tearDown(simClock.reset);

  test('cambiar de día conserva el calendario al cruzar meses y años', () {
    expect(shiftIsoDate('2026-12-31', 1), '2027-01-01');
    expect(shiftIsoDate('2028-03-01', -1), '2028-02-29');
  });

  testWidgets('la agenda vacía ofrece elegir otra fecha', (tester) async {
    var picked = 0;
    await _pump(tester, _content(day: _day([]), onPick: () => picked++));
    expect(find.text('Un día sin entregas'), findsOneWidget);
    await tester.ensureVisible(find.text('Elegir otra fecha'));
    await tester.tap(find.text('Elegir otra fecha'));
    expect(picked, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'carga y error nunca se anuncian como agenda vacía; permite reintentar',
    (tester) async {
      await _pump(tester, _content(loading: true));
      expect(find.bySemanticsLabel('Cargando agenda'), findsOneWidget);
      expect(find.text('Un día sin entregas'), findsNothing);
      var retried = 0;
      await _pump(
        tester,
        _content(
          error: 'No se pudo conectar con el servidor.',
          onRetry: () => retried++,
        ),
      );
      expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
      expect(find.text('Un día sin entregas'), findsNothing);
      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      expect(retried, 1);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'varias entregas muestran sus verificaciones y abren el pedido, texto x$scale',
      (tester) async {
        final opened = <String>[];
        await _pump(
          tester,
          _content(
            day: _day([
              _entry('a', prescriptionValid: true),
              _entry(
                'b',
                confirmed: false,
                stockOk: false,
                prescriptionValid: false,
              ),
            ]),
            onOpen: opened.add,
          ),
          scale: scale,
        );
        expect(find.text('2 entregas programadas'), findsOneWidget);
        expect(
          find.text('Más entregas que drones en esta franja.'),
          findsOneWidget,
        );
        expect(find.text('Fórmula vigente'), findsOneWidget);
        expect(find.text('Fórmula vencida'), findsOneWidget);
        expect(find.text('Stock insuficiente: 2 de 4'), findsOneWidget);
        expect(find.text('Por confirmar'), findsOneWidget);
        expect(find.text('Despegar antes de las 9:40 a. m.'), findsOneWidget);
        expect(find.text('Sin ruta disponible'), findsOneWidget);
        for (final finder in [
          find.text('Revisar entrega').first,
          find.text('Revisar entrega').last,
        ]) {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
        }
        expect(opened, ['a', 'b']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('un traslado entre centrales no exige confirmación de persona', (
    tester,
  ) async {
    await _pump(
      tester,
      _content(
        day: _day([
          _entry('a', confirmed: false, destination: DestinationKind.hub),
        ]),
      ),
    );
    expect(find.text('No requiere confirmación'), findsOneWidget);
    expect(find.text('Por confirmar'), findsNothing);
    expect(find.text('Fórmula vigente'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selector de días, calendario y volver a hoy funcionan con texto grande',
    (tester) async {
      var picked = 0;
      final dates = <String>[];
      await _pump(
        tester,
        AgendaDayBar(
          date: '2026-11-22',
          onChanged: dates.add,
          onPick: () => picked++,
        ),
        scale: 2,
      );
      await tester.tap(find.byTooltip('Día anterior'));
      await tester.tap(find.byTooltip('Día siguiente'));
      await tester.tap(
        find.text(capitalized(formatDay('2026-11-22', relative: false))),
      );
      await tester.tap(find.text('Volver a hoy'));
      expect(dates, ['2026-11-21', '2026-11-23', '2026-11-21']);
      expect(picked, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'consulta el día de Colombia, cambia de fecha y refresca cada 10 segundos',
    (tester) async {
      final requests = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaProvider.overrideWith((ref, date) async {
              requests.add(date);
              return AgendaDay(
                date: date,
                drones: 1,
                slots: date == '2026-11-21'
                    ? const []
                    : _day([_entry('a')]).slots,
              );
            }),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const AgendaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, ['2026-11-21']);
      await tester.tap(find.byTooltip('Día siguiente'));
      await tester.pumpAndSettle();
      expect(requests.last, '2026-11-22');
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        0,
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(requests.where((date) => date == '2026-11-22').length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'la página completa conserva el acceso a programados y cabe con texto al 200 %',
    (tester) async {
      var opened = 0;
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: AgendaPage(
              date: '2026-11-21',
              content: _content(day: _day([])),
              onDateChanged: (_) {},
              onPick: () {},
              onRefresh: () async {},
              onProgrammed: () => opened++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ver todos los programados'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Ver todos los programados')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todos los programados'));
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
