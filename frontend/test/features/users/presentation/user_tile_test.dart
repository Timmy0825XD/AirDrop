import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/users/presentation/widgets/user_labels.dart';
import 'package:frontend/features/users/presentation/widgets/user_tile.dart';

PublicUser _user(UserStatus status) => PublicUser(
  id: 'u1',
  fullName: 'Jorge Oñate',
  email: 'jonate@clinicadelvalle.co',
  phone: null,
  role: UserRole.dispatcher,
  status: status,
  hubIds: const ['h1'],
);

Future<void> _pump(WidgetTester tester, PublicUser user) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UserTile(
          user: user,
          hubNames: const ['Clínica del Valle'],
          onToggle: () {},
        ),
      ),
    ),
  );
}

void main() {
  test('solo una cuenta suspendida se reactiva', () {
    expect(UserLabels.canReactivate(UserStatus.suspended), isTrue);
    expect(UserLabels.canReactivate(UserStatus.active), isFalse);
    // Ofrecer "Activar" a una bloqueada daba 409 en Nest.
    expect(UserLabels.canReactivate(UserStatus.locked), isFalse);
  });

  testWidgets('una cuenta bloqueada ofrece suspender, no activar', (
    tester,
  ) async {
    await _pump(tester, _user(UserStatus.locked));

    expect(find.text('Bloqueada'), findsOneWidget);
    expect(find.text('Suspender'), findsOneWidget);
    expect(find.text('Reactivar'), findsNothing);
  });

  testWidgets('muestra el rol y el nombre de sus centrales', (tester) async {
    await _pump(tester, _user(UserStatus.suspended));

    expect(find.text('Despachador'), findsOneWidget);
    expect(find.text('Clínica del Valle'), findsOneWidget);
    expect(find.text('Reactivar'), findsOneWidget);
  });
}
