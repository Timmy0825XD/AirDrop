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
}
