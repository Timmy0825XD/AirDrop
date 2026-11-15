import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';
import 'package:frontend/features/auth/data/privacy_models.dart';
import 'package:frontend/features/auth/presentation/accept_policy_screen.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/auth/presentation/policy_gate.dart';
import 'package:frontend/features/auth/presentation/privacy_screen.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore() : super();

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

/// La cuenta local que se registró antes de la política (RF-50).
const _oldEmail = 'antiguo@airdrop.local';
const _password = 'Demo1234';

Future<(_FakeTokenStore, LocalAuthRepository)> _signedIn(String email) async {
  final store = _FakeTokenStore();
  final repository = LocalAuthRepository(tokenStore: store);
  final session = await repository.login(
    LoginRequest(contact: AuthContact.email(email), password: _password),
  );
  store.value = session.accessToken;
  return (store, repository);
}

/// Una pantalla de datos personales en un router mínimo, ya con sesión.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  _FakeTokenStore store,
  LocalAuthRepository repository, {
  required String at,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.future);
  Widget page(String text) => Scaffold(body: Text(text));
  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(
        path: '/privacy/accept',
        builder: (_, _) => const AcceptPolicyScreen(),
      ),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: '/login', builder: (_, _) => page('Login')),
      GoRoute(path: '/register', builder: (_, _) => page('Registro')),
      GoRoute(path: '/home', builder: (_, _) => page('Inicio')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('la cuenta trae la versión aceptada y si debe aceptar', () {
    final json = {
      'id': 'u1',
      'fullName': 'Ana',
      'email': 'ana@correo.co',
      'phone': '3001234567',
      'role': 'requester',
      'status': 'revoked',
      'hubIds': <String>[],
      'policyVersion': null,
      'mustAcceptPolicy': true,
    };
    final user = PublicUser.fromJson(json);

    expect(user.status, UserStatus.revoked);
    expect(user.policyVersion, isNull);
    expect(user.mustAcceptPolicy, isTrue);
    // Una cuenta de antes de la rama no trae la clave: no debe aceptar.
    expect(
      PublicUser.fromJson(
        {...json}..remove('mustAcceptPolicy'),
      ).mustAcceptPolicy,
      isFalse,
    );
    expect(UserStatus.fromJson('deleted'), UserStatus.deleted);
  });

  test('lee "Mis datos" y la política como los manda Nest', () {
    final overview = PrivacyOverview.fromJson({
      'user': {
        'id': 'u1',
        'fullName': 'Ana',
        'email': 'ana@correo.co',
        'phone': null,
        'role': 'requester',
        'status': 'active',
        'hubIds': <String>[],
      },
      'consent': {
        'acceptedAt': '2026-11-14T15:00:00.000Z',
        'acceptedVersion': '1.0',
        'currentVersion': '1.0',
        'mustAccept': false,
      },
      'notices': {
        'revoke': ['Tu cuenta queda inactiva.'],
        'suppress': ['Se borra tu correo.', 'No se puede deshacer.'],
      },
    });
    expect(overview.consent.acceptedVersion, '1.0');
    expect(overview.consent.acceptedAt, isNotNull);
    expect(overview.revokeNotice, ['Tu cuenta queda inactiva.']);
    expect(overview.suppressNotice, hasLength(2));

    final policy = PrivacyPolicy.fromJson({
      'version': '1.0',
      'substantialVersion': '1.0',
      'effectiveFrom': '2026-11-14',
      'controller': {'name': 'AirDrop', 'contactEmail': 'datos@airdrop.co'},
      'sections': [
        {
          'title': 'Tus derechos',
          'body': ['Conocer tus datos.', 'Suprimirlos.'],
        },
      ],
    });
    expect(policy.controllerName, 'AirDrop');
    expect(policy.sections.single.body, hasLength(2));
  });

  test('sin aceptar la política solo se ve la pantalla para aceptarla', () {
    String? to(bool mustAccept, String location) =>
        policyRedirect(mustAccept: mustAccept, location: location);

    expect(to(true, '/home'), '/privacy/accept');
    expect(to(true, '/orders/emergency'), '/privacy/accept');
    expect(to(true, '/privacy/accept'), isNull);
    // Ya aceptada, esa pantalla no retiene a nadie.
    expect(to(false, '/privacy/accept'), '/home');
    expect(to(false, '/home'), isNull);
  });

  test('revocar pide la contraseña y la cuenta ya no entra', () async {
    final (_, repository) = await _signedIn('demo@airdrop.local');

    await expectLater(
      repository.revokeConsent('otra'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'La contraseña no es correcta.',
        ),
      ),
    );

    await repository.revokeConsent(_password);
    await expectLater(
      repository.login(
        LoginRequest(
          contact: AuthContact.email('demo@airdrop.local'),
          password: _password,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          PrivacyScreen.revokedMessage,
        ),
      ),
    );
  });

  testWidgets('quien no ha aceptado la política la acepta antes de entrar', (
    tester,
  ) async {
    final (store, repository) = await _signedIn(_oldEmail);
    final container = await _pumpApp(
      tester,
      store,
      repository,
      at: '/privacy/accept',
    );

    expect(find.text('Actualizamos la política de datos'), findsOneWidget);
    expect(find.text('Tus derechos (Ley 1581, art. 8)'), findsOneWidget);

    await tester.tap(find.text('Acepto la política'));
    await tester.pumpAndSettle();

    final user = container.read(authControllerProvider).value!.user!;
    expect(user.mustAcceptPolicy, isFalse);
    expect(user.policyVersion, '1.0');
  });

  testWidgets('"Mis datos" revoca con la contraseña y cierra la sesión', (
    tester,
  ) async {
    final (store, repository) = await _signedIn('demo@airdrop.local');
    final container = await _pumpApp(tester, store, repository, at: '/privacy');

    expect(find.text('Mis datos'), findsOneWidget);
    expect(find.textContaining('Aceptaste la versión 1.0'), findsOneWidget);

    await tester.tap(find.text('Revocar consentimiento'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu cuenta queda inactiva y no podrás iniciar sesión.'),
      findsOneWidget,
    );

    // Sin contraseña no sale.
    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), _password);
    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();

    expect(store.value, isNull);
    expect(
      container.read(authControllerProvider).value!.isAuthenticated,
      isFalse,
    );
  });
}
