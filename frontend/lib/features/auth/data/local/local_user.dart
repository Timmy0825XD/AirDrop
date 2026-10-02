import '../auth_models.dart';

/// Usuario de la sesión simulada. Es el mismo `PublicUser` que devuelve
/// el repositorio remoto, más la contraseña y el `hubId` que solo
/// existen en el cliente.
class LocalUser {
  LocalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.password,
    this.hubId,
  });

  final String id;
  String fullName;
  String? email;
  String? phone;
  final UserRole role;
  UserStatus status;
  String password;
  final String? hubId;

  LocalUser copy() {
    return LocalUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      password: password,
      hubId: hubId,
    );
  }

  PublicUser toPublicUser() {
    return PublicUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      hubId: hubId,
    );
  }
}