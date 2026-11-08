import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/widgets/status_pill.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/decline_sheet.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/dispatcher_permissions.dart';
import 'package:frontend/features/orders/presentation/widgets/queue_wait.dart';
import 'package:frontend/theme/app_theme.dart';

const _civil = 'a1111111-1111-4111-8111-111111111111';

void main() {
  test('declinar saca la urgencia de la cola y solo una vez', () async {
    final repo = LocalOrderRepository();
    final order = await repo.findOne(_civil);
    expect(canDecline(order), isTrue);

    await repo.decline(_civil, reason: 'Sin dron disponible');
    final queue = await repo.queue();
    expect(queue.where((e) => e.order.id == _civil), isEmpty);

    await expectLater(
      repo.decline(_civil),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Tu central ya declinó esta urgencia.',
        ),
      ),
    );
  });

  test('la espera en la cola sube de color a los 3 y a los 5 min', () {
    final created = DateTime.utc(2026, 11, 7, 15);
    final at = created.add(const Duration(minutes: 6));
    expect(queueWaitMinutes(created, at), 6);
    expect(queueWaitLabel(0), 'Recién llegada');
    expect(queueWaitLabel(6), 'Espera 6 min');
    expect(queueWaitTone(1, unattended: false), PillTone.neutral);
    expect(queueWaitTone(3, unattended: false), PillTone.attention);
    expect(queueWaitTone(5, unattended: false), PillTone.negative);
    expect(queueWaitTone(1, unattended: true), PillTone.negative);
  });

  testWidgets('la hoja manda el motivo elegido u "Otro" escrito', (
    tester,
  ) async {
    String? sent;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => sent = await showDeclineSheet(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pasarla a otra central'));
    await tester.pumpAndSettle();
    expect(sent, 'Sin dron disponible');

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tormenta sobre la central');
    await tester.tap(find.text('Pasarla a otra central'));
    await tester.pumpAndSettle();
    expect(sent, 'Tormenta sobre la central');
  });
}
