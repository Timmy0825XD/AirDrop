import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';

/// Un estado nuevo de Nest no deja la pantalla en blanco: cae en `unknown`.
/// Los tipos (rol, misión, destino…) siguen fallando, porque sin conocerlos
/// la app no sabe qué regla aplicar.
void main() {
  test('los estados que la app no conoce caen en unknown', () {
    expect(OrderStatus.fromJson('nuevo'), OrderStatus.unknown);
    expect(OrderStatus.unknown.label, 'Estado desconocido');
    expect(PlanStatus.fromJson('nuevo'), PlanStatus.unknown);
    expect(HubStatus.fromJson('nuevo'), HubStatus.unknown);
    expect(HubStatus.unknown.isActive, isFalse);
    expect(UserStatus.fromJson('nuevo'), UserStatus.unknown);
  });

  test('los estados conocidos se siguen leyendo igual', () {
    expect(OrderStatus.fromJson('in_flight'), OrderStatus.inFlight);
    expect(HubStatus.fromJson('suspended'), HubStatus.suspended);
    expect(UserStatus.fromJson('locked'), UserStatus.locked);
  });

  test('un tipo desconocido sigue fallando', () {
    expect(() => UserRole.fromJson('nuevo'), throwsFormatException);
    expect(() => MissionType.fromJson('nuevo'), throwsFormatException);
  });
}
