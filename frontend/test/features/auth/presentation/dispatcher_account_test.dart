import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/prefs/app_prefs.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/auth/presentation/profile_screen.dart';
import 'package:frontend/features/auth/presentation/widgets/profile/profile_field_type.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/features/settings/data/app_settings.dart';
import 'package:frontend/theme/app_palette.dart';

PublicUser _user({String name = 'Ana Pérez', String? pendingEmail}) =>
    PublicUser(
      id: 'u',
      fullName: name,
      role: UserRole.dispatcher,
      status: UserStatus.active,
      email: 'ana@ejemplo.com',
      phone: '3001234567',
      hubIds: const ['h'],
      pendingEmail: pendingEmail,
    );
const _hub = Hub(
  id: 'h',
  name: 'Hospital Central de Atención y Rehabilitación Regional',
  type: HubType.hospital,
  address: 'Valledupar, sede central de la red regional',
  latitude: 10.4,
  longitude: -73.2,
  contactPhone: '3001234567',
  status: HubStatus.active,
);

class _Auth extends AuthController {
  _Auth(this.user);
  PublicUser user;
  UpdateProfileRequest? saved;
  @override
  Future<AuthState> build() async => AuthState.authenticated(user);
  @override
  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    saved = request;
    user = _user(
      name: request.fullName ?? user.fullName,
      pendingEmail: user.pendingEmail,
    );
    state = AsyncData(AuthState.authenticated(user));
    return user;
  }

  @override
  Future<PublicUser> cancelEmailChange() async {
    user = _user(name: user.fullName);
    state = AsyncData(AuthState.authenticated(user));
    return user;
  }
}

Future<GoRouter> _mount(
  WidgetTester tester,
  _Auth auth, {
  double scale = 1,
  String initial = '/profile',
  MemoryPrefsStore? prefs,
  Future<Hub?> Function()? loadHub,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/privacy/policy',
        builder: (_, _) => const Scaffold(body: Text('Privacidad')),
      ),
      GoRoute(
        path: '/hubs/me',
        builder: (_, _) => const Scaffold(body: Text('Mi central')),
      ),
      GoRoute(
        path: '/profile/email',
        builder: (_, _) => const Scaffold(body: Text('Verificar correo')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (count, error) => null,
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        myHubProvider.overrideWith(
          (ref) => loadHub?.call() ?? Future.value(_hub),
        ),
        prefsStoreProvider.overrideWithValue(
          prefs ?? MemoryPrefsStore(available: true),
        ),
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
  return router;
}

Future<void> _bring(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'perfil mantiene la central conocida si falla una actualización',
    (tester) async {
      var attempts = 0;
      final router = await _mount(
        tester,
        _Auth(_user()),
        loadHub: () async {
          if (attempts++ > 0) throw Exception('Sin conexión');
          return _hub;
        },
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileScreen)),
        listen: false,
      );
      container.invalidate(myHubProvider);
      await tester.pumpAndSettle();
      await _bring(tester, find.text(_hub.name));
      expect(find.text('Reintentar'), findsOneWidget);
      await tester.tap(find.text(_hub.name));
      await tester.pumpAndSettle();
      expect(find.text('Mi central'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'perfil institucional conserva edición y excluye documento y alergias',
    (tester) async {
      final auth = _Auth(_user());
      await _mount(tester, auth);
      expect(find.text('Despachador'), findsOneWidget);
      expect(find.text('Alergias registradas'), findsNothing);
      await _bring(tester, find.text('Datos personales'));
      await tester.tap(find.text('Datos personales'));
      await tester.pumpAndSettle();
      expect(find.text('Documento'), findsNothing);
      await tester.tap(find.text(ProfileFieldType.fullName.label));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ana Pérez Gómez');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(auth.saved?.fullName, 'Ana Pérez Gómez');
      expect(find.text('Ana Pérez Gómez'), findsOneWidget);
      await _bring(tester, find.text('Política de privacidad'));
      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();
      expect(find.text('Privacidad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'correo pendiente permite verificar y cancelar desde la cuenta del despachador',
    (tester) async {
      final auth = _Auth(_user(pendingEmail: 'nuevo@ejemplo.com'));
      final router = await _mount(tester, auth);
      await _bring(tester, find.text('Ingresar código'));
      await tester.tap(find.text('Ingresar código'));
      await tester.pumpAndSettle();
      expect(find.text('Verificar correo'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(auth.user.pendingEmail, isNull);
      expect(find.text('Correo pendiente de confirmar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'perfil, central asignada y ajustes caben a 320 px con texto x2',
    (tester) async {
      final auth = _Auth(
        _user(name: 'Ana Valentina Pérez Rodríguez de la central regional'),
      );
      final router = await _mount(tester, auth, scale: 2);
      await _bring(
        tester,
        find.text('Hospital Central de Atención y Rehabilitación Regional'),
      );
      await tester.tap(
        find.text('Hospital Central de Atención y Rehabilitación Regional'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mi central'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Ajustes de la app'));
      await tester.tap(find.text('Ajustes de la app'));
      await tester.pumpAndSettle();
      expect(find.text('Modo sencillo'), findsNothing);
      expect(find.text('Ajustes de la app'), findsOneWidget);
      await _bring(tester, find.text(TextSize.extraLarge.label));
      await tester.tap(find.text(TextSize.extraLarge.label));
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Reducir movimiento'));
      expect(tester.takeException(), isNull);
    },
  );
}
