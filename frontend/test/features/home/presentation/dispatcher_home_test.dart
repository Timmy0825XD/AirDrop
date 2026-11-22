import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/widgets/app_tab_bar.dart';
import 'package:frontend/core/widgets/floating_tab_bar.dart';
import 'package:frontend/features/home/presentation/widgets/dispatcher/dispatcher_home_page.dart';
import 'package:frontend/features/home/presentation/widgets/dispatcher/dispatcher_home_values.dart';
import 'package:frontend/features/home/presentation/widgets/dispatcher/dispatcher_tasks.dart';
import 'package:frontend/features/home/presentation/widgets/home_link.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/theme/app_icons.dart';
import 'package:frontend/theme/app_palette.dart';

Hub _hub({HubStatus status = HubStatus.active}) => Hub(
  id: 'h1',
  name: 'Central de atención rural de La Paz y sus corregimientos',
  type: HubType.hospital,
  address: 'La Paz',
  latitude: 10.38,
  longitude: -73.17,
  contactPhone: '3001234567',
  status: status,
);

Order _order(String id, OrderStatus status) => Order(
  id: id,
  status: status,
  missionType: MissionType.emergency,
  destinationKind: DestinationKind.hub,
  priority: OrderPriority.high,
  medicationName: 'Solución de rehidratación oral de baja osmolaridad $id',
  saleType: SaleType.overTheCounter,
  quantity: 2,
  requiresColdChain: false,
  address: 'Central San Diego',
  hasPrescription: false,
  createdByUserId: 'u1',
);

DispatcherHomeValues _empty() => DispatcherHomeValues(
  hub: AsyncData(_hub()),
  queue: const AsyncData([]),
  pendingLoad: const AsyncData([]),
  scheduled: const AsyncData([]),
  incoming: const AsyncData([]),
  flights: const AsyncData([]),
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
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _tasks(
  DispatcherHomeValues data, {
  ValueChanged<String>? onOpen,
  VoidCallback? onRetry,
}) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: DispatcherTasks(
      data: data,
      onOpen: onOpen ?? (_) {},
      onRetry: onRetry ?? () {},
    ),
  ),
);

void main() {
  testWidgets(
    'solo muestra Todo al día tras cargar todas las bandejas vacías',
    (tester) async {
      await _pump(tester, _tasks(DispatcherHomeValues(hub: AsyncData(_hub()))));
      expect(find.text('Todo al día'), findsNothing);
      expect(find.bySemanticsLabel('Cargando pendientes'), findsOneWidget);
      await _pump(tester, _tasks(_empty()));
      expect(find.text('Todo al día'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('un error ofrece reintentar y conserva las tareas conocidas', (
    tester,
  ) async {
    var retried = 0;
    final data = DispatcherHomeValues(
      hub: AsyncData(_hub()),
      queue: AsyncError(const ApiException('Sin conexión'), StackTrace.empty),
      pendingLoad: AsyncData([_order('p1', OrderStatus.pendingLoad)]),
      incoming: const AsyncData([]),
      scheduled: const AsyncData([]),
    );
    await _pump(tester, _tasks(data, onRetry: () => retried++));
    expect(find.text('Todo al día'), findsNothing);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Preparar carga'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, 1);
    expect(data.counts.queue, isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'tareas simultáneas y nombres largos caben a 320 px, texto x$scale',
      (tester) async {
        final opened = <String>[];
        final data = DispatcherHomeValues(
          hub: AsyncData(_hub()),
          queue: AsyncData([
            QueueEntry(
              order: _order('q1', OrderStatus.received),
              availableQuantity: 20,
              unattended: false,
            ),
          ]),
          pendingLoad: AsyncData([_order('p1', OrderStatus.pendingLoad)]),
          incoming: AsyncData([_order('i1', OrderStatus.awaitingDelivery)]),
          scheduled: const AsyncData([]),
          flights: const AsyncData([]),
        );
        await _pump(tester, _tasks(data, onOpen: opened.add), scale: scale);
        for (final label in [
          'Revisar solicitud',
          'Preparar carga',
          'Recibir traslado',
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
        }
        expect(opened, ['/orders/q1', '/orders/p1', '/delivery/i1']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'la central suspendida no muestra Todo al día ni habilita solicitudes',
    (tester) async {
      final data = DispatcherHomeValues(
        hub: AsyncData(_hub(status: HubStatus.suspended)),
      );
      await _pump(
        tester,
        DispatcherHomePage(
          data: data,
          fullName: 'Laura Pérez',
          onOpen: (_) {},
          onRetry: () {},
        ),
      );
      expect(find.text('Central suspendida'), findsNWidgets(2));
      expect(find.text('Todo al día'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Urgencia a otra central'),
        200,
      );
      final link = tester.widget<HomeLink>(
        find.ancestor(
          of: find.text('Urgencia a otra central'),
          matching: find.byType(HomeLink),
        ),
      );
      expect(link.onTap, isNull);
      await tester.scrollUntilVisible(find.text('Mis abastecimientos'), 200);
      expect(
        tester
            .widget<HomeLink>(
              find.ancestor(
                of: find.text('Mis abastecimientos'),
                matching: find.byType(HomeLink),
              ),
            )
            .onTap,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Inicio vacío completo admite texto grande y central de nombre largo',
    (tester) async {
      await _pump(
        tester,
        DispatcherHomePage(
          data: _empty(),
          fullName: 'Maríadelosángeles Rodríguez',
          onOpen: (_) {},
          onRetry: () {},
        ),
        scale: 2,
      );
      await tester.scrollUntilVisible(find.text('Hoy en tu central'), 200);
      await tester.scrollUntilVisible(find.text('Mis abastecimientos'), 200);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'la barra mantiene cinco destinos, contador y selección de Urgencias con texto grande',
    (tester) async {
      var openedUrgencies = 0;
      final selected = <int>[];
      await _pump(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingTabBar(
              destinations: const [
                NavDestination(icon: AppIcons.home, label: 'Inicio'),
                NavDestination(icon: AppIcons.calendar, label: 'Agenda'),
                NavDestination(icon: AppIcons.orders, label: 'Inventario'),
                NavDestination(icon: AppIcons.more, label: 'Más'),
              ],
              selected: null,
              centerActive: true,
              onSelect: selected.add,
              center: NavCenterAction(
                icon: AppIcons.urgency,
                label: 'Cola de urgencias',
                tabLabel: 'Urgencias',
                badge: 3,
                onPressed: () => openedUrgencies++,
              ),
            ),
          ),
        ),
        scale: 2,
      );
      for (final label in [
        'Inicio',
        'Agenda',
        'Urgencias',
        'Inventario',
        'Más',
      ]) {
        expect(find.text(label), findsOneWidget);
        await tester.tap(find.text(label));
      }
      final item = tester.widget<Semantics>(
        find.bySemanticsLabel('Cola de urgencias, 3 por atender'),
      );
      expect(item.properties.selected, isTrue);
      expect(selected, [0, 1, 2, 3]);
      expect(openedUrgencies, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
