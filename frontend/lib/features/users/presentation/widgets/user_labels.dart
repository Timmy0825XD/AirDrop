import '../../../../core/widgets/status_pill.dart';
import '../../../auth/data/auth_models.dart';

/// Copy de los estados de cuenta en español de Colombia.
///
/// El enum vive en `auth/data` y el texto acá, igual que `HubLabels` con
/// `HubStatus`. El rol no se repite: lo trae `ProfileLabels.role`, que ya
/// lo usan el perfil y el home, para que un mismo rol no se diga de dos
/// formas.
class UserLabels {
  UserLabels._();

  static String status(UserStatus status) => switch (status) {
    UserStatus.unverified => 'Sin verificar',
    UserStatus.active => 'Activa',
    UserStatus.locked => 'Bloqueada',
    UserStatus.suspended => 'Suspendida',
  };

  static PillTone tone(UserStatus status) => switch (status) {
    UserStatus.active => PillTone.positive,
    UserStatus.unverified => PillTone.attention,
    UserStatus.suspended || UserStatus.locked => PillTone.negative,
  };

  /// Lo que se le puede hacer a la cuenta, igual que en
  /// `UsersService.setSuspension`: solo una suspendida se reactiva; una
  /// activa o una bloqueada por intentos fallidos se suspende. Ofrecer
  /// "Activar" a una bloqueada daba 409 ("Esta cuenta no está suspendida.").
  static bool canReactivate(UserStatus status) =>
      status == UserStatus.suspended;

  /// Qué significa cada rol al crear la cuenta.
  static String roleHint(UserRole role) => switch (role) {
    UserRole.dispatcher => 'Trabaja en una sola central',
    UserRole.fleetOperator => 'Una o varias centrales',
    _ => '',
  };
}
