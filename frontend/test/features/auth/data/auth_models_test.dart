import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';

void main() {
  test('convierte los valores de rol, estado y documento de la API', () {
    expect(UserRole.fromJson('fleet_operator'), UserRole.fleetOperator);
    expect(UserStatus.fromJson('active'), UserStatus.active);
    expect(DocumentType.fromJson('citizenship_id'), DocumentType.citizenshipId);
    expect(DocumentType.fromJson('ppt'), DocumentType.ppt);
  });

  test('parsea un campo único como correo o celular', () {
    final email = AuthContact.parse(' Persona@Correo.CO ');
    final phone = AuthContact.parse('300 123 4567');

    expect(email.toJson(), {'email': 'persona@correo.co'});
    expect(phone.toJson(), {'phone': '3001234567'});
  });

  test('el prefijo +57 se quita antes de mandar el celular', () {
    // Nest solo quita lo que no es dígito y exige 10 dígitos, así que sin
    // esto "+57 300 123 4567" llegaba como 573001234567 y Nest rechazaba
    // el registro, el login y la recuperación con un 400.
    expect(AuthContact.parse('+57 300 123 4567').toJson(), {
      'phone': '3001234567',
    });
    expect(AuthContact.parse('573001234567').toJson(), {'phone': '3001234567'});
  });

  test('RegisterRequest manda documento y celular, sin rol', () {
    final request = RegisterRequest(
      fullName: 'Ana Pérez',
      documentType: DocumentType.citizenshipId,
      documentNumber: '1098765432',
      phone: '3001234567',
      password: 'secreto12',
      consentAccepted: true,
      email: 'ana@correo.co',
    );

    expect(request.toJson(), {
      'email': 'ana@correo.co',
      'fullName': 'Ana Pérez',
      'documentType': 'citizenship_id',
      'documentNumber': '1098765432',
      'phone': '3001234567',
      'password': 'secreto12',
      'consentAccepted': true,
    });
    // Nest usa forbidNonWhitelisted: mandar `role` rompe el registro.
    expect(request.toJson().containsKey('role'), isFalse);
  });

  test('RegisterRequest omite el correo cuando no viene', () {
    final request = RegisterRequest(
      fullName: 'Ana Pérez',
      documentType: DocumentType.ppt,
      documentNumber: 'AB123456',
      phone: '3001234567',
      password: 'secreto12',
      consentAccepted: true,
    );

    expect(request.toJson().containsKey('email'), isFalse);
  });

  test('UpdateProfileRequest manda el documento solo si viene', () {
    expect(const UpdateProfileRequest(fullName: 'Ana').toJson(), {
      'fullName': 'Ana',
    });
    expect(
      const UpdateProfileRequest(
        documentType: DocumentType.ppt,
        documentNumber: 'AB123456',
      ).toJson(),
      {'documentType': 'ppt', 'documentNumber': 'AB123456'},
    );
  });

  test('PublicUser convierte la respuesta de NestJS', () {
    final user = PublicUser.fromJson({
      'id': 'user-1',
      'fullName': 'Ana Pérez',
      'email': 'ana@correo.co',
      'phone': '3001234567',
      'documentType': 'citizenship_id',
      'documentNumber': '1098765432',
      'role': 'requester',
      'status': 'active',
      'hubIds': <String>[],
    });

    expect(user.role, UserRole.requester);
    expect(user.status, UserStatus.active);
    expect(user.documentType, DocumentType.citizenshipId);
    expect(user.documentNumber, '1098765432');
    expect(user.hubIds, isEmpty);
    expect(user.isRequester, isTrue);
  });

  test('PublicUser lee varias centrales del operador de flota', () {
    final user = PublicUser.fromJson({
      'id': 'user-2',
      'fullName': 'Sara Operadora',
      'email': 'sara@correo.co',
      'phone': null,
      'documentType': null,
      'documentNumber': null,
      'role': 'fleet_operator',
      'status': 'active',
      'hubIds': ['hub-1', 'hub-2'],
    });

    expect(user.hubIds, ['hub-1', 'hub-2']);
    expect(user.documentType, isNull);
    expect(user.isRequester, isFalse);
  });

  test('PublicUser tolera que no venga hubIds', () {
    final user = PublicUser.fromJson({
      'id': 'user-3',
      'fullName': 'Admin AirDrop',
      'email': 'admin@correo.co',
      'phone': null,
      'role': 'admin',
      'status': 'active',
    });

    expect(user.hubIds, isEmpty);
  });
}
