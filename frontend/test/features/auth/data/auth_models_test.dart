import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';

void main() {
  test('convierte los valores de rol y estado de la API', () {
    expect(UserRole.fromJson('fleet_operator'), UserRole.fleetOperator);
    expect(UserStatus.fromJson('active'), UserStatus.active);
  });

  test('parsea un campo único como correo o celular', () {
    final email = AuthContact.parse(' Persona@Correo.CO ');
    final phone = AuthContact.parse('+57 300 123 4567');

    expect(email.toJson(), {'email': 'persona@correo.co'});
    expect(phone.toJson(), {'phone': '573001234567'});
  });

  test('RegisterRequest permite correo y celular al mismo tiempo', () {
    final request = RegisterRequest(
      fullName: 'Ana Pérez',
      email: 'ana@correo.co',
      phone: '3001234567',
      password: 'secreto12',
      role: UserRole.requester,
      consentAccepted: true,
    );

    expect(request.toJson(), {
      'email': 'ana@correo.co',
      'phone': '3001234567',
      'fullName': 'Ana Pérez',
      'password': 'secreto12',
      'role': 'requester',
      'consentAccepted': true,
    });
  });

  test('PublicUser convierte la respuesta de NestJS', () {
    final user = PublicUser.fromJson({
      'id': 'user-1',
      'fullName': 'Ana Pérez',
      'email': 'ana@correo.co',
      'phone': null,
      'role': 'requester',
      'status': 'active',
      'hubId': null,
    });

    expect(user.role, UserRole.requester);
    expect(user.status, UserStatus.active);
    expect(user.phone, isNull);
  });
}
