import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/widgets/skeleton.dart';
import 'package:frontend/features/home/presentation/dispatcher_more_screen.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/theme/app_palette.dart';

const _hub = Hub(
  id: 'h',
  name: 'Hospital Central',
  type: HubType.hospital,
  address: 'Valledupar',
  latitude: 10.4,
  longitude: -73.2,
  contactPhone: '3001234567',
  status: HubStatus.active,
);
const _suspended = Hub(
  id: 'h',
  name: 'Hospital Central',
  type: HubType.hospital,
  address: 'Valledupar',
  latitude: 10.4,
  longitude: -73.2,
  contactPhone: '3001234567',
  status: HubStatus.suspended,
);
const _destinations = {
  'Traslados entrantes': '/orders/incoming',
  'Pendiente de carga': '/orders/pending-load',
  'Vuelos en curso': '/orders/in-flight',
  'Programados': '/orders/scheduled',
  'Historial': '/orders/history',
  'Urgencia a otra central': '/orders/hub-emergency',
  'Nuevo abastecimiento': '/orders/hub-plans/new',
  'Mis abastecimientos': '/orders/plans',
  'Información de la central': '/hubs/me',
  'Cuarentena': '/inventory/quarantine',
  'Mi perfil': '/profile',
  'Ajustes de la app': '/settings',
};

Future<GoRouter> _mount(
  WidgetTester tester, {
  Future<Hub?> Function()? loadHub,
  double scale = 1,
  List<Order> incoming = const [],
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/more',
    routes: [
      GoRoute(path: '/more', builder: (_, _) => const DispatcherMoreScreen()),
      for (final path in _destinations.values)
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('Destino $path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (count, error) => null,
      overrides: [
        myHubProvider.overrideWith(
          (ref) => loadHub?.call() ?? Future.value(_hub),
        ),
        queueProvider.overrideWith((ref) async => []),
        pendingLoadProvider.overrideWith((ref) async => []),
        scheduledProvider.overrideWith((ref) async => []),
        incomingProvider.overrideWith((ref) async => incoming),
        inFlightProvider.overrideWith((ref) async => []),
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
  await tester.pump();
  return router;
}

Future<void> _bring(WidgetTester tester, String label) async {
  await Scrollable.ensureVisible(
    tester.element(find.text(label)),
    alignment: 0.3,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Más cuenta todos los traslados entrantes, incluidos los que siguen en vuelo',
    (tester) async {
      Order transfer(String id, OrderStatus status) => Order(
        id: id,
        missionType: MissionType.emergency,
        destinationKind: DestinationKind.hub,
        status: status,
        priority: OrderPriority.normal,
        medicationName: 'Suero oral',
        saleType: SaleType.overTheCounter,
        requiresColdChain: false,
        quantity: 1,
        address: 'Valledupar',
        hasPrescription: false,
        createdByUserId: 'u',
        originHubId: 'other',
        destinationHubId: 'h',
      );
      await _mount(
        tester,
        incoming: [
          transfer('flying', OrderStatus.inFlight),
          transfer('landed', OrderStatus.awaitingDelivery),
        ],
      );
      await tester.pumpAndSettle();
      final row = find
          .ancestor(
            of: find.text('Traslados entrantes'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(
        find.descendant(of: row, matching: find.text('2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'los 12 accesos de Más abren su destino y permiten volver, texto x$scale',
      (tester) async {
        final router = await _mount(tester, scale: scale);
        await tester.pumpAndSettle();
        for (final entry in _destinations.entries) {
          await _bring(tester, entry.key);
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(find.text('Destino ${entry.value}'), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
        }
        expect(find.text('0'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'central suspendida bloquea operación y conserva cuenta, central y planes',
    (tester) async {
      final router = await _mount(tester, loadHub: () async => _suspended);
      await tester.pumpAndSettle();
      expect(find.textContaining('Tu central está suspendida'), findsOneWidget);
      for (final label in [
        'Traslados entrantes',
        'Urgencia a otra central',
        'Nuevo abastecimiento',
        'Cuarentena',
      ]) {
        await _bring(tester, label);
        final row = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(tester.widget<InkWell>(row).onTap, isNull);
      }
      for (final label in [
        'Información de la central',
        'Mis abastecimientos',
        'Mi perfil',
        'Ajustes de la app',
      ]) {
        await _bring(tester, label);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text('Destino ${_destinations[label]}'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'carga y fallo de central no inventan contadores ni ocultan la cuenta',
    (tester) async {
      final pending = Completer<Hub?>();
      await _mount(tester, loadHub: () => pending.future);
      expect(find.byType(Skeleton), findsOneWidget);
      pending.completeError(const ApiException('No hay conexión.'));
      await tester.pumpAndSettle();
      expect(find.text('No hay conexión.'), findsOneWidget);
      expect(find.text('Actualizar central'), findsOneWidget);
      await _bring(tester, 'Mi perfil');
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Destino /profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
