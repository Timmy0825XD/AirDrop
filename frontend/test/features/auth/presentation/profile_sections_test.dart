import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/widgets/profile/profile_field_type.dart';
import 'package:frontend/features/auth/presentation/widgets/profile/profile_sections.dart';

const _operator = PublicUser(
  id: 'u-2',
  fullName: 'Olga Operadora',
  email: 'olga@airdrop.co',
  phone: '3009876543',
  role: UserRole.fleetOperator,
  status: UserStatus.active,
  hubIds: ['h1', 'h2'],
);

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('las centrales se ven por nombre', (tester) async {
    await _pump(
      tester,
      const ProfileHubsCard(
        names: ['Hospital Rosario Pumarejo', 'Clínica del Cesar'],
      ),
    );

    expect(find.text('TUS CENTRALES'), findsOneWidget);
    expect(find.text('Hospital Rosario Pumarejo'), findsOneWidget);
    expect(find.text('Clínica del Cesar'), findsOneWidget);
    expect(find.text('Central operativa vinculada'), findsNothing);
  });

  testWidgets('tocar un dato pide editarlo', (tester) async {
    ProfileFieldType? edited;
    await _pump(
      tester,
      ProfileDataCard(user: _operator, onEdit: (type) => edited = type),
    );

    await tester.tap(find.text('3009876543'));
    expect(edited, ProfileFieldType.phone);
  });
}
