import '../../auth/data/auth_models.dart';
import 'user_models.dart';

/// Contrato de la feature de cuentas institucionales. Las tres operaciones
/// que `UsersController` expone al administrador.
///
/// Ningún método convierte un error en `null`: la UI siempre muestra el
/// `message` que define Nest ("No puedes suspender tu propia cuenta.",
/// "Solo puedes asignar centrales activas.", el 409 de una suspensión
/// repetida, etc.).
abstract class UserRepository {
  /// `GET /users?role=&status=` — lista institucional. Nunca trae
  /// solicitantes: el API solo lista despachadores y operadores.
  Future<List<PublicUser>> list({UserRole? role, UserStatus? status});

  /// `POST /users` — alta del administrador. Nace `active`, sin OTP.
  Future<PublicUser> create(CreateUserRequest request);

  /// `PATCH /users/:id/suspension` — suspende o reactiva. Si la cuenta ya
  /// está en ese estado, Nest responde 409 y el error se propaga.
  Future<PublicUser> setSuspension(String id, {required bool suspended});
}
