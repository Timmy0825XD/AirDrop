import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/role_shell.dart';
import 'package:frontend/core/widgets/floating_tab_bar.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/home/presentation/dispatcher_home.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/notifications/data/notice_providers.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/data/queue_live.dart';
import 'package:frontend/features/tracking/data/tracking_providers.dart';
import 'package:frontend/theme/app_palette.dart';

const _user = PublicUser(
  id: 'u1',
  fullName: 'Laura Pérez',
  email: 'despacho@example.test',
  phone: null,
  role: UserRole.dispatcher,
  status: UserStatus.active,
  hubIds: ['h1'],
);
const _hub = Hub(
  id: 'h1',
  name: 'Central La Paz',
  type: HubType.hospital,
  address: 'La Paz',
  latitude: 10.38,
  longitude: -73.17,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

class _Session extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(_user);
}

void main() {
  testWidgets(
    'el menú abre sus cinco destinos y se oculta al entrar a un detalle',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
                builder: (_, _) => const DispatcherHome(user: _user),
              ),
              for (final path in [
                '/orders/agenda',
                '/orders/queue',
                '/inventory',
                '/more',
                '/orders/p1',
              ])
                GoRoute(
                  path: path,
                  builder: (_, _) => Scaffold(body: Text(path)),
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Session.new),
            clockSyncProvider.overrideWith((ref) {}),
            queueLiveProvider.overrideWith((ref) {}),
            myHubProvider.overrideWith((ref) async => _hub),
            unreadCountProvider.overrideWith((ref) async => 0),
            queueProvider.overrideWith((ref) async => []),
            pendingLoadProvider.overrideWith((ref) async => []),
            scheduledProvider.overrideWith((ref) async => []),
            incomingProvider.overrideWith((ref) async => []),
            inFlightProvider.overrideWith((ref) async => []),
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
      expect(find.text('Todo al día'), findsOneWidget);
      for (final entry in {
        'Agenda': '/orders/agenda',
        'Urgencias': '/orders/queue',
        'Inventario': '/inventory',
        'Más': '/more',
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
      }
      router.push('/orders/p1');
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
