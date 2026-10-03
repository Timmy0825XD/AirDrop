import '../../../../core/api_exception.dart';
import '../../../../core/auth/token_store.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/local/local_auth_rules.dart';
import '../../auth/data/local/local_fixtures.dart';
import 'user_models.dart';
import 'user_repository.dart';

/// Lista simulada en memoria, para trabajar sin NestJS. Reproduce los
/// mensajes y el 409 de `UsersService` para que el comportamiento sea el
/// mismo en los dos orígenes de datos.
///
/// Las centrales que se pueden asignar son las que conoce la maqueta
/// ([localFixtureHubId]); el bloqueo de una central suspendida es regla de
/// Nest y acá solo aplica si el id no existe.
class LocalUserRepository implements UserRepository {
  LocalUserRepository({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _users = [
        // Solo las cuentas institucionales: el API nunca lista
        // solicitantes.
        ...localFixtureUsers
            .where((user) => institutionalRoles.contains(user.role))
            .map(
              (user) => _FixtureAccount(
                id: user.id,
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                role: user.role,
                status: user.status,
                hubIds: List.of(user.hubIds),
              ),
            ),
      ];

  final TokenStore _tokenStore;
  final List<_FixtureAccount> _users;

  @override
  Future<List<PublicUser>> list({UserRole? role, UserStatus? status}) async {
    final rows = _users
        .where((user) => role == null || user.role == role)
        .where((user) => status == null || user.status == status)
        .map((user) => user.toPublicUser())
        .toList();
    rows.sort((a, b) => a.fullName.compareTo(b.fullName));
    return rows;
  }

  @override
  Future<PublicUser> create(CreateUserRequest request) async {
    if (!institutionalRoles.contains(request.role)) {
      throw const ApiException(
        'El rol debe ser despachador u operador de flota.',
        statusCode: 400,
      );
    }
    final hubIds = request.hubIds.toSet().toList();
    if (request.role == UserRole.dispatcher && hubIds.length != 1) {
      throw const ApiException(
        'El despachador debe quedar asignado a una sola central.',
        statusCode: 400,
      );
    }
    if (request.role == UserRole.fleetOperator && hubIds.isEmpty) {
      throw const ApiException(
        'El operador debe quedar asignado al menos a una central.',
        statusCode: 400,
      );
    }
    if (hubIds.any((id) => id != localFixtureHubId)) {
      throw const ApiException('La central no existe.', statusCode: 404);
    }
    final duplicate = _users.any(
      (user) =>
          user.email == request.email ||
          (request.phone != null && user.phone == request.phone),
    );
    if (duplicate) {
      throw const ApiException(
        'Ya existe una cuenta con este correo o celular.',
        statusCode: 409,
      );
    }

    final user = _FixtureAccount(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      fullName: request.fullName.trim(),
      email: request.email,
      phone: request.phone,
      role: request.role,
      status: UserStatus.active,
      hubIds: List.of(hubIds),
    );
    _users.add(user);
    return user.toPublicUser();
  }

  @override
  Future<PublicUser> setSuspension(String id, {required bool suspended}) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index < 0) {
      throw const ApiException('El usuario no existe.', statusCode: 404);
    }
    final current = _users[index];
    if (!institutionalRoles.contains(current.role)) {
      throw const ApiException(
        'Solo puedes suspender despachadores y operadores.',
        statusCode: 403,
      );
    }
    if (id == await _sessionId()) {
      throw const ApiException(
        'No puedes suspender tu propia cuenta.',
        statusCode: 403,
      );
    }
    if (suspended) {
      if (current.status == UserStatus.suspended) {
        throw const ApiException(
          'Esta cuenta ya está suspendida.',
          statusCode: 409,
        );
      }
      if (current.status != UserStatus.active &&
          current.status != UserStatus.locked) {
        throw const ApiException(
          'Solo se pueden suspender cuentas activas o bloqueadas.',
          statusCode: 400,
        );
      }
      current.status = UserStatus.suspended;
    } else {
      if (current.status != UserStatus.suspended) {
        throw const ApiException(
          'Esta cuenta no está suspendida.',
          statusCode: 409,
        );
      }
      current.status = UserStatus.active;
    }
    return current.toPublicUser();
  }

  /// Id de la cuenta de la sesión simulada: el token local es
  /// `local-session:<id>` (ver `LocalAuthRules.tokenPrefix`).
  Future<String?> _sessionId() async {
    final token = await _tokenStore.read();
    if (token == null || !token.startsWith(LocalAuthRules.tokenPrefix)) {
      return null;
    }
    return token.substring(LocalAuthRules.tokenPrefix.length);
  }
}

/// Cuenta institucional de la maqueta: el mismo alcance que devuelve
/// `UsersService.toPublicUser`.
class _FixtureAccount {
  _FixtureAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.hubIds,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  UserStatus status;
  final List<String> hubIds;

  PublicUser toPublicUser() {
    return PublicUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      hubIds: hubIds,
    );
  }
}
