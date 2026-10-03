/// Modelos de cuentas institucionales (despachadores y operadores).
///
/// El listado y el alta devuelven el mismo `PublicUser` de auth: Nest usa
/// `UsersService.toPublicUser` para los dos, así que no hay entidad nueva
/// que inventar. Acá vive únicamente el body de `POST /users`
/// (`CreateInstitutionalUserDto`).
library;

import '../../auth/data/auth_models.dart';

/// Roles que el administrador puede crear. Los mismos
/// `INSTITUTIONAL_ROLES` de Nest: el solicitante se autoregistra y el
/// administrador no se crea a sí mismo por esta vía.
const List<UserRole> institutionalRoles = [
  UserRole.dispatcher,
  UserRole.fleetOperator,
];

/// Body de `POST /users`. Sin documento (las cuentas institucionales
/// nacen sin él) y sin OTP: la cuenta nace `active`.
///
/// El celular llega ya normalizado a 10 dígitos con
/// `normalizeColombianPhone`, y el correo en minúsculas, igual que lo
/// transforma el `@Transform` del DTO.
class CreateUserRequest {
  const CreateUserRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.hubIds,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
      'role': role.apiValue,
      'hubIds': hubIds,
    };
  }

  final String fullName;
  final String email;
  final String? phone;
  final String password;
  final UserRole role;

  /// Exactamente una para el despachador, una o más para el operador.
  final List<String> hubIds;
}
