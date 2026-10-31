import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/airdrop_app.dart';
import 'package:frontend/app/providers.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/presentation/widgets/airspace/airspace_reveal.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_providers.dart';

import 'auth_controller_test.dart' show FakeTokenStore;
import 'package:frontend/features/notifications/data/local_notice_repository.dart';
import 'package:frontend/features/notifications/data/notice_providers.dart';

void main() {
  testWidgets('el login termina su salida al mapa antes de ir al inicio', (
    tester,
  ) async {
    final tokenStore = FakeTokenStore();
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokenStore),
        authRepositoryProvider.overrideWithValue(
          LocalAuthRepository(tokenStore: tokenStore),
        ),
        // El inicio del solicitante lista sus pedidos: sin esto pediría a
        // la API real y el test quedaría esperando la red.
        orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
        noticeRepositoryProvider.overrideWithValue(LocalNoticeRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AirDropApp(),
      ),
    );
    // Entrada completa.
    await tester.pump(const Duration(seconds: 5));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'demo@airdrop.local');
    await tester.enterText(fields.at(1), 'Demo1234');
    final button = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
    await tester.ensureVisible(button);
    await tester.tap(button);

    // El repositorio local responde enseguida; el botón espera 700 ms, el
    // check se ve 380 ms y la salida tarda 1100 ms. A mitad de la salida
    // el login sigue.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AirspaceReveal), findsOneWidget);
    expect(
      container.read(authControllerProvider).asData!.value.isAuthenticated,
      isFalse,
      reason: 'la sesión se anuncia al router cuando termina la salida',
    );

    // Al terminar la salida se anuncia la sesión y se entra al inicio.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      container.read(authControllerProvider).asData!.value.isAuthenticated,
      isTrue,
    );
    expect(find.byType(LoginScreen), findsNothing);
    expect(tokenStore.value, startsWith('local-session:'));

    await tester.pumpWidget(const SizedBox());
  });
}
