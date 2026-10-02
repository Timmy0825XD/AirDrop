import '../auth_models.dart';

/// Usuario de la sesión simulada. Es el mismo `PublicUser` que devuelve
/// el repositorio remoto, más la contraseña que solo existe en el cliente.
class LocalUser {
  LocalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.password,
    this.documentType,
    this.documentNumber,
    this.hubIds = const [],
  });

  final String id;
  String fullName;
  String? email;
  String? phone;

  /// Solo el solicitante tiene documento; las cuentas institucionales
  /// nacen sin él, igual que en Nest.
  DocumentType? documentType;
  String? documentNumber;

  final UserRole role;
  UserStatus status;
  String password;

  /// Centrales asignadas: una para el despachador, una o más para el
  /// operador de flota, ninguna para el solicitante y el administrador.
  List<String> hubIds;

  LocalUser copy() {
    return LocalUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      role: role,
      status: status,
      password: password,
      hubIds: List.of(hubIds),
    );
  }

  PublicUser toPublicUser() {
    return PublicUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      role: role,
      status: status,
      hubIds: hubIds,
    );
  }
}
