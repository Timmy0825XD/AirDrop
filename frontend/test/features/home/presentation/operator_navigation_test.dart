import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/role_shell.dart';
import 'package:frontend/core/widgets/floating_tab_bar.dart';
import 'package:frontend/features/analytics/data/analytics_models.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/fleet/data/fleet_dashboard_models.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/data/fleet_providers.dart';
import 'package:frontend/features/home/presentation/fleet_operator_home.dart';
import 'package:frontend/features/notifications/data/notice_providers.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/theme/app_theme.dart';
import 'operator_test_data.dart';

class _Session extends AuthController {
  @override
  Future<AuthState> build() async =>
      const AuthState.authenticated(operatorUser);
}

Future<(GoRouter, ProviderContainer)> _pump(
  WidgetTester tester, {
  double scale = 1,
  List<Drone> Function()? drones,
  List<AnalyticsQuery>? queries,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            RoleShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const FleetOperatorHome(user: operatorUser),
          ),
          for (final path in [
            '/fleet',
            '/fleet/flights',
            '/geofences',
            '/profile',
            '/notifications',
            '/tracking/:id',
          ])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text(path)),
            ),
        ],
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_Session.new),
      clockSyncProvider.overrideWith((ref) {}),
      assignedHubsProvider.overrideWith((ref) async => operatorHubs),
      operatorDronesProvider.overrideWith((ref) async => drones?.call() ?? []),
      fleetFlightsProvider.overrideWith(
        (ref) async => [
          operatorFlight('01'),
          operatorFlight('02', hubId: 'h2'),
        ],
      ),
      fleetModelsProvider.overrideWith((ref) async => operatorModels),
      fleetDashboardProvider.overrideWith((ref, query) async {
        queries?.add(query);
        return const FleetDashboard(flights: 42, km: 286);
      }),
      unreadCountProvider.overrideWith((ref) async => 3),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
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
  return (router, container);
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'cinco destinos, contador y regreso desde detalle con texto x$scale',
      (tester) async {
        final (router, _) = await _pump(tester, scale: scale);
        expect(find.byType(FloatingTabBar), findsOneWidget);
        for (final entry in {
          'Flota': '/fleet',
          'Mapa': '/fleet/flights',
          'Geovallas': '/geofences',
          'Perfil': '/profile',
          'Inicio': '/home',
        }.entries) {
          await tester.tap(
            find.descendant(
              of: find.byType(FloatingTabBar),
              matching: find.text(entry.key),
            ),
          );
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, entry.value);
          if (entry.key == 'Mapa') {
            final semantics = tester.widget<Semantics>(
              find.bySemanticsLabel('Mapa en vivo, 2 drones en misión'),
            );
            expect(semantics.properties.selected, isTrue);
          }
        }
        router.push('/tracking/p01');
        await tester.pumpAndSettle();
        expect(find.byType(FloatingTabBar), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(FloatingTabBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'una revisión de otra central selecciona esa central al abrir Flota',
    (tester) async {
      final (router, container) = await _pump(
        tester,
        drones: () => [operatorDrone('03', hubId: 'h2', due: true)],
      );
      await tester.ensureVisible(find.text('Ver dron'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver dron'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/fleet');
      expect(container.read(fleetHubProvider), 'h2');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'actualiza la operación cada diez segundos y permite cambiar periodo',
    (tester) async {
      var rows = <Drone>[];
      final queries = <AnalyticsQuery>[];
      await _pump(tester, drones: () => rows, queries: queries);
      expect(find.text('Todo al día'), findsOneWidget);
      rows = [operatorDrone('03', status: DroneStatus.maintenance)];
      final before = queries.length;
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
      expect(find.text('Todo al día'), findsNothing);
      expect(find.text('Mantenimiento pendiente'), findsOneWidget);
      expect(queries.length, greaterThan(before));
      await tester.ensureVisible(find.text('Últimos 30 días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Últimos 30 días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Últimos 7 días'));
      await tester.pumpAndSettle();
      expect(queries, contains(AnalyticsQuery.lastDays(7)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
