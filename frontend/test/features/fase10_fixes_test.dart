import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/widgets/order_tray.dart';
import 'package:frontend/theme/app_theme.dart';

/// Cuenta simulada en sesión, para cambiarla dentro del test.
class _FakeSession extends Notifier<String?> {
  @override
  String? build() => 'cuenta-a';

  void set(String? id) => state = id;
}

final _fakeSessionProvider = NotifierProvider<_FakeSession, String?>(
  _FakeSession.new,
);

var _loads = 0;

/// Una lista que tarda en llegar, para ver qué pinta la bandeja mientras
/// recarga.
final _slowRowsProvider = FutureProvider<List<String>>((ref) async {
  _loads++;
  if (_loads > 1) await Future<void>.delayed(const Duration(seconds: 1));
  return ['Acetaminofén F10'];
});

void main() {
  test('al cambiar de cuenta se descarta lo cargado por la anterior', () {
    final container = ProviderContainer(
      overrides: [
        sessionUserIdProvider.overrideWith(
          (ref) => ref.watch(_fakeSessionProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    final first = container.read(orderRepositoryProvider);
    container.read(_fakeSessionProvider.notifier).set('cuenta-b');

    expect(container.read(orderRepositoryProvider), isNot(same(first)));
  });

  testWidgets('la bandeja no se queda en blanco mientras recarga', (
    tester,
  ) async {
    _loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => OrderTray<String>(
              title: 'Cola',
              idleSubtitle: 'Cargando',
              countLabel: (n) => '$n por atender',
              rows: ref.watch(_slowRowsProvider),
              onRefresh: () => ref.invalidate(_slowRowsProvider),
              emptyIcon: Icons.inbox,
              emptyText: 'Vacía',
              keyOf: (row) => row,
              itemBuilder: (context, row) => Text(row),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Acetaminofén F10'), findsOneWidget);

    // El refresco automático de las bandejas (cada 10 s).
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Acetaminofén F10'), findsOneWidget);
    expect(find.text('1 por atender'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  test('el botón flotante y los "container" van en la paleta de marca', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        theme.colorScheme.primary,
      );
      // El morado por defecto de Material tiene el azul por encima del
      // verde; el verde azulado de la marca, al revés.
      final container = theme.colorScheme.secondaryContainer;
      expect(container.g, greaterThanOrEqualTo(container.r));
    }
  });
}
