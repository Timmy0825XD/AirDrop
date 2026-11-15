import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/prefs/app_prefs.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/onboarding/presentation/welcome_gate.dart';
import 'package:frontend/features/onboarding/presentation/welcome_screen.dart';
import 'package:frontend/features/onboarding/presentation/welcome_steps.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

Future<MemoryPrefsStore> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = MemoryPrefsStore(available: true);
  final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  test('la bienvenida solo sale al solicitante que no la ha visto', () {
    final fresh = MemoryPrefsStore(available: true);
    final seen = MemoryPrefsStore(
      available: true,
      values: {PrefKeys.onboardingSeen: true},
    );
    bool gate(UserRole? role, String location, PrefsStore prefs) =>
        shouldShowWelcome(role: role, location: location, prefs: prefs);

    expect(gate(UserRole.requester, '/home', fresh), isTrue);
    expect(gate(UserRole.requester, '/home', seen), isFalse);
    // Los roles institucionales no la ven.
    expect(gate(UserRole.dispatcher, '/home', fresh), isFalse);
    expect(gate(UserRole.admin, '/home', fresh), isFalse);
    // Solo camino al inicio: un enlace a otra pantalla no se interrumpe.
    expect(gate(UserRole.requester, '/orders/mine', fresh), isFalse);
    // Sin dónde anotar que ya se vio, no se muestra.
    expect(gate(UserRole.requester, '/home', MemoryPrefsStore()), isFalse);
  });

  testWidgets('recorre los tres pasos y al empezar lo deja anotado', (
    tester,
  ) async {
    final prefs = await _pump(tester);

    expect(find.text(welcomeSteps[0].title), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 1 de 3'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text(welcomeSteps[1].title), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text(welcomeSteps[2].title), findsOneWidget);
    expect(find.textContaining('5 minutos'), findsOneWidget);
    expect(prefs.getBool(PrefKeys.onboardingSeen), isNull);

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    expect(prefs.getBool(PrefKeys.onboardingSeen), isTrue);
  });

  testWidgets('omitir en el primer paso también lleva al inicio', (
    tester,
  ) async {
    final prefs = await _pump(tester);

    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(prefs.getBool(PrefKeys.onboardingSeen), isTrue);
  });

  testWidgets('cabe en un teléfono pequeño con el texto al doble', (
    tester,
  ) async {
    await _pump(tester, size: const Size(320, 568), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
