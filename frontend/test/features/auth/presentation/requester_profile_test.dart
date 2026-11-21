import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/auth/presentation/profile_screen.dart';
import 'package:frontend/theme/app_palette.dart';

PublicUser _user({
  String name = 'Ana Pérez',
  String email = 'ana@correo.co',
  String? pendingEmail,
  String? allergies,
}) => PublicUser(
  id: 'requester',
  fullName: name,
  email: email,
  phone: '3001234567',
  role: UserRole.requester,
  status: UserStatus.active,
  hubIds: const [],
  documentType: DocumentType.citizenshipId,
  documentNumber: '1234567890',
  pendingEmail: pendingEmail,
  allergies: allergies,
);

class _Auth extends AuthController {
  _Auth(this.user, {this.failOnce = false});
  PublicUser user;
  bool failOnce;
  UpdateProfileRequest? saved;
  int logoutCalls = 0;

  @override
  Future<AuthState> build() async {
    if (failOnce) {
      throw const ApiException('No hay conexión.');
    }
    return AuthState.authenticated(user);
  }

  @override
  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    saved = request;
    user = _user(
      name: request.fullName ?? user.fullName,
      email: user.email!,
      pendingEmail: request.email ?? user.pendingEmail,
      allergies: user.allergies,
    );
    state = AsyncData(AuthState.authenticated(user));
    return user;
  }

  @override
  Future<PublicUser> cancelEmailChange() async {
    user = _user(
      name: user.fullName,
      email: user.email!,
      allergies: user.allergies,
    );
    state = AsyncData(AuthState.authenticated(user));
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = const AsyncData(AuthState.unauthenticated());
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _Auth auth, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
      for (final (path, title) in [
        ('/settings', 'Pantalla de ajustes'),
        ('/privacy', 'Pantalla de privacidad'),
        ('/profile/email', 'Verificar correo nuevo'),
        ('/login', 'Pantalla de acceso'),
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(title)),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => auth)],
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

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('agrupa la información y abre ajustes y privacidad', (
    tester,
  ) async {
    final router = await _pump(tester, _Auth(_user()));
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Tu información'), findsOneWidget);
    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de ajustes'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await _tap(tester, 'Privacidad y mis datos');
    expect(find.text('Pantalla de privacidad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar datos conserva el guardado y actualiza el nombre', (
    tester,
  ) async {
    final auth = _Auth(_user());
    await _pump(tester, auth);
    await _tap(tester, 'Editar datos');
    expect(find.text('Cédula 1234567890'), findsOneWidget);
    await _tap(tester, 'Nombre completo');
    expect(find.text('Editar nombre completo'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Valentina Pérez');
    await _tap(tester, 'Guardar');
    expect(auth.saved?.fullName, 'Valentina Pérez');
    expect(find.text('Valentina Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el correo nuevo sigue pidiendo contraseña y verificación', (
    tester,
  ) async {
    final auth = _Auth(_user());
    await _pump(tester, auth);
    await _tap(tester, 'Correo y celular');
    expect(find.text('300 123 4567'), findsOneWidget);
    await _tap(tester, 'Correo electrónico');
    await tester.enterText(find.byType(TextField).first, 'nuevo@correo.co');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Clave1234');
    await _tap(tester, 'Guardar');
    expect(auth.saved?.email, 'nuevo@correo.co');
    expect(auth.saved?.currentPassword, 'Clave1234');
    expect(auth.user.email, 'ana@correo.co');
    expect(find.text('Verificar correo nuevo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el correo pendiente se muestra y permite cancelar el cambio', (
    tester,
  ) async {
    final auth = _Auth(_user(pendingEmail: 'nuevo@correo.co'));
    await _pump(tester, auth);
    expect(find.text('Correo pendiente de confirmar'), findsOneWidget);
    await _tap(tester, 'Cancelar');
    expect(find.text('Correo pendiente de confirmar'), findsNothing);
    expect(auth.user.pendingEmail, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final allergies in <String?>[null, 'Penicilina']) {
    testWidgets(
      'alergias: ${allergies ?? 'sin datos'} sin inventar información',
      (tester) async {
        await _pump(tester, _Auth(_user(allergies: allergies)));
        await _tap(tester, 'Alergias registradas');
        expect(
          find.text(allergies ?? 'Sin información registrada'),
          findsOneWidget,
        );
        expect(find.textContaining('próxima solicitud'), findsOneWidget);
        expect(find.text('Guardar'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('nombre y correo largos caben con texto al 200 %', (
    tester,
  ) async {
    await _pump(
      tester,
      _Auth(
        _user(
          name: 'María Alejandra de los Ángeles Rodríguez Pérez',
          email: 'maria.alejandra.rodriguez.perez@correo-ejemplo.co',
        ),
      ),
      scale: 2,
    );
    await _tap(tester, 'Correo y celular');
    expect(
      find.text('maria.alejandra.rodriguez.perez@correo-ejemplo.co'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cerrar sesión conserva la confirmación y permite cancelar', (
    tester,
  ) async {
    final auth = _Auth(_user());
    await _pump(tester, auth);
    await _tap(tester, 'Cerrar sesión');
    await _tap(tester, 'Cancelar');
    expect(auth.logoutCalls, 0);
    await _tap(tester, 'Cerrar sesión');
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, 1);
    expect(find.text('Pantalla de acceso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un error al cargar permite recuperar el perfil', (tester) async {
    final auth = _Auth(_user(), failOnce: true);
    await _pump(tester, auth);
    expect(find.text('No hay conexión.'), findsOneWidget);
    auth.failOnce = false;
    await _tap(tester, 'Reintentar');
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
