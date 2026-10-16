import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/status_pill.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_status_chip.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_tile.dart';
import 'package:frontend/features/fleet/presentation/widgets/maintenance_sheet.dart';

const _drone = Drone(
  id: 'd1',
  identifier: 'DRON-01',
  droneModelId: 'm1',
  hubId: 'hub-1',
  status: DroneStatus.maintenance,
);

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('sin acciones (central suspendida) no ofrece "Gestionar"', (
    tester,
  ) async {
    await _pump(
      tester,
      const DroneTile(
        drone: _drone,
        modelName: 'Wingcopter 198',
        onActions: null,
      ),
    );

    expect(find.text('Gestionar'), findsNothing);
    expect(find.text('Sin cambios'), findsOneWidget);
  });

  test('cada estado del dron tiene su color de pastilla', () {
    expect(DroneStatusChip.toneOf(DroneStatus.available), PillTone.positive);
    expect(DroneStatusChip.toneOf(DroneStatus.inMission), PillTone.attention);
    expect(DroneStatusChip.toneOf(DroneStatus.maintenance), PillTone.neutral);
    expect(DroneStatusChip.toneOf(DroneStatus.outOfService), PillTone.negative);
  });

  testWidgets('registrar mantenimiento sin fecha pide elegirla', (
    tester,
  ) async {
    await _pump(tester, const MaintenanceSheet(mandatory: true));

    await tester.enterText(find.byType(TextField), 'Cambio de hélices');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Elige la fecha estimada.'), findsOneWidget);
    expect(find.text('AAAA-MM-DD'), findsNothing);
  });
}
