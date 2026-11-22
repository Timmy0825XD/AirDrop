import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/fleet/data/fleet_dashboard_models.dart';
import 'package:frontend/features/fleet/data/fleet_flight.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/home/presentation/widgets/operator/operator_home_page.dart';
import 'package:frontend/features/home/presentation/widgets/operator/operator_home_values.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:frontend/theme/app_theme.dart';

const operatorUser = PublicUser(
  id: 'op1',
  fullName: 'Andrés Martínez',
  email: 'operador@example.test',
  phone: null,
  role: UserRole.fleetOperator,
  status: UserStatus.active,
  hubIds: ['h1', 'h2'],
);

const operatorHubs = [
  Hub(
    id: 'h1',
    name: 'Central La Paz',
    type: HubType.hospital,
    address: 'La Paz',
    latitude: 10.38,
    longitude: -73.17,
    contactPhone: '3001234567',
    status: HubStatus.active,
  ),
  Hub(
    id: 'h2',
    name: 'Central San Diego',
    type: HubType.hospital,
    address: 'San Diego',
    latitude: 10.33,
    longitude: -73.18,
    contactPhone: '3001234567',
    status: HubStatus.active,
  ),
];

const operatorModels = [
  DroneModel(
    id: 'm1',
    code: 'balanced',
    name: 'Garza',
    maxSpeedKmh: 110,
    maxPayloadKg: 5,
    maxRangeKm: 90,
  ),
  DroneModel(
    id: 'm2',
    code: 'cargo',
    name: 'Cóndor',
    maxSpeedKmh: 60,
    maxPayloadKg: 15,
    maxRangeKm: 30,
  ),
];

Drone operatorDrone(
  String id, {
  String hubId = 'h1',
  DroneStatus status = DroneStatus.available,
  bool due = false,
  bool overdue = false,
}) => Drone(
  id: id,
  identifier: 'CD-$id',
  droneModelId: 'm2',
  hubId: hubId,
  status: status,
  batteryPercent: 96,
  maintenanceDue: due,
  maintenanceOverdue: overdue,
);

FleetFlight operatorFlight(
  String id, {
  String hubId = 'h1',
  bool alert = false,
  bool returning = false,
}) => FleetFlight(
  droneId: 'd$id',
  identifier: 'GZ-$id',
  hubId: hubId,
  orderId: 'p$id',
  orderStatus: OrderStatus.inFlight,
  requiresColdChain: true,
  phase: FlightPhase.cruise,
  batteryPercent: alert ? 18 : 68,
  batteryAlert: alert,
  returning: returning,
  etaSeconds: 360,
  temperatureC: 4,
);

OperatorHomeValues operatorData({
  AsyncValue<List<Hub>>? hubs,
  AsyncValue<List<Drone>>? drones,
  AsyncValue<List<FleetFlight>>? flights,
  AsyncValue<FleetDashboard>? dashboard,
}) => OperatorHomeValues(
  hubs: hubs ?? const AsyncData(operatorHubs),
  drones: drones ?? const AsyncData([]),
  flights: flights ?? const AsyncData([]),
  dashboard: dashboard ?? const AsyncData(FleetDashboard(flights: 42, km: 286)),
  models: operatorModels,
);

Future<void> pumpOperatorPage(
  WidgetTester tester,
  OperatorHomeValues data, {
  double scale = 1,
  Size size = const Size(390, 844),
  ValueChanged<String>? onOpen,
  ValueChanged<Drone>? onDrone,
  VoidCallback? onRetry,
  ValueChanged<int>? onDays,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: OperatorHomePage(
          data: data,
          fullName: 'Maríadelosángeles Rodríguez Martínez',
          days: 30,
          onDays: onDays ?? (_) {},
          onOpen: onOpen ?? (_) {},
          onDrone: onDrone ?? (_) {},
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
